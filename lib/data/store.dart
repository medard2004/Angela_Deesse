import 'dart:async';

import 'package:flutter/foundation.dart';
import '../core/format.dart';
import 'db/app_database.dart' show AppDatabase;
import 'db/clock.dart';
import 'db/demo_seeder.dart';
import 'db/id_generator.dart';
import 'models.dart';
import 'repositories/apprentice_payment_repository.dart';
import 'repositories/apprentice_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/measurement_repository.dart';
import 'repositories/modele_repository.dart';
import 'repositories/finance_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/realisation_repository.dart';
import 'repositories/settings_repository.dart';
import 'utils/sort_utils.dart';

IdGenerator defaultIdGenerator = const UuidV7IdGenerator();
String newId() => defaultIdGenerator.generate();

/// Store de l'application.
/// Façade unifiée branchée sur les repositories Drift (clients, mesures,
/// modèles, réalisations, commandes, versements clients, apprentis, versements
/// apprentis, réglages et finances).
class AppStore extends ChangeNotifier {
  AppStore({
    AppDatabase? db,
    Clock? clock,
    ClientRepository? clientRepository,
    MeasurementRepository? measurementRepository,
    ModeleRepository? modeleRepository,
    RealisationRepository? realisationRepository,
    OrderRepository? orderRepository,
    PaymentRepository? paymentRepository,
    ApprenticeRepository? apprenticeRepository,
    ApprenticePaymentRepository? apprenticePaymentRepository,
    SettingsRepository? settingsRepository,
    FinanceRepository? financeRepository,
  }) : this._(
          db ?? AppDatabase(),
          clock ?? const SystemClock(),
          clientRepository,
          measurementRepository,
          modeleRepository,
          realisationRepository,
          orderRepository,
          paymentRepository,
          apprenticeRepository,
          apprenticePaymentRepository,
          settingsRepository,
          financeRepository,
        );

  AppStore._(
    this._db,
    this._clock,
    ClientRepository? clientRepository,
    MeasurementRepository? measurementRepository,
    ModeleRepository? modeleRepository,
    RealisationRepository? realisationRepository,
    OrderRepository? orderRepository,
    PaymentRepository? paymentRepository,
    ApprenticeRepository? apprenticeRepository,
    ApprenticePaymentRepository? apprenticePaymentRepository,
    SettingsRepository? settingsRepository,
    FinanceRepository? financeRepository,
  )   : _clientRepo = clientRepository ?? DriftClientRepository(db: _db, clock: _clock),
        _measurementRepo = measurementRepository ?? DriftMeasurementRepository(db: _db, clock: _clock),
        _modeleRepo = modeleRepository ?? DriftModeleRepository(db: _db, clock: _clock),
        _realisationRepo = realisationRepository ?? DriftRealisationRepository(db: _db, clock: _clock),
        _orderRepo = orderRepository ?? DriftOrderRepository(db: _db, clock: _clock),
        _paymentRepo = paymentRepository ?? DriftPaymentRepository(db: _db, clock: _clock),
        _apprenticeRepo = apprenticeRepository ?? DriftApprenticeRepository(db: _db, clock: _clock),
        _apprenticePaymentRepo = apprenticePaymentRepository ?? DriftApprenticePaymentRepository(db: _db, clock: _clock),
        _settingsRepo = settingsRepository ?? DriftSettingsRepository(db: _db, clock: _clock),
        _financeRepo = financeRepository ?? DriftFinanceRepository(db: _db, clock: _clock);

  final AppDatabase _db;
  final Clock _clock;
  final ClientRepository _clientRepo;
  final MeasurementRepository _measurementRepo;
  final ModeleRepository _modeleRepo;
  final RealisationRepository _realisationRepo;
  final OrderRepository _orderRepo;
  final PaymentRepository _paymentRepo;
  final ApprenticeRepository _apprenticeRepo;
  final ApprenticePaymentRepository _apprenticePaymentRepo;
  final SettingsRepository _settingsRepo;
  final FinanceRepository _financeRepo;

  StreamSubscription<List<Client>>? _clientSub;
  StreamSubscription<List<Measurement>>? _measurementSub;
  StreamSubscription<List<Modele>>? _modeleSub;
  StreamSubscription<List<Realisation>>? _realisationSub;
  StreamSubscription<List<Order>>? _orderSub;
  StreamSubscription<List<ClientPayment>>? _paymentSub;
  StreamSubscription<List<Apprentice>>? _apprenticeSub;
  StreamSubscription<List<ApprenticePayment>>? _apprenticePaymentSub;
  StreamSubscription<Map<String, String>>? _settingsSub;
  StreamSubscription<FinanceSummary>? _financeSub;

  Map<String, Modele> _allModelesById = {};
  Map<String, String> _settingsMap = {};
  FinanceSummary? _financeSummary;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  AppDatabase get db => _db;
  ClientRepository get clientRepo => _clientRepo;
  MeasurementRepository get measurementRepo => _measurementRepo;
  ModeleRepository get modeleRepo => _modeleRepo;
  RealisationRepository get realisationRepo => _realisationRepo;
  OrderRepository get orderRepo => _orderRepo;
  PaymentRepository get paymentRepo => _paymentRepo;
  ApprenticeRepository get apprenticeRepo => _apprenticeRepo;
  ApprenticePaymentRepository get apprenticePaymentRepo => _apprenticePaymentRepo;
  SettingsRepository get settingsRepo => _settingsRepo;
  FinanceRepository get financeRepo => _financeRepo;

  String get atelierName => _settingsMap[kSettingAtelierName] ?? kDefaultAtelierName;
  bool get notifDelivery => _settingsMap[kSettingNotifDelivery] != 'false';
  bool get notifFitting => _settingsMap[kSettingNotifFitting] != 'false';
  bool get notifPayments => _settingsMap[kSettingNotifPayments] != 'false';
  bool get notifLate => _settingsMap[kSettingNotifLate] != 'false';

  int get monthTotal => _financeSummary?.monthTotal ?? 0;
  List<MonthCashFlow> get last6Months => _financeSummary?.last6Months ?? [];
  PunctualityStats get punctualityStats => _financeSummary?.punctuality ?? const PunctualityStats(onTimeCount: 0, totalCount: 0, rate: null);
  double? get punctualityRate => punctualityStats.rate;

  List<Client> clients = [];
  List<Measurement> measurements = [];
  List<Modele> modeles = [];
  List<Order> orders = [];
  List<ClientPayment> clientPayments = [];
  List<Apprentice> apprentices = [];
  List<ApprenticePayment> apprenticePayments = [];
  List<Realisation> realisations = [];

  Future<void> setAtelierName(String v) async {
    final name = v.trim().isEmpty ? kDefaultAtelierName : v.trim();
    await _settingsRepo.set(kSettingAtelierName, name);
    _settingsMap[kSettingAtelierName] = name;
    notifyListeners();
  }

  Future<void> setNotifDelivery(bool v) async {
    final str = v ? 'true' : 'false';
    await _settingsRepo.set(kSettingNotifDelivery, str);
    _settingsMap[kSettingNotifDelivery] = str;
    notifyListeners();
  }

  Future<void> setNotifFitting(bool v) async {
    final str = v ? 'true' : 'false';
    await _settingsRepo.set(kSettingNotifFitting, str);
    _settingsMap[kSettingNotifFitting] = str;
    notifyListeners();
  }

  Future<void> setNotifPayments(bool v) async {
    final str = v ? 'true' : 'false';
    await _settingsRepo.set(kSettingNotifPayments, str);
    _settingsMap[kSettingNotifPayments] = str;
    notifyListeners();
  }

  Future<void> setNotifLate(bool v) async {
    final str = v ? 'true' : 'false';
    await _settingsRepo.set(kSettingNotifLate, str);
    _settingsMap[kSettingNotifLate] = str;
    notifyListeners();
  }

  /// Initialise la persistance Drift (seeding si nécessaire, chargement du cache et écoute des streams).
  Future<void> init({bool seedDemo = true}) async {
    if (_initialized) return;

    if (seedDemo) {
      await DemoSeeder(_db, clock: _clock).seedIfNecessary();
    }

    final dbClients = await _clientRepo.getAll();
    clients = _sortClients(dbClients);

    final dbMeasurements = await _measurementRepo.getAll();
    measurements = _sortMeasurements(dbMeasurements);

    final dbModeles = await _modeleRepo.getAll();
    modeles = _sortModeles(dbModeles);

    final allModeles = await _modeleRepo.getAllIncludingDeleted();
    _allModelesById = {for (final m in allModeles) m.id: m};

    final dbRealisations = await _realisationRepo.getAll();
    realisations = _sortRealisations(dbRealisations);

    final dbOrders = await _orderRepo.getAll();
    orders = _sortOrders(dbOrders);

    final dbPayments = await _paymentRepo.getAll();
    clientPayments = _sortPayments(dbPayments);

    final dbApprentices = await _apprenticeRepo.getAll();
    apprentices = _sortApprentices(dbApprentices);

    final dbApprenticePayments = await _apprenticePaymentRepo.getAll();
    apprenticePayments = _sortApprenticePayments(dbApprenticePayments);

    final dbSettings = await _settingsRepo.getAll();
    _settingsMap = Map<String, String>.from(dbSettings);

    final dbFinance = await _financeRepo.getSummary();
    _financeSummary = dbFinance;

    _clientSub?.cancel();
    _clientSub = _clientRepo.watchAll().listen((list) {
      clients = _sortClients(list);
      notifyListeners();
    });

    _measurementSub?.cancel();
    _measurementSub = _measurementRepo.watchAll().listen((list) {
      measurements = _sortMeasurements(list);
      notifyListeners();
    });

    _modeleSub?.cancel();
    _modeleSub = _modeleRepo.watchAll().listen((list) {
      modeles = _sortModeles(list);
      for (final m in list) {
        _allModelesById[m.id] = m;
      }
      notifyListeners();
    });

    _realisationSub?.cancel();
    _realisationSub = _realisationRepo.watchAll().listen((list) {
      realisations = _sortRealisations(list);
      notifyListeners();
    });

    _orderSub?.cancel();
    _orderSub = _orderRepo.watchAll().listen((list) {
      orders = _sortOrders(list);
      notifyListeners();
    });

    _paymentSub?.cancel();
    _paymentSub = _paymentRepo.watchAll().listen((list) {
      clientPayments = _sortPayments(list);
      notifyListeners();
    });

    _apprenticeSub?.cancel();
    _apprenticeSub = _apprenticeRepo.watchAll().listen((list) {
      apprentices = _sortApprentices(list);
      notifyListeners();
    });

    _apprenticePaymentSub?.cancel();
    _apprenticePaymentSub = _apprenticePaymentRepo.watchAll().listen((list) {
      apprenticePayments = _sortApprenticePayments(list);
      notifyListeners();
    });

    _settingsSub?.cancel();
    _settingsSub = _settingsRepo.watchAll().listen((map) {
      _settingsMap = Map<String, String>.from(map);
      notifyListeners();
    });

    _financeSub?.cancel();
    _financeSub = _financeRepo.watchSummary().listen((summary) {
      _financeSummary = summary;
      notifyListeners();
    });

    await _db.reconcileReceiptCounters();

    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _clientSub?.cancel();
    _measurementSub?.cancel();
    _modeleSub?.cancel();
    _realisationSub?.cancel();
    _orderSub?.cancel();
    _paymentSub?.cancel();
    _apprenticeSub?.cancel();
    _apprenticePaymentSub?.cancel();
    _settingsSub?.cancel();
    _financeSub?.cancel();
    super.dispose();
  }

  List<Client> _sortClients(List<Client> list) {
    final copy = List<Client>.from(list);
    copy.sort((a, b) => compareCaseAndAccentInsensitive(a.name, b.name));
    return copy;
  }

  List<Measurement> _sortMeasurements(List<Measurement> list) {
    final copy = List<Measurement>.from(list);
    copy.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return copy;
  }

  List<Modele> _sortModeles(List<Modele> list) {
    final copy = List<Modele>.from(list);
    copy.sort((a, b) => compareCaseAndAccentInsensitive(a.name, b.name));
    return copy;
  }

  List<Realisation> _sortRealisations(List<Realisation> list) {
    final copy = List<Realisation>.from(list);
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  List<Order> _sortOrders(List<Order> list) {
    final copy = List<Order>.from(list);
    copy.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
    return copy;
  }

  List<ClientPayment> _sortPayments(List<ClientPayment> list) {
    final copy = List<ClientPayment>.from(list);
    copy.sort((a, b) {
      final d = b.paidAt.compareTo(a.paidAt);
      if (d != 0) return d;
      return b.receiptNumber.compareTo(a.receiptNumber);
    });
    return copy;
  }

  List<Apprentice> _sortApprentices(List<Apprentice> list) {
    final copy = List<Apprentice>.from(list);
    copy.sort((a, b) => compareCaseAndAccentInsensitive(a.name, b.name));
    return copy;
  }

  List<ApprenticePayment> _sortApprenticePayments(List<ApprenticePayment> list) {
    final copy = List<ApprenticePayment>.from(list);
    copy.sort((a, b) {
      final d = b.paidAt.compareTo(a.paidAt);
      if (d != 0) return d;
      return b.receiptNumber.compareTo(a.receiptNumber);
    });
    return copy;
  }

  // ---------- Lookups ----------
  Client? clientById(String? id) => clients.where((c) => c.id == id).firstOrNull;
  Order? orderById(String? id) => orders.where((o) => o.id == id).firstOrNull;
  Modele? modeleById(String? id) {
    if (id == null) return null;
    return _allModelesById[id] ?? modeles.where((m) => m.id == id).firstOrNull;
  }
  Apprentice? apprenticeById(String? id) => apprentices.where((a) => a.id == id).firstOrNull;

  List<Order> ordersOfClient(String clientId) => orders.where((o) => o.clientId == clientId).toList().reversed.toList();
  List<Measurement> measurementsOf(String clientId) => measurements.where((m) => m.clientId == clientId).toList();
  List<ClientPayment> paymentsOfOrder(String orderId) => clientPayments.where((p) => p.orderId == orderId).toList();
  List<ClientPayment> activePaymentsOf(String orderId) =>
      clientPayments.where((p) => p.orderId == orderId && !p.isVoided).toList();
  List<ApprenticePayment> paymentsOfApprentice(String apprenticeId) =>
      apprenticePayments.where((p) => p.apprenticeId == apprenticeId).toList();
  List<ApprenticePayment> activePaymentsOfApprentice(String apprenticeId) =>
      apprenticePayments.where((p) => p.apprenticeId == apprenticeId && !p.isVoided).toList();

  // ---------- Calculs ----------
  int paidOf(Order o) => activePaymentsOf(o.id).fold(0, (s, p) => s + p.amount);
  int remainingOf(Order o) => (o.price - paidOf(o)).clamp(0, 1 << 40).toInt();
  int clientRemaining(String clientId) => ordersOfClient(clientId).fold(0, (s, o) => s + remainingOf(o));
  int get totalClientRemaining => _financeSummary?.totalClientRemaining ?? orders.fold(0, (s, o) => s + remainingOf(o));

  int apprenticePaid(Apprentice a) => activePaymentsOfApprentice(a.id).fold(0, (s, p) => s + p.amount);
  int apprenticeRemaining(Apprentice a) => (a.totalFee - apprenticePaid(a)).clamp(0, 1 << 40).toInt();
  int get totalApprenticeRemaining => _financeSummary?.totalApprenticeRemaining ?? apprentices.fold(0, (s, a) => s + apprenticeRemaining(a));

  List<Order> get activeOrders => orders.where((o) => o.isActive).toList();
  List<Order> get lateOrders => orders.where((o) => o.isActive && daysUntil(o.deliveryDate) < 0).toList();

  // ---------- Écritures Clients & Mesures (Drift) ----------
  Future<void> saveClient(Client c) async {
    await _clientRepo.save(c);
    clients = _sortClients(await _clientRepo.getAll());
    notifyListeners();
  }

  Future<void> deleteClient(String id) async {
    final hasOrders = await _orderRepo.hasNonDeletedOrdersForClient(id);
    if (hasOrders) {
      throw StateError('Impossible de supprimer un client ayant des commandes actives.');
    }
    await _clientRepo.delete(id);
    clients = _sortClients(await _clientRepo.getAll());
    measurements = _sortMeasurements(await _measurementRepo.getAll());
    notifyListeners();
  }

  Future<void> saveMeasurement(Measurement m) async {
    await _measurementRepo.save(m);
    measurements = _sortMeasurements(await _measurementRepo.getAll());
    notifyListeners();
  }

  Future<void> deleteMeasurement(String id) async {
    await _measurementRepo.delete(id);
    measurements = _sortMeasurements(await _measurementRepo.getAll());
    notifyListeners();
  }

  // ---------- Écritures Modèles & Réalisations (Drift) ----------
  Future<void> saveModele(Modele m) async {
    await _modeleRepo.save(m);
    modeles = _sortModeles(await _modeleRepo.getAll());
    _allModelesById[m.id] = m;
    notifyListeners();
  }

  Future<void> deleteModele(String id) async {
    await _modeleRepo.delete(id);
    modeles = _sortModeles(await _modeleRepo.getAll());
    // On conserve le modèle dans _allModelesById pour que les commandes existantes
    // puissent toujours résoudre son nom et sa photo via modeleById(id).
    notifyListeners();
  }

  Future<void> saveRealisation(Realisation r) async {
    await _realisationRepo.save(r);
    realisations = _sortRealisations(await _realisationRepo.getAll());
    notifyListeners();
  }

  Future<void> deleteRealisation(String id) async {
    await _realisationRepo.delete(id);
    realisations = _sortRealisations(await _realisationRepo.getAll());
    notifyListeners();
  }

  // ---------- Écritures Commandes (Drift) ----------
  Future<void> saveOrder(Order o, {int? initialDeposit, String? depositNote}) async {
    if (initialDeposit != null && initialDeposit > 0) {
      await _orderRepo.createWithDeposit(
        order: o,
        depositAmount: initialDeposit,
        depositNote: depositNote ?? 'Acompte',
      );
      clientPayments = _sortPayments(await _paymentRepo.getAll());
    } else {
      await _orderRepo.save(o);
    }
    orders = _sortOrders(await _orderRepo.getAll());
    notifyListeners();
  }

  Future<void> deleteOrder(String id) async {
    await _orderRepo.delete(id);
    orders = _sortOrders(await _orderRepo.getAll());
    notifyListeners();
  }

  // ---------- Écritures Versements Clients & Reçus (Drift) ----------
  Future<ClientPayment> addClientPayment(String orderId, int amount, String note) async {
    final o = orderById(orderId);
    if (o == null) {
      throw StateError('Commande introuvable.');
    }
    final rest = remainingOf(o);
    if (amount > rest) {
      throw ArgumentError('Le montant du versement ($amount FCFA) dépasse le reliquat restant ($rest FCFA).');
    }
    final p = await _paymentRepo.addPayment(
      orderId: orderId,
      amount: amount,
      note: note,
    );
    clientPayments = _sortPayments(await _paymentRepo.getAll());
    notifyListeners();
    return p;
  }

  Future<ClientPayment> voidClientPayment(String id, String reason) async {
    final p = await _paymentRepo.voidPayment(id: id, reason: reason);
    clientPayments = _sortPayments(await _paymentRepo.getAll());
    notifyListeners();
    return p;
  }

  Future<void> deleteClientPayment(String id, [String reason = 'Annulé']) async {
    await voidClientPayment(id, reason);
  }

  // ---------- Écritures Apprentis (Drift) ----------
  Future<ApprenticePayment?> saveApprentice(
    Apprentice a, {
    int? initialDeposit,
    String? depositNote,
  }) async {
    final ApprenticePayment? payment;
    if (initialDeposit != null && initialDeposit > 0) {
      payment = await _apprenticeRepo.createWithDeposit(
        apprentice: a,
        depositAmount: initialDeposit,
        depositNote: depositNote ?? 'Acompte inscription',
      );
    } else {
      await _apprenticeRepo.save(a);
      payment = null;
    }
    apprentices = _sortApprentices(await _apprenticeRepo.getAll());
    apprenticePayments = _sortApprenticePayments(await _apprenticePaymentRepo.getAll());
    notifyListeners();
    return payment;
  }

  Future<void> deleteApprentice(String id) async {
    final hasActive = await _apprenticeRepo.hasActivePaymentsForApprentice(id);
    if (hasActive) {
      throw StateError('Impossible de supprimer un apprenti avec des versements actifs.');
    }
    await _apprenticeRepo.delete(id);
    apprentices = _sortApprentices(await _apprenticeRepo.getAll());
    notifyListeners();
  }

  // ---------- Écritures Versements Apprentis & Reçus (Drift) ----------
  Future<ApprenticePayment> addApprenticePayment(String apprenticeId, int amount, String note) async {
    final a = apprenticeById(apprenticeId);
    if (a == null) {
      throw StateError('Apprenti introuvable.');
    }
    final rest = apprenticeRemaining(a);
    if (amount > rest) {
      throw ArgumentError('Le montant du versement ($amount FCFA) dépasse le reste à payer ($rest FCFA).');
    }
    final p = await _apprenticePaymentRepo.addPayment(
      apprenticeId: apprenticeId,
      amount: amount,
      note: note,
    );
    apprenticePayments = _sortApprenticePayments(await _apprenticePaymentRepo.getAll());
    notifyListeners();
    return p;
  }

  Future<ApprenticePayment> voidApprenticePayment(String id, String reason) async {
    final p = await _apprenticePaymentRepo.voidPayment(id: id, reason: reason);
    apprenticePayments = _sortApprenticePayments(await _apprenticePaymentRepo.getAll());
    notifyListeners();
    return p;
  }

  Future<void> deleteApprenticePayment(String id, [String reason = 'Annulé']) async {
    await voidApprenticePayment(id, reason);
  }
}
