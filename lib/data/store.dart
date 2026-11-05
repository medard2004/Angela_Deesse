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
  }) : this._(
          db ?? AppDatabase(),
          clientRepository,
          measurementRepository,
          modeleRepository,
          realisationRepository,
          orderRepository,
        );

  AppStore._(
    this._db,
    ClientRepository? clientRepository,
    MeasurementRepository? measurementRepository,
    ModeleRepository? modeleRepository,
    RealisationRepository? realisationRepository,
    OrderRepository? orderRepository,
  )   : _clientRepo = clientRepository ?? DriftClientRepository(db: _db),
        _measurementRepo = measurementRepository ?? DriftMeasurementRepository(db: _db),
        _modeleRepo = modeleRepository ?? DriftModeleRepository(db: _db),
        _realisationRepo = realisationRepository ?? DriftRealisationRepository(db: _db),
        _orderRepo = orderRepository ?? DriftOrderRepository(db: _db) {
    _seedInMemory();
  }

  final AppDatabase _db;
  final ClientRepository _clientRepo;
  final MeasurementRepository _measurementRepo;
  final ModeleRepository _modeleRepo;
  final RealisationRepository _realisationRepo;
  final OrderRepository _orderRepo;

  StreamSubscription<List<Client>>? _clientSub;
  StreamSubscription<List<Measurement>>? _measurementSub;
  StreamSubscription<List<Modele>>? _modeleSub;
  StreamSubscription<List<Realisation>>? _realisationSub;
  StreamSubscription<List<Order>>? _orderSub;

  Map<String, Modele> _allModelesById = {};

  bool _initialized = false;
  bool get isInitialized => _initialized;

  AppDatabase get db => _db;
  ClientRepository get clientRepo => _clientRepo;
  MeasurementRepository get measurementRepo => _measurementRepo;
  ModeleRepository get modeleRepo => _modeleRepo;
  RealisationRepository get realisationRepo => _realisationRepo;
  OrderRepository get orderRepo => _orderRepo;

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

  // ---------- Données de démonstration (entités encore en mémoire) ----------
  void _seedInMemory() {
    // (client, titre, tissu, prix, livraison J+, statut, déjà payé, essayage, modèle)
    final defs = <(int, String, String, int, int, OrderStatus, int, DateTime?, int?)>[
      (7, 'Robe cocktail', 'Satin émeraude', 45000, -3, OrderStatus.cours, 20000, null, null),
      (8, 'Tailleur pantalon', 'Crêpe noir', 60000, -1, OrderStatus.cours, 30000, null, null),
      (2, 'Ensemble bazin brodé', 'Bazin riche', 75000, 0, OrderStatus.prete, 50000, null, 2),
      (3, 'Robe de mariage civil', 'Dentelle ivoire', 120000, 1, OrderStatus.cours, 70000, null, 0),
      (0, 'Robe pagne', 'Wax Vlisco', 38000, 3, OrderStatus.cours, 15000, null, 1),
      (1, 'Ensemble pagne', 'Wax doré', 55000, 5, OrderStatus.attente, 25000, _day(0, 10, 30), 1),
      (4, 'Chemise bazin', 'Bazin bleu', 28000, 9, OrderStatus.attente, 10000, null, 2),
      (5, 'Costume 3 pièces', 'Laine anthracite', 140000, 12, OrderStatus.cours, 70000, _day(6, 15), 3),
      (6, 'Boubou brodé', 'Brocart blanc', 95000, 14, OrderStatus.attente, 30000, _day(8, 9), 4),
      (0, 'Robe enfant', 'Coton rose', 22000, 16, OrderStatus.attente, 0, null, 5),
      (4, 'Jupe wax', 'Wax Hollandais', 18000, 20, OrderStatus.attente, 18000, null, null),
      (8, 'Robe longue', 'Satin bordeaux', 52000, 25, OrderStatus.attente, 20000, null, 0),
      (2, 'Robe wax', 'Wax rouge', 30000, -10, OrderStatus.livree, 30000, null, null),
      (1, 'Chemise', 'Bazin blanc', 25000, -15, OrderStatus.livree, 25000, null, 2),
      (5, 'Costume', 'Lin beige', 110000, -20, OrderStatus.livree, 110000, null, 3),
    ];
    for (var i = 0; i < defs.length; i++) {
      final d = defs[i];
      final id = 'o$i';
      final paid = d.$7;
      if (paid >= 50000) {
        final first = (paid * .6 / 5000).round() * 5000;
        clientPayments.add(ClientPayment(id: 'p${i}a', orderId: id, amount: first, paidAt: _day(-(6 + i)), note: 'Acompte'));
        clientPayments.add(ClientPayment(id: 'p${i}b', orderId: id, amount: paid - first, paidAt: _day(-(i % 4)), note: 'Complément'));
      } else if (paid > 0) {
        clientPayments.add(ClientPayment(id: 'p${i}a', orderId: id, amount: paid, paidAt: _day(-(i % 9)), note: 'Acompte'));
      }
    }

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
    clientPayments.sort((a, b) => b.paidAt.compareTo(a.paidAt));
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
  List<ApprenticePayment> paymentsOfApprentice(String apprenticeId) =>
      apprenticePayments.where((p) => p.apprenticeId == apprenticeId).toList();

  // ---------- Calculs ----------
  int paidOf(Order o) => paymentsOfOrder(o.id).fold(0, (s, p) => s + p.amount);
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
  Future<void> saveOrder(Order o) async {
    await _orderRepo.save(o);
    orders = _sortOrders(await _orderRepo.getAll());
    notifyListeners();
  }

  Future<void> deleteOrder(String id) async {
    await _orderRepo.delete(id);
    orders = _sortOrders(await _orderRepo.getAll());
    notifyListeners();
  }

  Future<void> addClientPayment(String orderId, int amount, String note) async => _put(
      clientPayments, ClientPayment(id: newId(), orderId: orderId, amount: amount, paidAt: DateTime.now(), note: note), '', (x) => x.id);

  Future<void> deleteClientPayment(String id) async {
    clientPayments.removeWhere((p) => p.id == id);
    _commit();
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
