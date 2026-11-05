import 'dart:async';

import 'package:flutter/foundation.dart';
import '../core/format.dart';
import 'db/app_database.dart' show AppDatabase;
import 'db/demo_seeder.dart';
import 'db/id_generator.dart';
import 'models.dart';
import 'repositories/client_repository.dart';
import 'repositories/measurement_repository.dart';
import 'repositories/modele_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/realisation_repository.dart';
import 'utils/sort_utils.dart';

IdGenerator defaultIdGenerator = const UuidV7IdGenerator();
String newId() => defaultIdGenerator.generate();

DateTime _day(int off, [int h = 0, int m = 0]) => today().add(Duration(days: off, hours: h, minutes: m));

/// Store de l'application.
/// Pour les clients, mesures, modèles et réalisations : façade branchée sur les repositories Drift.
/// Les autres entités (commandes, finances, etc.) restent en mémoire pour les tranches suivantes.
class AppStore extends ChangeNotifier {
  AppStore({
    AppDatabase? db,
    ClientRepository? clientRepository,
    MeasurementRepository? measurementRepository,
    ModeleRepository? modeleRepository,
    RealisationRepository? realisationRepository,
    OrderRepository? orderRepository,
    PaymentRepository? paymentRepository,
  }) : this._(
          db ?? AppDatabase(),
          clientRepository,
          measurementRepository,
          modeleRepository,
          realisationRepository,
          orderRepository,
          paymentRepository,
        );

  AppStore._(
    this._db,
    ClientRepository? clientRepository,
    MeasurementRepository? measurementRepository,
    ModeleRepository? modeleRepository,
    RealisationRepository? realisationRepository,
    OrderRepository? orderRepository,
    PaymentRepository? paymentRepository,
  )   : _clientRepo = clientRepository ?? DriftClientRepository(db: _db),
        _measurementRepo = measurementRepository ?? DriftMeasurementRepository(db: _db),
        _modeleRepo = modeleRepository ?? DriftModeleRepository(db: _db),
        _realisationRepo = realisationRepository ?? DriftRealisationRepository(db: _db),
        _orderRepo = orderRepository ?? DriftOrderRepository(db: _db),
        _paymentRepo = paymentRepository ?? DriftPaymentRepository(db: _db) {
    _seedInMemory();
  }

  final AppDatabase _db;
  final ClientRepository _clientRepo;
  final MeasurementRepository _measurementRepo;
  final ModeleRepository _modeleRepo;
  final RealisationRepository _realisationRepo;
  final OrderRepository _orderRepo;
  final PaymentRepository _paymentRepo;

  StreamSubscription<List<Client>>? _clientSub;
  StreamSubscription<List<Measurement>>? _measurementSub;
  StreamSubscription<List<Modele>>? _modeleSub;
  StreamSubscription<List<Realisation>>? _realisationSub;
  StreamSubscription<List<Order>>? _orderSub;
  StreamSubscription<List<ClientPayment>>? _paymentSub;

  Map<String, Modele> _allModelesById = {};

  bool _initialized = false;
  bool get isInitialized => _initialized;

  AppDatabase get db => _db;
  ClientRepository get clientRepo => _clientRepo;
  MeasurementRepository get measurementRepo => _measurementRepo;
  ModeleRepository get modeleRepo => _modeleRepo;
  RealisationRepository get realisationRepo => _realisationRepo;
  OrderRepository get orderRepo => _orderRepo;
  PaymentRepository get paymentRepo => _paymentRepo;

  String atelierName = 'Angela Couture';
  List<Client> clients = [];
  List<Measurement> measurements = [];
  List<Modele> modeles = [];
  List<Order> orders = [];
  List<ClientPayment> clientPayments = [];
  List<Apprentice> apprentices = [];
  List<ApprenticePayment> apprenticePayments = [];
  List<Realisation> realisations = [];

  void setAtelierName(String v) {
    atelierName = v.trim().isEmpty ? 'Angela Couture' : v.trim();
    notifyListeners();
  }

  /// Initialise la persistance Drift (seeding si nécessaire, chargement du cache et écoute des streams).
  Future<void> init() async {
    if (_initialized) return;

    await DemoSeeder(_db).seedIfNecessary();

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

  // ---------- Données de démonstration (entités encore en mémoire) ----------
  void _seedInMemory() {
    apprentices = [
      Apprentice(id: 'a0', name: 'Kafui Amedome', phone: '90 22 41 18', startDate: _day(-120), totalFee: 150000, nextDue: _day(4)),
      Apprentice(id: 'a1', name: 'Mawuli Sodji', phone: '91 08 77 30', startDate: _day(-200), totalFee: 120000, nextDue: _day(-2)),
      Apprentice(id: 'a2', name: 'Essi Gbadoe', phone: '93 61 09 52', startDate: _day(-300), totalFee: 150000),
    ];
    final ap = <(String, int, int)>[('a0', 50000, -60), ('a0', 30000, -5), ('a1', 60000, -40), ('a2', 100000, -200), ('a2', 50000, -40)];
    for (var i = 0; i < ap.length; i++) {
      apprenticePayments.add(ApprenticePayment(
        id: 'ap$i', apprenticeId: ap[i].$1, amount: ap[i].$2, paidAt: _day(ap[i].$3), receiptNo: i + 1, note: i == 1 ? 'Mensualité' : '',
      ));
    }

    _sort();
  }

  void _sort() {
    clients = _sortClients(clients);
    orders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
    measurements = _sortMeasurements(measurements);
    clientPayments = _sortPayments(clientPayments);
    apprenticePayments.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    apprentices.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    modeles = _sortModeles(modeles);
    realisations = _sortRealisations(realisations);
  }

  void _commit() {
    _sort();
    notifyListeners();
  }

  void _put<T>(List<T> list, T item, String id, String Function(T) idOf) {
    final i = list.indexWhere((x) => idOf(x) == id);
    i >= 0 ? list[i] = item : list.add(item);
    _commit();
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

  // ---------- Calculs ----------
  int paidOf(Order o) => activePaymentsOf(o.id).fold(0, (s, p) => s + p.amount);
  int remainingOf(Order o) => (o.price - paidOf(o)).clamp(0, 1 << 40).toInt();
  int clientRemaining(String clientId) => ordersOfClient(clientId).fold(0, (s, o) => s + remainingOf(o));
  int get totalClientRemaining => orders.fold(0, (s, o) => s + remainingOf(o));

  int apprenticePaid(Apprentice a) => paymentsOfApprentice(a.id).fold(0, (s, p) => s + p.amount);
  int apprenticeRemaining(Apprentice a) => (a.totalFee - apprenticePaid(a)).clamp(0, 1 << 40).toInt();
  int get totalApprenticeRemaining => apprentices.fold(0, (s, a) => s + apprenticeRemaining(a));

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

  Future<void> saveApprentice(Apprentice a) async => _put(apprentices, a, a.id, (x) => x.id);
  Future<void> deleteApprentice(String id) async {
    apprenticePayments.removeWhere((p) => p.apprenticeId == id);
    apprentices.removeWhere((a) => a.id == id);
    _commit();
  }

  Future<ApprenticePayment> addApprenticePayment(String apprenticeId, int amount, String note) async {
    final next = apprenticePayments.fold(0, (m, p) => p.receiptNo > m ? p.receiptNo : m) + 1;
    final p = ApprenticePayment(
        id: newId(), apprenticeId: apprenticeId, amount: amount, paidAt: DateTime.now(), note: note, receiptNo: next);
    apprenticePayments.add(p);
    _commit();
    return p;
  }

  Future<void> deleteApprenticePayment(String id) async {
    apprenticePayments.removeWhere((p) => p.id == id);
    _commit();
  }
}
