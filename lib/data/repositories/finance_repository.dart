import 'dart:async';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';
import '../models.dart';

class MonthCashFlow {
  final DateTime monthStartLocal;
  final String label;
  final int total;

  const MonthCashFlow({
    required this.monthStartLocal,
    required this.label,
    required this.total,
  });
}

class PunctualityStats {
  final int onTimeCount;
  final int totalCount;
  final double? rate;

  const PunctualityStats({
    required this.onTimeCount,
    required this.totalCount,
    required this.rate,
  });
}

class FinanceSummary {
  final int monthTotal;
  final int totalClientRemaining;
  final int totalApprenticeRemaining;
  final List<MonthCashFlow> last6Months;
  final PunctualityStats punctuality;

  const FinanceSummary({
    required this.monthTotal,
    required this.totalClientRemaining,
    required this.totalApprenticeRemaining,
    required this.last6Months,
    required this.punctuality,
  });
}

abstract class FinanceRepository {
  Stream<FinanceSummary> watchSummary();
  Future<FinanceSummary> getSummary();
  Future<int> getTotalClientRemaining();
  Future<int> getTotalApprenticeRemaining();
  Future<int> getMonthCashFlow(DateTime monthStartLocal, DateTime nextMonthStartLocal);
  Future<List<MonthCashFlow>> getLast6MonthsCashFlow();
  Future<PunctualityStats> getPunctualityStats({Duration window = const Duration(days: 90)});
}

class DriftFinanceRepository implements FinanceRepository {
  DriftFinanceRepository({
    required this.db,
    this.clock = const SystemClock(),
    DateTime Function(DateTime)? toLocal,
  }) : toLocal = toLocal ?? ((d) => d.toLocal());

  final db_layer.AppDatabase db;
  final Clock clock;
  final DateTime Function(DateTime) toLocal;

  @override
  Stream<FinanceSummary> watchSummary() {
    late StreamController<FinanceSummary> controller;
    StreamSubscription? s1, s2, s3, s4;

    Future<void> emitSummary() async {
      if (!controller.isClosed) {
        try {
          final summary = await getSummary();
          if (!controller.isClosed) {
            controller.add(summary);
          }
        } catch (_) {
          // Base fermée ou en cours de fermeture
        }
      }
    }

    controller = StreamController<FinanceSummary>(
      onListen: () {
        emitSummary();
        s1 = (db.select(db.orders)..limit(1)).watch().listen((_) => emitSummary());
        s2 = (db.select(db.clientPayments)..limit(1)).watch().listen((_) => emitSummary());
        s3 = (db.select(db.apprentices)..limit(1)).watch().listen((_) => emitSummary());
        s4 = (db.select(db.apprenticePayments)..limit(1)).watch().listen((_) => emitSummary());
      },
      onCancel: () async {
        await s1?.cancel();
        await s2?.cancel();
        await s3?.cancel();
        await s4?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<FinanceSummary> getSummary() async {
    final nowLocal = toLocal(clock.now());
    final currentMonthStartLocal = DateTime(nowLocal.year, nowLocal.month, 1);
    final nextMonthStartLocal = DateTime(nowLocal.year, nowLocal.month + 1, 1);

    final clientRemaining = await getTotalClientRemaining();
    final appRemaining = await getTotalApprenticeRemaining();
    final monthTotal = await getMonthCashFlow(currentMonthStartLocal, nextMonthStartLocal);
    final last6Months = await getLast6MonthsCashFlow();
    final punctuality = await getPunctualityStats();

    return FinanceSummary(
      monthTotal: monthTotal,
      totalClientRemaining: clientRemaining,
      totalApprenticeRemaining: appRemaining,
      last6Months: last6Months,
      punctuality: punctuality,
    );
  }

  @override
  Future<int> getTotalClientRemaining() async {
    final query = db.select(db.orders).join([
      leftOuterJoin(
        db.clientPayments,
        db.clientPayments.orderId.equalsExp(db.orders.id) &
            db.clientPayments.voidedAt.isNull() &
            db.clientPayments.deletedAt.isNull(),
      ),
    ])
      ..where(db.orders.deletedAt.isNull())
      ..groupBy([db.orders.id])
      ..addColumns([
        db.orders.id,
        db.orders.price,
        db.clientPayments.amount.sum(),
      ]);

    final rows = await query.get();
    var sumRemaining = 0;
    for (final row in rows) {
      final price = row.read(db.orders.price) ?? 0;
      final paid = row.read(db.clientPayments.amount.sum()) ?? 0;
      final remaining = price - paid;
      if (remaining > 0) sumRemaining += remaining;
    }
    return sumRemaining;
  }

  @override
  Future<int> getTotalApprenticeRemaining() async {
    final query = db.select(db.apprentices).join([
      leftOuterJoin(
        db.apprenticePayments,
        db.apprenticePayments.apprenticeId.equalsExp(db.apprentices.id) &
            db.apprenticePayments.voidedAt.isNull() &
            db.apprenticePayments.deletedAt.isNull(),
      ),
    ])
      ..where(db.apprentices.deletedAt.isNull())
      ..groupBy([db.apprentices.id])
      ..addColumns([
        db.apprentices.id,
        db.apprentices.totalFee,
        db.apprenticePayments.amount.sum(),
      ]);

    final rows = await query.get();
    var sumRemaining = 0;
    for (final row in rows) {
      final totalFee = row.read(db.apprentices.totalFee) ?? 0;
      final paid = row.read(db.apprenticePayments.amount.sum()) ?? 0;
      final remaining = totalFee - paid;
      if (remaining > 0) sumRemaining += remaining;
    }
    return sumRemaining;
  }

  @override
  Future<int> getMonthCashFlow(DateTime monthStartLocal, DateTime nextMonthStartLocal) async {
    final startUtc = monthStartLocal.toUtc();
    final endUtc = nextMonthStartLocal.toUtc();
    final startMs = startUtc.millisecondsSinceEpoch;
    final endMs = endUtc.millisecondsSinceEpoch;

    final clientQuery = db.selectOnly(db.clientPayments)
      ..addColumns([db.clientPayments.amount.sum()])
      ..where(
        db.clientPayments.voidedAt.isNull() &
            db.clientPayments.deletedAt.isNull() &
            db.clientPayments.paidAt.isBiggerOrEqualValue(startMs) &
            db.clientPayments.paidAt.isSmallerThanValue(endMs),
      );
    final clientSum = await clientQuery.map((r) => r.read(db.clientPayments.amount.sum())).getSingle() ?? 0;

    final appQuery = db.selectOnly(db.apprenticePayments)
      ..addColumns([db.apprenticePayments.amount.sum()])
      ..where(
        db.apprenticePayments.voidedAt.isNull() &
            db.apprenticePayments.deletedAt.isNull() &
            db.apprenticePayments.paidAt.isBiggerOrEqualValue(startMs) &
            db.apprenticePayments.paidAt.isSmallerThanValue(endMs),
      );
    final appSum = await appQuery.map((r) => r.read(db.apprenticePayments.amount.sum())).getSingle() ?? 0;

    return clientSum + appSum;
  }

  @override
  Future<List<MonthCashFlow>> getLast6MonthsCashFlow() async {
    final nowLocal = toLocal(clock.now());
    final list = <MonthCashFlow>[];

    for (var i = 5; i >= 0; i--) {
      final monthStartLocal = DateTime(nowLocal.year, nowLocal.month - i, 1);
      final nextMonthLocal = DateTime(nowLocal.year, nowLocal.month - i + 1, 1);
      final total = await getMonthCashFlow(monthStartLocal, nextMonthLocal);
      final label = _formatMonth(monthStartLocal);

      list.add(MonthCashFlow(
        monthStartLocal: monthStartLocal,
        label: label,
        total: total,
      ));
    }
    return list;
  }

  String _formatMonth(DateTime d) {
    try {
      return DateFormat('MMM', 'fr_FR').format(d);
    } catch (_) {
      const frMonths = [
        'Janv.',
        'Févr.',
        'Mars',
        'Avr.',
        'Mai',
        'Juin',
        'Juil.',
        'Août',
        'Sept.',
        'Oct.',
        'Nov.',
        'Déc.'
      ];
      return frMonths[d.month - 1];
    }
  }

  @override
  Future<PunctualityStats> getPunctualityStats({Duration window = const Duration(days: 90)}) async {
    final now = clock.now();
    final windowStart = now.subtract(window);
    final windowStartMs = windowStart.millisecondsSinceEpoch;

    final query = db.select(db.orders)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.status.equals(OrderStatus.livree.name) &
          t.deliveredAt.isNotNull() &
          t.deliveredAt.isBiggerOrEqualValue(windowStartMs));

    final deliveredOrders = await query.get();

    if (deliveredOrders.isEmpty) {
      return const PunctualityStats(onTimeCount: 0, totalCount: 0, rate: null);
    }

    var onTimeCount = 0;
    for (final o in deliveredOrders) {
      final deliveredLocal = toLocal(o.deliveredAt!);
      final delCalendarDay = DateTime(deliveredLocal.year, deliveredLocal.month, deliveredLocal.day);
      final promCalendarDay = DateTime(o.deliveryDate.year, o.deliveryDate.month, o.deliveryDate.day);

      // À temps si jour calendaire local de delivered_at <= jour calendaire promis
      if (!delCalendarDay.isAfter(promCalendarDay)) {
        onTimeCount++;
      }
    }

    final rate = onTimeCount / deliveredOrders.length;
    return PunctualityStats(
      onTimeCount: onTimeCount,
      totalCount: deliveredOrders.length,
      rate: rate,
    );
  }
}
