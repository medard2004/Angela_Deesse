import 'dart:convert';

int _i(Object? v) => (v as num).toInt();
DateTime _d(Object? v) => DateTime.fromMillisecondsSinceEpoch(_i(v));
DateTime? _dn(Object? v) => v == null ? null : _d(v);
String _s(Object? v) => (v as String?) ?? '';

const kMeasureLabels = [
  'Épaules', 'Tour de poitrine', 'Tour de taille', 'Tour de bassin',
  'Longueur dos', 'Longueur manche', 'Tour de bras', 'Longueur robe',
  'Longueur jupe', 'Longueur pantalon', 'Tour de cuisse', 'Entrejambe',
];

const kCategories = ['Robe', 'Chemise', 'Costume', 'Pagne', 'Enfant', 'Autre'];

class Client {
  Client({required this.id, required this.name, this.phone = '', this.notes = ''});
  final String id;
  final String name, phone, notes;
  Map<String, Object?> toMap() => {'id': id, 'name': name, 'phone': phone, 'notes': notes};
  factory Client.fromMap(Map<String, Object?> m) =>
      Client(id: m['id'] as String, name: _s(m['name']), phone: _s(m['phone']), notes: _s(m['notes']));
}

class Measurement {
  Measurement({required this.id, required this.clientId, required this.takenAt, required this.values, this.note = ''});
  final String id, clientId, note;
  final DateTime takenAt;
  final Map<String, double> values;
  Map<String, Object?> toMap() => {
        'id': id, 'client_id': clientId, 'taken_at': takenAt.millisecondsSinceEpoch,
        'vals': jsonEncode(values), 'note': note,
      };
  factory Measurement.fromMap(Map<String, Object?> m) => Measurement(
        id: m['id'] as String,
        clientId: m['client_id'] as String,
        takenAt: _d(m['taken_at']),
        values: (jsonDecode(m['vals'] as String) as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        note: _s(m['note']),
      );
}

class Modele {
  Modele({required this.id, required this.name, this.description = '', this.photo});
  final String id, name, description;
  final String? photo;
  Map<String, Object?> toMap() => {'id': id, 'name': name, 'description': description, 'photo': photo};
  factory Modele.fromMap(Map<String, Object?> m) => Modele(
      id: m['id'] as String, name: _s(m['name']), description: _s(m['description']), photo: m['photo'] as String?);
}

enum OrderStatus {
  attente('En attente'),
  cours('En cours'),
  prete('Prête'),
  livree('Livrée');

  const OrderStatus(this.label);
  final String label;
}

class Order {
  Order({
    required this.id, required this.clientId, this.modeleId, required this.title, this.fabric = '',
    required this.price, required this.deliveryDate, this.fittingDate, this.status = OrderStatus.attente,
    this.deliveredAt, this.photos = const [], required this.createdAt,
  });
  final String id, clientId, title, fabric;
  final String? modeleId;
  final int price;
  final DateTime deliveryDate, createdAt;
  final DateTime? fittingDate, deliveredAt;
  final OrderStatus status;
  final List<String> photos;
  bool get isActive => status != OrderStatus.livree;

  Order copyWith({OrderStatus? status, DateTime? deliveredAt, int? price, String? title, String? fabric, DateTime? deliveryDate, DateTime? fittingDate}) => Order(
        id: id, clientId: clientId, modeleId: modeleId, title: title ?? this.title, fabric: fabric ?? this.fabric, price: price ?? this.price,
        deliveryDate: deliveryDate ?? this.deliveryDate, fittingDate: fittingDate ?? this.fittingDate, status: status ?? this.status,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        photos: photos, createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id, 'client_id': clientId, 'modele_id': modeleId, 'title': title, 'fabric': fabric,
        'price': price, 'delivery_date': deliveryDate.millisecondsSinceEpoch,
        'fitting_date': fittingDate?.millisecondsSinceEpoch,
        'delivered_at': deliveredAt?.millisecondsSinceEpoch,
        'status': status.name,
        'photos': jsonEncode(photos), 'created_at': createdAt.millisecondsSinceEpoch,
      };
  factory Order.fromMap(Map<String, Object?> m) => Order(
        id: m['id'] as String,
        clientId: m['client_id'] as String,
        modeleId: m['modele_id'] as String?,
        title: _s(m['title']),
        fabric: _s(m['fabric']),
        price: _i(m['price']),
        deliveryDate: _d(m['delivery_date']),
        fittingDate: _dn(m['fitting_date']),
        deliveredAt: _dn(m['delivered_at']),
        status: OrderStatus.values.firstWhere((e) => e.name == m['status'], orElse: () => OrderStatus.attente),
        photos: (jsonDecode(_s(m['photos']).isEmpty ? '[]' : m['photos'] as String) as List).cast<String>(),
        createdAt: _d(m['created_at']),
      );
}

class ClientPayment {
  ClientPayment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paidAt,
    this.note = '',
    this.receiptNumber = 0,
    this.orderPriceAtPayment = 0,
    this.balanceAfter = 0,
    this.voidedAt,
    this.voidReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? paidAt,
        updatedAt = updatedAt ?? paidAt;

  final String id, orderId, note;
  final int amount;
  final DateTime paidAt;
  final int receiptNumber;
  final int orderPriceAtPayment;
  final int balanceAfter;
  final DateTime? voidedAt;
  final String? voidReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVoided => voidedAt != null;

  Map<String, Object?> toMap() => {
        'id': id,
        'order_id': orderId,
        'amount': amount,
        'paid_at': paidAt.millisecondsSinceEpoch,
        'note': note,
        'receipt_number': receiptNumber,
        'order_price_at_payment': orderPriceAtPayment,
        'balance_after': balanceAfter,
        'voided_at': voidedAt?.millisecondsSinceEpoch,
        'void_reason': voidReason,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ClientPayment.fromMap(Map<String, Object?> m) => ClientPayment(
        id: m['id'] as String,
        orderId: m['order_id'] as String,
        amount: _i(m['amount']),
        paidAt: _d(m['paid_at']),
        note: _s(m['note']),
        receiptNumber: _i(m['receipt_number']),
        orderPriceAtPayment: _i(m['order_price_at_payment']),
        balanceAfter: _i(m['balance_after']),
        voidedAt: _dn(m['voided_at']),
        voidReason: m['void_reason'] as String?,
        createdAt: m['created_at'] != null ? _d(m['created_at']) : null,
        updatedAt: m['updated_at'] != null ? _d(m['updated_at']) : null,
      );
}

class Apprentice {
  Apprentice({
    required this.id, required this.name, this.phone = '', required this.startDate,
    required this.totalFee, this.nextDue, this.notes = '',
  });
  final String id, name, phone, notes;
  final DateTime startDate;
  final DateTime? nextDue;
  final int totalFee;
  Map<String, Object?> toMap() => {
        'id': id, 'name': name, 'phone': phone, 'start_date': startDate.millisecondsSinceEpoch,
        'total_fee': totalFee, 'next_due': nextDue?.millisecondsSinceEpoch, 'notes': notes,
      };
  factory Apprentice.fromMap(Map<String, Object?> m) => Apprentice(
      id: m['id'] as String, name: _s(m['name']), phone: _s(m['phone']), startDate: _d(m['start_date']),
      totalFee: _i(m['total_fee']), nextDue: _dn(m['next_due']), notes: _s(m['notes']));
}

class ApprenticePayment {
  ApprenticePayment({
    required this.id, required this.apprenticeId, required this.amount, required this.paidAt,
    this.note = '', required this.receiptNo,
  });
  final String id, apprenticeId, note;
  final int amount, receiptNo;
  final DateTime paidAt;
  Map<String, Object?> toMap() => {
        'id': id, 'apprentice_id': apprenticeId, 'amount': amount,
        'paid_at': paidAt.millisecondsSinceEpoch, 'note': note, 'receipt_no': receiptNo,
      };
  factory ApprenticePayment.fromMap(Map<String, Object?> m) => ApprenticePayment(
      id: m['id'] as String, apprenticeId: m['apprentice_id'] as String, amount: _i(m['amount']),
      paidAt: _d(m['paid_at']), note: _s(m['note']), receiptNo: _i(m['receipt_no']));
}

class Realisation {
  Realisation({required this.id, required this.photo, this.category = 'Autre', this.clientId, this.caption = '', required this.createdAt});
  final String id, photo, category, caption;
  final String? clientId;
  final DateTime createdAt;
  Map<String, Object?> toMap() => {
        'id': id, 'photo': photo, 'category': category, 'client_id': clientId, 'caption': caption,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
  factory Realisation.fromMap(Map<String, Object?> m) => Realisation(
      id: m['id'] as String, photo: _s(m['photo']), category: _s(m['category']), clientId: m['client_id'] as String?,
      caption: _s(m['caption']), createdAt: _d(m['created_at']));
}
