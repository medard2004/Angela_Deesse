import 'package:flutter/foundation.dart';
import '../core/format.dart';
import 'models.dart';

int _n = 0;
String newId() => 'id${DateTime.now().microsecondsSinceEpoch}_${_n++}';

DateTime _day(int off, [int h = 0, int m = 0]) => today().add(Duration(days: off, hours: h, minutes: m));

/// Données de démonstration en mémoire (maquette UI/UX, aucun back-end).
/// Les écrans lisent et modifient ce store ; il suffira plus tard de le brancher à une vraie base.
class AppStore extends ChangeNotifier {
  AppStore() {
    _seed();
  }

  String atelierName = 'Miva Couture';
  bool isDarkMode = false;
  bool hasCompletedOnboarding = false;
  bool isAuthenticated = false;

  // Configuration du Cachet / Tampon d'atelier sur les reçus
  String receiptStampTitle = 'VERSÉ';
  String receiptStampAtelierName = 'MIVA ATELIER';
  String receiptStampMention = 'OFFICIEL & CERTIFIÉ';
  int receiptStampColorValue = 0xFFB3362B; // Rouge brique couture par défaut

  List<Atelier> ateliers = [];
  String currentAtelierId = 'at0';

  Atelier get currentAtelier => ateliers.firstWhere(
        (a) => a.id == currentAtelierId,
        orElse: () => ateliers.isNotEmpty
            ? ateliers.first
            : Atelier(id: 'at0', name: atelierName),
      );

  void updateReceiptStamp({
    String? title,
    String? atelierName,
    String? mention,
    int? colorValue,
  }) {
    if (title != null) receiptStampTitle = title.trim();
    if (atelierName != null) receiptStampAtelierName = atelierName.trim();
    if (mention != null) receiptStampMention = mention.trim();
    if (colorValue != null) receiptStampColorValue = colorValue;
    _commit();
    notifyListeners();
  }

  void toggleDarkMode([bool? value]) {
    isDarkMode = value ?? !isDarkMode;
    notifyListeners();
  }

  void completeOnboarding() {
    hasCompletedOnboarding = true;
    notifyListeners();
  }

  void resetOnboarding() {
    hasCompletedOnboarding = false;
    isAuthenticated = false;
    notifyListeners();
  }

  void authenticate() {
    hasCompletedOnboarding = true;
    isAuthenticated = true;
    notifyListeners();
  }

  void switchAtelier(String id) {
    if (currentAtelierId != id && ateliers.any((a) => a.id == id)) {
      currentAtelierId = id;
      atelierName = currentAtelier.name;
      notifyListeners();
    }
  }

  void addAtelier(Atelier atelier) {
    ateliers.add(atelier);
    currentAtelierId = atelier.id;
    atelierName = atelier.name;
    notifyListeners();
  }

  void updateCurrentAtelier({
    String? name,
    String? ownerName,
    String? country,
    String? city,
    String? currency,
    String? phone,
    String? specialties,
  }) {
    final idx = ateliers.indexWhere((a) => a.id == currentAtelierId);
    if (idx != -1) {
      final current = ateliers[idx];
      ateliers[idx] = Atelier(
        id: current.id,
        name: name ?? current.name,
        ownerName: ownerName ?? current.ownerName,
        country: country ?? current.country,
        city: city ?? current.city,
        currency: currency ?? current.currency,
        phone: phone ?? current.phone,
        specialties: specialties ?? current.specialties,
        isActive: current.isActive,
      );
      if (name != null) atelierName = name;
      notifyListeners();
    }
  }

  List<Client> clients = [];
  List<Measurement> measurements = [];
  List<Modele> modeles = [];
  List<Order> orders = [];
  List<ClientPayment> clientPayments = [];
  List<Apprentice> apprentices = [];
  List<ApprenticePayment> apprenticePayments = [];
  List<Realisation> realisations = [];

  void setAtelierName(String v) {
    final val = v.trim().isEmpty ? 'Miva Couture' : v.trim();
    atelierName = val;
    updateCurrentAtelier(name: val);
    notifyListeners();
  }

  // ---------- Données de démonstration ----------
  void _seed() {
    ateliers = [
      Atelier(
        id: 'at0',
        name: 'Miva Couture - Maison Mère',
        ownerName: 'Miva Agbodjan',
        country: 'Togo',
        city: 'Lomé (Tokoin)',
        currency: 'FCFA',
        phone: '+228 90 12 34 56',
        specialties: 'Haute couture africaine, Bazin brodé, Wax & Soie',
        isActive: true,
      ),
      Atelier(
        id: 'at1',
        name: 'Miva Couture - Cotonou VIP',
        ownerName: 'Miva Agbodjan',
        country: 'Bénin',
        city: 'Cotonou (Haie Vive)',
        currency: 'FCFA',
        phone: '+229 97 45 88 12',
        specialties: 'Robes de soirée, Tenues traditionnelles, Kente',
        isActive: true,
      ),
    ];
    currentAtelierId = 'at0';
    atelierName = ateliers.first.name;
    const names = [
      ('Ama Mensah', '90 12 34 56'), ('Yawa Kpogo', '91 45 67 89'), ('Adjoa Agbodjan', '92 33 21 08'),
      ('Akouvi Lawson', '90 77 12 40'), ('Afi Dosseh', '93 18 52 66'), ('Edem Amegah', '98 04 31 72'),
      ('Mawussi Koffi', '97 66 20 15'), ('Abla Tchalla', '91 29 83 47'), ('Dzifa Ayivi', '99 50 14 38'),
    ];
    for (var i = 0; i < names.length; i++) {
      clients.add(Client(id: 'c$i', name: names[i].$1, phone: names[i].$2));
    }
    clients[1] = Client(id: 'c1', name: 'Yawa Kpogo', phone: '91 45 67 89', notes: 'Préfère les coupes ajustées.');

    for (final c in ['c0', 'c1', 'c2']) {
      final k = c == 'c0' ? 0 : c == 'c1' ? 2 : 4;
      measurements.add(Measurement(id: 'm$c', clientId: c, takenAt: _day(-20 - k), values: {
        'Épaules': 38.0 + k, 'Tour de poitrine': 92.0 + k, 'Tour de taille': 74.0 + k,
        'Tour de bassin': 100.0 + k, 'Longueur robe': 112, 'Longueur manche': 58,
      }));
    }

    const mods = [
      ('Robe sirène', 'Coupe ajustée jusqu\'aux genoux, évasée en bas.'),
      ('Ensemble pagne', 'Haut cintré et jupe longue assortie.'),
      ('Chemise bazin', 'Col mao, broderies sur le plastron.'),
      ('Costume 3 pièces', 'Veste, pantalon et gilet.'),
      ('Boubou brodé', 'Grand boubou, broderies main.'),
      ('Robe enfant', 'Robe évasée avec nœud dans le dos.'),
    ];
    for (var i = 0; i < mods.length; i++) {
      modeles.add(Modele(id: 'mo$i', name: mods[i].$1, description: mods[i].$2, photo: 'demo:$i'));
    }

    // (client, titre, tissu, prix, livraison J+, statut, déjà payé, essayage, modèle)
    final defs = <(int, String, String, int, int, OrderStatus, int, DateTime?, int?)>[
      (7, 'Robe cocktail', 'Satin émeraude', 45000, -3, OrderStatus.cours, 20000, null, null),
      (8, 'Tailleur pantalon', 'Crêpe noir', 60000, -1, OrderStatus.cours, 30000, null, null),
      (2, 'Ensemble bazin brodé', 'Bazin riche', 75000, 0, OrderStatus.prete, 50000, null, 2),
      (3, 'Robe de mariage civil', 'Dentelle ivoire', 120000, 1, OrderStatus.cours, 70000, null, 0),
      (0, 'Robe pagne', 'Wax Vlisco', 38000, 3, OrderStatus.cours, 15000, null, 1),
      (1, 'Ensemble pagne', 'Wax doré', 55000, 5, OrderStatus.essayage, 25000, _day(0, 10, 30), 1),
      (4, 'Chemise bazin', 'Bazin bleu', 28000, 9, OrderStatus.attente, 10000, null, 2),
      (5, 'Costume 3 pièces', 'Laine anthracite', 140000, 12, OrderStatus.essayage, 70000, _day(6, 15), 3),
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
      orders.add(Order(
        id: id, clientId: 'c${d.$1}', modeleId: d.$9 == null ? null : 'mo${d.$9}', title: d.$2, fabric: d.$3,
        price: d.$4, deliveryDate: _day(d.$5), fittingDate: d.$8, status: d.$6,
        photos: ['demo:${i + 1}'], createdAt: _day(d.$5 - 14),
      ));
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

    const cats = ['Robe', 'Robe', 'Chemise', 'Costume', 'Pagne', 'Pagne', 'Enfant', 'Robe', 'Costume'];
    for (var i = 0; i < cats.length; i++) {
      realisations.add(Realisation(
        id: 'r$i', photo: 'demo:${i + 2}', category: cats[i], clientId: 'c${i % 6}',
        caption: i.isEven ? modeles[i % modeles.length].name : '', createdAt: _day(-3 * i - 2),
      ));
    }
    _sort();
  }

  void _sort() {
    clients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    orders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
    measurements.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    clientPayments.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    apprenticePayments.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    apprentices.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    modeles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    realisations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
  Modele? modeleById(String? id) => modeles.where((m) => m.id == id).firstOrNull;
  Apprentice? apprenticeById(String? id) => apprentices.where((a) => a.id == id).firstOrNull;

  List<Order> ordersOfClient(String clientId) => orders.where((o) => o.clientId == clientId).toList().reversed.toList();
  List<Measurement> measurementsOf(String clientId) => measurements.where((m) => m.clientId == clientId).toList();
  List<ClientPayment> paymentsOfOrder(String orderId) => clientPayments.where((p) => p.orderId == orderId).toList();
  List<ApprenticePayment> paymentsOfApprentice(String id) => apprenticePayments.where((p) => p.apprenticeId == id).toList();

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

  // ---------- Écritures (en mémoire) ----------
  Future<void> saveClient(Client c) async => _put(clients, c, c.id, (x) => x.id);

  Future<void> deleteClient(String id) async {
    final oids = orders.where((o) => o.clientId == id).map((o) => o.id).toSet();
    clientPayments.removeWhere((p) => oids.contains(p.orderId));
    orders.removeWhere((o) => o.clientId == id);
    measurements.removeWhere((m) => m.clientId == id);
    clients.removeWhere((c) => c.id == id);
    _commit();
  }

  Future<void> saveMeasurement(Measurement m) async => _put(measurements, m, m.id, (x) => x.id);
  Future<void> deleteMeasurement(String id) async {
    measurements.removeWhere((m) => m.id == id);
    _commit();
  }

  Future<void> saveOrder(Order o) async => _put(orders, o, o.id, (x) => x.id);
  Future<void> deleteOrder(String id) async {
    clientPayments.removeWhere((p) => p.orderId == id);
    orders.removeWhere((o) => o.id == id);
    _commit();
  }

  Future<void> addClientPayment(String orderId, int amount, String note) async => _put(
      clientPayments, ClientPayment(id: newId(), orderId: orderId, amount: amount, paidAt: DateTime.now(), note: note), '', (x) => x.id);

  Future<void> deleteClientPayment(String id) async {
    clientPayments.removeWhere((p) => p.id == id);
    _commit();
  }

  Future<void> saveModele(Modele m) async => _put(modeles, m, m.id, (x) => x.id);
  Future<void> deleteModele(String id) async {
    modeles.removeWhere((m) => m.id == id);
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

  Future<void> saveRealisation(Realisation r) async => _put(realisations, r, r.id, (x) => x.id);
  Future<void> deleteRealisation(String id) async {
    realisations.removeWhere((r) => r.id == id);
    _commit();
  }
}
