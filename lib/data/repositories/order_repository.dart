import 'package:drift/drift.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';
import '../db/id_generator.dart';
import '../models.dart';
import '../utils/photo_metadata.dart';

/// Normalise une date jour-seul en UTC (00:00:00 UTC) pour préserver le même jour
/// quel que soit le fuseau horaire de lecture.
DateTime normalizeDate(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Normalise une date avec heure optionnelle en UTC.
DateTime normalizeDateTime(DateTime d) => DateTime.utc(d.year, d.month, d.day, d.hour, d.minute);

abstract class OrderRepository {
  Stream<List<Order>> watchAll();
  Stream<Order?> watchById(String id);
  Future<List<Order>> getAll();
  Future<Order?> getById(String id, {bool includeDeleted = false});
  Future<List<Order>> getByClient(String clientId);
  Future<bool> hasNonDeletedOrdersForClient(String clientId);
  Future<void> save(Order order);
  Future<void> createWithDeposit({
    required Order order,
    required int depositAmount,
    String depositNote = 'Acompte',
  });
  Future<void> delete(String id);
}

class DriftOrderRepository implements OrderRepository {
  DriftOrderRepository({
    required this.db,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7IdGenerator(),
  });

  final db_layer.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  List<Order> _mapJoinedResults(List<TypedResult> rows) {
    final Map<String, ({db_layer.Order order, List<String> photos})> map = {};

    for (final row in rows) {
      final orderRow = row.readTable(db.orders);
      final photoRow = row.readTableOrNull(db.orderPhotos);
      final entry = map.putIfAbsent(orderRow.id, () => (order: orderRow, photos: []));
      if (photoRow != null && !entry.photos.contains(photoRow.photoPath)) {
        entry.photos.add(photoRow.photoPath);
      }
    }

    return map.values.map((e) {
      final photos = List<String>.from(e.photos);
      if (photos.isEmpty && e.order.photoPath != null && e.order.photoPath!.isNotEmpty) {
        photos.add(e.order.photoPath!);
      }
      return Order(
        id: e.order.id,
        clientId: e.order.clientId,
        modeleId: e.order.modeleId,
        title: e.order.title,
        fabric: e.order.fabric,
        price: e.order.price,
        deliveryDate: e.order.deliveryDate,
        fittingDate: e.order.fittingDate,
        status: OrderStatus.values.firstWhere(
          (s) => s.name == e.order.status,
          orElse: () => OrderStatus.attente,
        ),
        photos: photos,
        createdAt: e.order.createdAt,
        deliveredAt: e.order.deliveredAt,
      );
    }).toList();
  }


  @override
  Stream<List<Order>> watchAll() {
    final query = db.select(db.orders).join([
      leftOuterJoin(
        db.orderPhotos,
        db.orderPhotos.orderId.equalsExp(db.orders.id) & db.orderPhotos.deletedAt.isNull(),
      ),
    ])
      ..where(db.orders.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.asc(db.orders.deliveryDate),
        OrderingTerm.asc(db.orderPhotos.position),
      ]);

    return query.watch().map(_mapJoinedResults);
  }

  @override
  Stream<Order?> watchById(String id) {
    final query = db.select(db.orders).join([
      leftOuterJoin(
        db.orderPhotos,
        db.orderPhotos.orderId.equalsExp(db.orders.id) & db.orderPhotos.deletedAt.isNull(),
      ),
    ])
      ..where(db.orders.id.equals(id) & db.orders.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(db.orderPhotos.position)]);

    return query.watch().map((rows) {
      final list = _mapJoinedResults(rows);
      return list.isEmpty ? null : list.first;
    });
  }

  @override
  Future<List<Order>> getAll() async {
    final query = db.select(db.orders).join([
      leftOuterJoin(
        db.orderPhotos,
        db.orderPhotos.orderId.equalsExp(db.orders.id) & db.orderPhotos.deletedAt.isNull(),
      ),
    ])
      ..where(db.orders.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.asc(db.orders.deliveryDate),
        OrderingTerm.asc(db.orderPhotos.position),
      ]);

    final rows = await query.get();
    return _mapJoinedResults(rows);
  }

  @override
  Future<Order?> getById(String id, {bool includeDeleted = false}) async {
    final query = db.select(db.orders).join([
      leftOuterJoin(
        db.orderPhotos,
        db.orderPhotos.orderId.equalsExp(db.orders.id) & (includeDeleted ? const Constant(true) : db.orderPhotos.deletedAt.isNull()),
      ),
    ])
      ..where(db.orders.id.equals(id) & (includeDeleted ? const Constant(true) : db.orders.deletedAt.isNull()))
      ..orderBy([OrderingTerm.asc(db.orderPhotos.position)]);

    final rows = await query.get();
    final list = _mapJoinedResults(rows);
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<List<Order>> getByClient(String clientId) async {
    final query = db.select(db.orders).join([
      leftOuterJoin(
        db.orderPhotos,
        db.orderPhotos.orderId.equalsExp(db.orders.id) & db.orderPhotos.deletedAt.isNull(),
      ),
    ])
      ..where(db.orders.clientId.equals(clientId) & db.orders.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.desc(db.orders.deliveryDate),
        OrderingTerm.asc(db.orderPhotos.position),
      ]);

    final rows = await query.get();
    return _mapJoinedResults(rows);
  }

  @override
  Future<bool> hasNonDeletedOrdersForClient(String clientId) async {
    final count = await (db.select(db.orders)
          ..where((t) => t.clientId.equals(clientId) & t.deletedAt.isNull()))
        .get()
        .then((l) => l.length);
    return count > 0;
  }

  @override
  Future<void> save(Order order) async {
    final now = clock.now();
    final existing = await (db.select(db.orders)..where((t) => t.id.equals(order.id))).getSingleOrNull();

    // Règle Décision 6 : Refuse de fixer un prix inférieur au total des versements non annulés
    final activePayments = await (db.select(db.clientPayments)
          ..where((t) => t.orderId.equals(order.id) & t.voidedAt.isNull() & t.deletedAt.isNull()))
        .get();
    final paidTotal = activePayments.fold<int>(0, (sum, p) => sum + p.amount);
    if (order.price < paidTotal) {
      throw ArgumentError('Le prix de la commande ($order.price FCFA) ne peut pas être inférieur au montant déjà versé ($paidTotal FCFA).');
    }

    final createdAt = existing?.createdAt ?? order.createdAt;
    final updatedAt = now;
    final normDelivery = normalizeDate(order.deliveryDate);
    final normFitting = order.fittingDate != null ? normalizeDateTime(order.fittingDate!) : null;

    final DateTime? deliveredAt;
    if (order.status == OrderStatus.livree) {
      deliveredAt = (existing != null && existing.status == OrderStatus.livree.name && existing.deliveredAt != null)
          ? existing.deliveredAt
          : (order.deliveredAt ?? now);
    } else {
      deliveredAt = null;
    }

    await db.transaction(() async {
      // 1. Sauvegarde de la commande principale
      await db.into(db.orders).insertOnConflictUpdate(
            db_layer.OrdersCompanion(
              id: Value(order.id),
              clientId: Value(order.clientId),
              modeleId: Value(order.modeleId),
              title: Value(order.title),
              fabric: Value(order.fabric),
              price: Value(order.price),
              deliveryDate: Value(normDelivery),
              fittingDate: Value(normFitting),
              status: Value(order.status.name),
              deliveredAt: Value(deliveredAt),
              photoPath: Value(order.photos.firstOrNull),
              photoHash: Value(resolvePhotoMetadata(order.photos.firstOrNull, existingUploadState: existing?.photoUploadState).hash),
              photoUploadState: Value(resolvePhotoMetadata(order.photos.firstOrNull, existingUploadState: existing?.photoUploadState).uploadState),
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
              deletedAt: const Value(null),
            ),
          );

      // Entrée d'outbox pour orders
      await db.into(db.syncOutbox).insert(
            db_layer.SyncOutboxCompanion.insert(
              id: idGenerator.generate(),
              entity: 'orders',
              entityId: order.id,
              op: 'upsert',
              createdAt: updatedAt,
            ),
          );

      // 2. Gestion des photos via order_photos (Diffing complet)
      final existingPhotos = await (db.select(db.orderPhotos)
            ..where((t) => t.orderId.equals(order.id) & t.deletedAt.isNull()))
          .get();

      final existingMap = {for (final p in existingPhotos) p.photoPath: p};
      final newPhotosSet = order.photos.toSet();

      // Photos supprimées (présentes en base mais absentes de newPhotos)
      for (final oldP in existingPhotos) {
        if (!newPhotosSet.contains(oldP.photoPath)) {
          await (db.update(db.orderPhotos)..where((t) => t.id.equals(oldP.id))).write(
            db_layer.OrderPhotosCompanion(
              deletedAt: Value(updatedAt),
              updatedAt: Value(updatedAt),
            ),
          );
          await db.into(db.syncOutbox).insert(
                db_layer.SyncOutboxCompanion.insert(
                  id: idGenerator.generate(),
                  entity: 'order_photos',
                  entityId: oldP.id,
                  op: 'delete',
                  createdAt: updatedAt,
                ),
              );
        }
      }

      // Photos conservées ou ajoutées
      for (var pos = 0; pos < order.photos.length; pos++) {
        final path = order.photos[pos];
        final existingRow = existingMap[path];

        if (existingRow != null) {
          // Photo existante : mise à jour de la position si elle a changé
          if (existingRow.position != pos) {
            await (db.update(db.orderPhotos)..where((t) => t.id.equals(existingRow.id))).write(
              db_layer.OrderPhotosCompanion(
                position: Value(pos),
                updatedAt: Value(updatedAt),
              ),
            );
            await db.into(db.syncOutbox).insert(
                  db_layer.SyncOutboxCompanion.insert(
                    id: idGenerator.generate(),
                    entity: 'order_photos',
                    entityId: existingRow.id,
                    op: 'upsert',
                    createdAt: updatedAt,
                  ),
                );
          }
        } else {
          // Nouvelle photo
          final photoId = idGenerator.generate();
          final photoMeta = resolvePhotoMetadata(path);
          await db.into(db.orderPhotos).insert(
                db_layer.OrderPhotosCompanion.insert(
                  id: photoId,
                  orderId: order.id,
                  photoPath: path,
                  photoHash: Value(photoMeta.hash),
                  position: Value(pos),
                  photoUploadState: Value(photoMeta.uploadState),
                  createdAt: updatedAt,
                  updatedAt: updatedAt,
                ),
              );
          await db.into(db.syncOutbox).insert(
                db_layer.SyncOutboxCompanion.insert(
                  id: idGenerator.generate(),
                  entity: 'order_photos',
                  entityId: photoId,
                  op: 'upsert',
                  createdAt: updatedAt,
                ),
              );
        }
      }
    });
  }

  @override
  Future<void> createWithDeposit({
    required Order order,
    required int depositAmount,
    String depositNote = 'Acompte',
  }) async {
    if (depositAmount <= 0) {
      throw ArgumentError('Le montant de l\'acompte doit être strictement positif.');
    }
    if (depositAmount > order.price) {
      throw ArgumentError('Le montant de l\'acompte ne peut pas être supérieur au prix.');
    }

    final now = clock.now();
    final createdAt = now;
    final updatedAt = now;
    final normDelivery = normalizeDate(order.deliveryDate);
    final normFitting = order.fittingDate != null ? normalizeDateTime(order.fittingDate!) : null;
    final deliveredAt = order.status == OrderStatus.livree ? now : null;

    await db.transaction(() async {
      // 1. Commande
      await db.into(db.orders).insert(
            db_layer.OrdersCompanion.insert(
              id: order.id,
              clientId: order.clientId,
              modeleId: Value(order.modeleId),
              title: order.title,
              fabric: Value(order.fabric),
              price: order.price,
              deliveryDate: normDelivery,
              fittingDate: Value(normFitting),
              status: Value(order.status.name),
              deliveredAt: Value(deliveredAt),
              photoPath: Value(order.photos.firstOrNull),
              photoHash: Value(resolvePhotoMetadata(order.photos.firstOrNull).hash),
              photoUploadState: Value(resolvePhotoMetadata(order.photos.firstOrNull).uploadState),
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );

      await db.into(db.syncOutbox).insert(
            db_layer.SyncOutboxCompanion.insert(
              id: idGenerator.generate(),
              entity: 'orders',
              entityId: order.id,
              op: 'upsert',
              createdAt: updatedAt,
            ),
          );

      // 2. Photos
      for (var pos = 0; pos < order.photos.length; pos++) {
        final ph = order.photos[pos];
        final photoId = idGenerator.generate();
        final photoMeta = resolvePhotoMetadata(ph);
        await db.into(db.orderPhotos).insert(
              db_layer.OrderPhotosCompanion.insert(
                id: photoId,
                orderId: order.id,
                photoPath: ph,
                photoHash: Value(photoMeta.hash),
                position: Value(pos),
                photoUploadState: Value(photoMeta.uploadState),
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
            );

        await db.into(db.syncOutbox).insert(
              db_layer.SyncOutboxCompanion.insert(
                id: idGenerator.generate(),
                entity: 'order_photos',
                entityId: photoId,
                op: 'upsert',
                createdAt: updatedAt,
              ),
            );
      }

      // 3. Versement (avec numéro de reçu séquentiel atomique et valeurs figées)
      final receiptNo = await db.nextReceiptNumber(counterName: 'clients');
      final paymentId = idGenerator.generate();
      final orderPriceAtPayment = order.price;
      final balanceAfter = order.price - depositAmount;

      await db.into(db.clientPayments).insert(
            db_layer.ClientPaymentsCompanion.insert(
              id: paymentId,
              orderId: order.id,
              amount: depositAmount,
              paidAt: now,
              receiptNumber: receiptNo,
              orderPriceAtPayment: orderPriceAtPayment,
              balanceAfter: balanceAfter,
              note: Value(depositNote),
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );

      await db.into(db.syncOutbox).insert(
            db_layer.SyncOutboxCompanion.insert(
              id: idGenerator.generate(),
              entity: 'client_payments',
              entityId: paymentId,
              op: 'upsert',
              createdAt: updatedAt,
            ),
          );
    });
  }

  @override
  Future<void> delete(String id) async {
    final now = clock.now();

    // Règle Décision 7 : refusée si au moins un versement NON annulé
    final activePayments = await (db.select(db.clientPayments)
          ..where((t) => t.orderId.equals(id) & t.voidedAt.isNull() & t.deletedAt.isNull()))
        .get();
    if (activePayments.isNotEmpty) {
      throw StateError('Impossible de supprimer une commande avec des versements actifs. Annulez d\'abord les versements.');
    }

    await db.transaction(() async {
      // Suppression logique de la commande
      await (db.update(db.orders)..where((t) => t.id.equals(id))).write(
        db_layer.OrdersCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.into(db.syncOutbox).insert(
            db_layer.SyncOutboxCompanion.insert(
              id: idGenerator.generate(),
              entity: 'orders',
              entityId: id,
              op: 'delete',
              createdAt: now,
            ),
          );

      // Suppression logique des photos de commande
      final photos = await (db.select(db.orderPhotos)
            ..where((t) => t.orderId.equals(id) & t.deletedAt.isNull()))
          .get();

      for (final p in photos) {
        await (db.update(db.orderPhotos)..where((t) => t.id.equals(p.id))).write(
          db_layer.OrderPhotosCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        await db.into(db.syncOutbox).insert(
              db_layer.SyncOutboxCompanion.insert(
                id: idGenerator.generate(),
                entity: 'order_photos',
                entityId: p.id,
                op: 'delete',
                createdAt: now,
              ),
            );
      }
    });
  }
}
