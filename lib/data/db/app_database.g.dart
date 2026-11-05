// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ClientsTable extends Clients with TableInfo<$ClientsTable, Client> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ClientsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ClientsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>('deleted_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($ClientsTable.$converterdeletedAt);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, phone, notes, createdAt, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients';
  @override
  VerificationContext validateIntegrity(Insertable<Client> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Client map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Client(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdAt: $ClientsTable.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updatedAt: $ClientsTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
      deletedAt: $ClientsTable.$converterdeletedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at'])),
    );
  }

  @override
  $ClientsTable createAlias(String alias) {
    return $ClientsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAt =
      const NullableDateTimeConverter();
}

class Client extends DataClass implements Insertable<Client> {
  final String id;
  final String name;
  final String phone;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Client(
      {required this.id,
      required this.name,
      required this.phone,
      required this.notes,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['notes'] = Variable<String>(notes);
    {
      map['created_at'] =
          Variable<int>($ClientsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] =
          Variable<int>($ClientsTable.$converterupdatedAt.toSql(updatedAt));
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] =
          Variable<int>($ClientsTable.$converterdeletedAt.toSql(deletedAt));
    }
    return map;
  }

  ClientsCompanion toCompanion(bool nullToAbsent) {
    return ClientsCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Client.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Client(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Client copyWith(
          {String? id,
          String? name,
          String? phone,
          String? notes,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Client(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Client copyWithCompanion(ClientsCompanion data) {
    return Client(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Client(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, notes, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Client &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ClientsCompanion extends UpdateCompanion<Client> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ClientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Client> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? phone,
      Value<String>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return ClientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $ClientsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $ClientsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
          $ClientsTable.$converterdeletedAt.toSql(deletedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, Measurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
      'client_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES clients (id)'));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> takenAt =
      GeneratedColumn<int>('taken_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($MeasurementsTable.$convertertakenAt);
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, double>, String>
      measures = GeneratedColumn<String>('measures', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Map<String, double>>(
              $MeasurementsTable.$convertermeasures);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($MeasurementsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($MeasurementsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>('deleted_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($MeasurementsTable.$converterdeletedAt);
  @override
  List<GeneratedColumn> get $columns =>
      [id, clientId, takenAt, measures, note, createdAt, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(Insertable<Measurement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Measurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Measurement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_id'])!,
      takenAt: $MeasurementsTable.$convertertakenAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}taken_at'])!),
      measures: $MeasurementsTable.$convertermeasures.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}measures'])!),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      createdAt: $MeasurementsTable.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updatedAt: $MeasurementsTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
      deletedAt: $MeasurementsTable.$converterdeletedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at'])),
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertertakenAt =
      const DateTimeConverter();
  static TypeConverter<Map<String, double>, String> $convertermeasures =
      const MeasurementValuesConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAt =
      const NullableDateTimeConverter();
}

class Measurement extends DataClass implements Insertable<Measurement> {
  final String id;
  final String clientId;
  final DateTime takenAt;
  final Map<String, double> measures;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Measurement(
      {required this.id,
      required this.clientId,
      required this.takenAt,
      required this.measures,
      required this.note,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    {
      map['taken_at'] =
          Variable<int>($MeasurementsTable.$convertertakenAt.toSql(takenAt));
    }
    {
      map['measures'] = Variable<String>(
          $MeasurementsTable.$convertermeasures.toSql(measures));
    }
    map['note'] = Variable<String>(note);
    {
      map['created_at'] = Variable<int>(
          $MeasurementsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(
          $MeasurementsTable.$converterupdatedAt.toSql(updatedAt));
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
          $MeasurementsTable.$converterdeletedAt.toSql(deletedAt));
    }
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      id: Value(id),
      clientId: Value(clientId),
      takenAt: Value(takenAt),
      measures: Value(measures),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Measurement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Measurement(
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      measures: serializer.fromJson<Map<String, double>>(json['measures']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'measures': serializer.toJson<Map<String, double>>(measures),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Measurement copyWith(
          {String? id,
          String? clientId,
          DateTime? takenAt,
          Map<String, double>? measures,
          String? note,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Measurement(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        takenAt: takenAt ?? this.takenAt,
        measures: measures ?? this.measures,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Measurement copyWithCompanion(MeasurementsCompanion data) {
    return Measurement(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      measures: data.measures.present ? data.measures.value : this.measures,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Measurement(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('takenAt: $takenAt, ')
          ..write('measures: $measures, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, clientId, takenAt, measures, note, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Measurement &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.takenAt == this.takenAt &&
          other.measures == this.measures &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MeasurementsCompanion extends UpdateCompanion<Measurement> {
  final Value<String> id;
  final Value<String> clientId;
  final Value<DateTime> takenAt;
  final Value<Map<String, double>> measures;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MeasurementsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.measures = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    required String id,
    required String clientId,
    required DateTime takenAt,
    required Map<String, double> measures,
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        clientId = Value(clientId),
        takenAt = Value(takenAt),
        measures = Value(measures),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Measurement> custom({
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<int>? takenAt,
    Expression<String>? measures,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (takenAt != null) 'taken_at': takenAt,
      if (measures != null) 'measures': measures,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeasurementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? clientId,
      Value<DateTime>? takenAt,
      Value<Map<String, double>>? measures,
      Value<String>? note,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return MeasurementsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      takenAt: takenAt ?? this.takenAt,
      measures: measures ?? this.measures,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<int>(
          $MeasurementsTable.$convertertakenAt.toSql(takenAt.value));
    }
    if (measures.present) {
      map['measures'] = Variable<String>(
          $MeasurementsTable.$convertermeasures.toSql(measures.value));
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $MeasurementsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $MeasurementsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
          $MeasurementsTable.$converterdeletedAt.toSql(deletedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('takenAt: $takenAt, ')
          ..write('measures: $measures, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModelesTable extends Modeles with TableInfo<$ModelesTable, Modele> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoHashMeta =
      const VerificationMeta('photoHash');
  @override
  late final GeneratedColumn<String> photoHash = GeneratedColumn<String>(
      'photo_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoUploadStateMeta =
      const VerificationMeta('photoUploadState');
  @override
  late final GeneratedColumn<String> photoUploadState = GeneratedColumn<String>(
      'photo_upload_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ModelesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ModelesTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>('deleted_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($ModelesTable.$converterdeletedAt);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        photoPath,
        photoHash,
        photoUploadState,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'modeles';
  @override
  VerificationContext validateIntegrity(Insertable<Modele> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('photo_hash')) {
      context.handle(_photoHashMeta,
          photoHash.isAcceptableOrUnknown(data['photo_hash']!, _photoHashMeta));
    }
    if (data.containsKey('photo_upload_state')) {
      context.handle(
          _photoUploadStateMeta,
          photoUploadState.isAcceptableOrUnknown(
              data['photo_upload_state']!, _photoUploadStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Modele map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Modele(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      photoHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_hash']),
      photoUploadState: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}photo_upload_state'])!,
      createdAt: $ModelesTable.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updatedAt: $ModelesTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
      deletedAt: $ModelesTable.$converterdeletedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at'])),
    );
  }

  @override
  $ModelesTable createAlias(String alias) {
    return $ModelesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAt =
      const NullableDateTimeConverter();
}

class Modele extends DataClass implements Insertable<Modele> {
  final String id;
  final String name;
  final String description;
  final String? photoPath;
  final String? photoHash;
  final String photoUploadState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Modele(
      {required this.id,
      required this.name,
      required this.description,
      this.photoPath,
      this.photoHash,
      required this.photoUploadState,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || photoHash != null) {
      map['photo_hash'] = Variable<String>(photoHash);
    }
    map['photo_upload_state'] = Variable<String>(photoUploadState);
    {
      map['created_at'] =
          Variable<int>($ModelesTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] =
          Variable<int>($ModelesTable.$converterupdatedAt.toSql(updatedAt));
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] =
          Variable<int>($ModelesTable.$converterdeletedAt.toSql(deletedAt));
    }
    return map;
  }

  ModelesCompanion toCompanion(bool nullToAbsent) {
    return ModelesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      photoHash: photoHash == null && nullToAbsent
          ? const Value.absent()
          : Value(photoHash),
      photoUploadState: Value(photoUploadState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Modele.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Modele(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      photoHash: serializer.fromJson<String?>(json['photoHash']),
      photoUploadState: serializer.fromJson<String>(json['photoUploadState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'photoPath': serializer.toJson<String?>(photoPath),
      'photoHash': serializer.toJson<String?>(photoHash),
      'photoUploadState': serializer.toJson<String>(photoUploadState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Modele copyWith(
          {String? id,
          String? name,
          String? description,
          Value<String?> photoPath = const Value.absent(),
          Value<String?> photoHash = const Value.absent(),
          String? photoUploadState,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Modele(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        photoHash: photoHash.present ? photoHash.value : this.photoHash,
        photoUploadState: photoUploadState ?? this.photoUploadState,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Modele copyWithCompanion(ModelesCompanion data) {
    return Modele(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoHash: data.photoHash.present ? data.photoHash.value : this.photoHash,
      photoUploadState: data.photoUploadState.present
          ? data.photoUploadState.value
          : this.photoUploadState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Modele(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoHash: $photoHash, ')
          ..write('photoUploadState: $photoUploadState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, photoPath, photoHash,
      photoUploadState, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Modele &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.photoPath == this.photoPath &&
          other.photoHash == this.photoHash &&
          other.photoUploadState == this.photoUploadState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ModelesCompanion extends UpdateCompanion<Modele> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String?> photoPath;
  final Value<String?> photoHash;
  final Value<String> photoUploadState;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ModelesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoHash = const Value.absent(),
    this.photoUploadState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoHash = const Value.absent(),
    this.photoUploadState = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Modele> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? photoPath,
    Expression<String>? photoHash,
    Expression<String>? photoUploadState,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoHash != null) 'photo_hash': photoHash,
      if (photoUploadState != null) 'photo_upload_state': photoUploadState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? description,
      Value<String?>? photoPath,
      Value<String?>? photoHash,
      Value<String>? photoUploadState,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return ModelesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      photoHash: photoHash ?? this.photoHash,
      photoUploadState: photoUploadState ?? this.photoUploadState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoHash.present) {
      map['photo_hash'] = Variable<String>(photoHash.value);
    }
    if (photoUploadState.present) {
      map['photo_upload_state'] = Variable<String>(photoUploadState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $ModelesTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $ModelesTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
          $ModelesTable.$converterdeletedAt.toSql(deletedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModelesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoHash: $photoHash, ')
          ..write('photoUploadState: $photoUploadState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
      'client_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES clients (id)'));
  static const VerificationMeta _modeleIdMeta =
      const VerificationMeta('modeleId');
  @override
  late final GeneratedColumn<String> modeleId = GeneratedColumn<String>(
      'modele_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES modeles (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fabricMeta = const VerificationMeta('fabric');
  @override
  late final GeneratedColumn<String> fabric = GeneratedColumn<String>(
      'fabric', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
      'price', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> deliveryDate =
      GeneratedColumn<int>('delivery_date', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($OrdersTable.$converterdeliveryDate);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> fittingDate =
      GeneratedColumn<int>('fitting_date', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($OrdersTable.$converterfittingDate);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('attente'));
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoHashMeta =
      const VerificationMeta('photoHash');
  @override
  late final GeneratedColumn<String> photoHash = GeneratedColumn<String>(
      'photo_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoUploadStateMeta =
      const VerificationMeta('photoUploadState');
  @override
  late final GeneratedColumn<String> photoUploadState = GeneratedColumn<String>(
      'photo_upload_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($OrdersTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($OrdersTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>('deleted_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($OrdersTable.$converterdeletedAt);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientId,
        modeleId,
        title,
        fabric,
        price,
        deliveryDate,
        fittingDate,
        status,
        photoPath,
        photoHash,
        photoUploadState,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(Insertable<Order> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('modele_id')) {
      context.handle(_modeleIdMeta,
          modeleId.isAcceptableOrUnknown(data['modele_id']!, _modeleIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('fabric')) {
      context.handle(_fabricMeta,
          fabric.isAcceptableOrUnknown(data['fabric']!, _fabricMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('photo_hash')) {
      context.handle(_photoHashMeta,
          photoHash.isAcceptableOrUnknown(data['photo_hash']!, _photoHashMeta));
    }
    if (data.containsKey('photo_upload_state')) {
      context.handle(
          _photoUploadStateMeta,
          photoUploadState.isAcceptableOrUnknown(
              data['photo_upload_state']!, _photoUploadStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_id'])!,
      modeleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}modele_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      fabric: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fabric'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price'])!,
      deliveryDate: $OrdersTable.$converterdeliveryDate.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}delivery_date'])!),
      fittingDate: $OrdersTable.$converterfittingDate.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fitting_date'])),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      photoHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_hash']),
      photoUploadState: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}photo_upload_state'])!,
      createdAt: $OrdersTable.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updatedAt: $OrdersTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
      deletedAt: $OrdersTable.$converterdeletedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at'])),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdeliveryDate =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterfittingDate =
      const NullableDateTimeConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAt =
      const NullableDateTimeConverter();
}

class Order extends DataClass implements Insertable<Order> {
  final String id;
  final String clientId;
  final String? modeleId;
  final String title;
  final String fabric;
  final int price;
  final DateTime deliveryDate;
  final DateTime? fittingDate;
  final String status;
  final String? photoPath;
  final String? photoHash;
  final String photoUploadState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Order(
      {required this.id,
      required this.clientId,
      this.modeleId,
      required this.title,
      required this.fabric,
      required this.price,
      required this.deliveryDate,
      this.fittingDate,
      required this.status,
      this.photoPath,
      this.photoHash,
      required this.photoUploadState,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || modeleId != null) {
      map['modele_id'] = Variable<String>(modeleId);
    }
    map['title'] = Variable<String>(title);
    map['fabric'] = Variable<String>(fabric);
    map['price'] = Variable<int>(price);
    {
      map['delivery_date'] = Variable<int>(
          $OrdersTable.$converterdeliveryDate.toSql(deliveryDate));
    }
    if (!nullToAbsent || fittingDate != null) {
      map['fitting_date'] =
          Variable<int>($OrdersTable.$converterfittingDate.toSql(fittingDate));
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || photoHash != null) {
      map['photo_hash'] = Variable<String>(photoHash);
    }
    map['photo_upload_state'] = Variable<String>(photoUploadState);
    {
      map['created_at'] =
          Variable<int>($OrdersTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] =
          Variable<int>($OrdersTable.$converterupdatedAt.toSql(updatedAt));
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] =
          Variable<int>($OrdersTable.$converterdeletedAt.toSql(deletedAt));
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      clientId: Value(clientId),
      modeleId: modeleId == null && nullToAbsent
          ? const Value.absent()
          : Value(modeleId),
      title: Value(title),
      fabric: Value(fabric),
      price: Value(price),
      deliveryDate: Value(deliveryDate),
      fittingDate: fittingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(fittingDate),
      status: Value(status),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      photoHash: photoHash == null && nullToAbsent
          ? const Value.absent()
          : Value(photoHash),
      photoUploadState: Value(photoUploadState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Order.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      modeleId: serializer.fromJson<String?>(json['modeleId']),
      title: serializer.fromJson<String>(json['title']),
      fabric: serializer.fromJson<String>(json['fabric']),
      price: serializer.fromJson<int>(json['price']),
      deliveryDate: serializer.fromJson<DateTime>(json['deliveryDate']),
      fittingDate: serializer.fromJson<DateTime?>(json['fittingDate']),
      status: serializer.fromJson<String>(json['status']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      photoHash: serializer.fromJson<String?>(json['photoHash']),
      photoUploadState: serializer.fromJson<String>(json['photoUploadState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'modeleId': serializer.toJson<String?>(modeleId),
      'title': serializer.toJson<String>(title),
      'fabric': serializer.toJson<String>(fabric),
      'price': serializer.toJson<int>(price),
      'deliveryDate': serializer.toJson<DateTime>(deliveryDate),
      'fittingDate': serializer.toJson<DateTime?>(fittingDate),
      'status': serializer.toJson<String>(status),
      'photoPath': serializer.toJson<String?>(photoPath),
      'photoHash': serializer.toJson<String?>(photoHash),
      'photoUploadState': serializer.toJson<String>(photoUploadState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Order copyWith(
          {String? id,
          String? clientId,
          Value<String?> modeleId = const Value.absent(),
          String? title,
          String? fabric,
          int? price,
          DateTime? deliveryDate,
          Value<DateTime?> fittingDate = const Value.absent(),
          String? status,
          Value<String?> photoPath = const Value.absent(),
          Value<String?> photoHash = const Value.absent(),
          String? photoUploadState,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Order(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        modeleId: modeleId.present ? modeleId.value : this.modeleId,
        title: title ?? this.title,
        fabric: fabric ?? this.fabric,
        price: price ?? this.price,
        deliveryDate: deliveryDate ?? this.deliveryDate,
        fittingDate: fittingDate.present ? fittingDate.value : this.fittingDate,
        status: status ?? this.status,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        photoHash: photoHash.present ? photoHash.value : this.photoHash,
        photoUploadState: photoUploadState ?? this.photoUploadState,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      modeleId: data.modeleId.present ? data.modeleId.value : this.modeleId,
      title: data.title.present ? data.title.value : this.title,
      fabric: data.fabric.present ? data.fabric.value : this.fabric,
      price: data.price.present ? data.price.value : this.price,
      deliveryDate: data.deliveryDate.present
          ? data.deliveryDate.value
          : this.deliveryDate,
      fittingDate:
          data.fittingDate.present ? data.fittingDate.value : this.fittingDate,
      status: data.status.present ? data.status.value : this.status,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoHash: data.photoHash.present ? data.photoHash.value : this.photoHash,
      photoUploadState: data.photoUploadState.present
          ? data.photoUploadState.value
          : this.photoUploadState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('modeleId: $modeleId, ')
          ..write('title: $title, ')
          ..write('fabric: $fabric, ')
          ..write('price: $price, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('fittingDate: $fittingDate, ')
          ..write('status: $status, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoHash: $photoHash, ')
          ..write('photoUploadState: $photoUploadState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      clientId,
      modeleId,
      title,
      fabric,
      price,
      deliveryDate,
      fittingDate,
      status,
      photoPath,
      photoHash,
      photoUploadState,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.modeleId == this.modeleId &&
          other.title == this.title &&
          other.fabric == this.fabric &&
          other.price == this.price &&
          other.deliveryDate == this.deliveryDate &&
          other.fittingDate == this.fittingDate &&
          other.status == this.status &&
          other.photoPath == this.photoPath &&
          other.photoHash == this.photoHash &&
          other.photoUploadState == this.photoUploadState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<String> id;
  final Value<String> clientId;
  final Value<String?> modeleId;
  final Value<String> title;
  final Value<String> fabric;
  final Value<int> price;
  final Value<DateTime> deliveryDate;
  final Value<DateTime?> fittingDate;
  final Value<String> status;
  final Value<String?> photoPath;
  final Value<String?> photoHash;
  final Value<String> photoUploadState;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.modeleId = const Value.absent(),
    this.title = const Value.absent(),
    this.fabric = const Value.absent(),
    this.price = const Value.absent(),
    this.deliveryDate = const Value.absent(),
    this.fittingDate = const Value.absent(),
    this.status = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoHash = const Value.absent(),
    this.photoUploadState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required String clientId,
    this.modeleId = const Value.absent(),
    required String title,
    this.fabric = const Value.absent(),
    required int price,
    required DateTime deliveryDate,
    this.fittingDate = const Value.absent(),
    this.status = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoHash = const Value.absent(),
    this.photoUploadState = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        clientId = Value(clientId),
        title = Value(title),
        price = Value(price),
        deliveryDate = Value(deliveryDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Order> custom({
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<String>? modeleId,
    Expression<String>? title,
    Expression<String>? fabric,
    Expression<int>? price,
    Expression<int>? deliveryDate,
    Expression<int>? fittingDate,
    Expression<String>? status,
    Expression<String>? photoPath,
    Expression<String>? photoHash,
    Expression<String>? photoUploadState,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (modeleId != null) 'modele_id': modeleId,
      if (title != null) 'title': title,
      if (fabric != null) 'fabric': fabric,
      if (price != null) 'price': price,
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      if (fittingDate != null) 'fitting_date': fittingDate,
      if (status != null) 'status': status,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoHash != null) 'photo_hash': photoHash,
      if (photoUploadState != null) 'photo_upload_state': photoUploadState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith(
      {Value<String>? id,
      Value<String>? clientId,
      Value<String?>? modeleId,
      Value<String>? title,
      Value<String>? fabric,
      Value<int>? price,
      Value<DateTime>? deliveryDate,
      Value<DateTime?>? fittingDate,
      Value<String>? status,
      Value<String?>? photoPath,
      Value<String?>? photoHash,
      Value<String>? photoUploadState,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return OrdersCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      modeleId: modeleId ?? this.modeleId,
      title: title ?? this.title,
      fabric: fabric ?? this.fabric,
      price: price ?? this.price,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      fittingDate: fittingDate ?? this.fittingDate,
      status: status ?? this.status,
      photoPath: photoPath ?? this.photoPath,
      photoHash: photoHash ?? this.photoHash,
      photoUploadState: photoUploadState ?? this.photoUploadState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (modeleId.present) {
      map['modele_id'] = Variable<String>(modeleId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (fabric.present) {
      map['fabric'] = Variable<String>(fabric.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (deliveryDate.present) {
      map['delivery_date'] = Variable<int>(
          $OrdersTable.$converterdeliveryDate.toSql(deliveryDate.value));
    }
    if (fittingDate.present) {
      map['fitting_date'] = Variable<int>(
          $OrdersTable.$converterfittingDate.toSql(fittingDate.value));
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoHash.present) {
      map['photo_hash'] = Variable<String>(photoHash.value);
    }
    if (photoUploadState.present) {
      map['photo_upload_state'] = Variable<String>(photoUploadState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $OrdersTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $OrdersTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
          $OrdersTable.$converterdeletedAt.toSql(deletedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('modeleId: $modeleId, ')
          ..write('title: $title, ')
          ..write('fabric: $fabric, ')
          ..write('price: $price, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('fittingDate: $fittingDate, ')
          ..write('status: $status, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoHash: $photoHash, ')
          ..write('photoUploadState: $photoUploadState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderPhotosTable extends OrderPhotos
    with TableInfo<$OrderPhotosTable, OrderPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orders (id)'));
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photoHashMeta =
      const VerificationMeta('photoHash');
  @override
  late final GeneratedColumn<String> photoHash = GeneratedColumn<String>(
      'photo_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoUploadStateMeta =
      const VerificationMeta('photoUploadState');
  @override
  late final GeneratedColumn<String> photoUploadState = GeneratedColumn<String>(
      'photo_upload_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($OrderPhotosTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($OrderPhotosTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>('deleted_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($OrderPhotosTable.$converterdeletedAt);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        photoPath,
        photoHash,
        photoUploadState,
        position,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_photos';
  @override
  VerificationContext validateIntegrity(Insertable<OrderPhoto> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    } else if (isInserting) {
      context.missing(_photoPathMeta);
    }
    if (data.containsKey('photo_hash')) {
      context.handle(_photoHashMeta,
          photoHash.isAcceptableOrUnknown(data['photo_hash']!, _photoHashMeta));
    }
    if (data.containsKey('photo_upload_state')) {
      context.handle(
          _photoUploadStateMeta,
          photoUploadState.isAcceptableOrUnknown(
              data['photo_upload_state']!, _photoUploadStateMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderPhoto(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path'])!,
      photoHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_hash']),
      photoUploadState: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}photo_upload_state'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      createdAt: $OrderPhotosTable.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updatedAt: $OrderPhotosTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
      deletedAt: $OrderPhotosTable.$converterdeletedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at'])),
    );
  }

  @override
  $OrderPhotosTable createAlias(String alias) {
    return $OrderPhotosTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAt =
      const NullableDateTimeConverter();
}

class OrderPhoto extends DataClass implements Insertable<OrderPhoto> {
  final String id;
  final String orderId;
  final String photoPath;
  final String? photoHash;
  final String photoUploadState;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const OrderPhoto(
      {required this.id,
      required this.orderId,
      required this.photoPath,
      this.photoHash,
      required this.photoUploadState,
      required this.position,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['photo_path'] = Variable<String>(photoPath);
    if (!nullToAbsent || photoHash != null) {
      map['photo_hash'] = Variable<String>(photoHash);
    }
    map['photo_upload_state'] = Variable<String>(photoUploadState);
    map['position'] = Variable<int>(position);
    {
      map['created_at'] =
          Variable<int>($OrderPhotosTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] =
          Variable<int>($OrderPhotosTable.$converterupdatedAt.toSql(updatedAt));
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] =
          Variable<int>($OrderPhotosTable.$converterdeletedAt.toSql(deletedAt));
    }
    return map;
  }

  OrderPhotosCompanion toCompanion(bool nullToAbsent) {
    return OrderPhotosCompanion(
      id: Value(id),
      orderId: Value(orderId),
      photoPath: Value(photoPath),
      photoHash: photoHash == null && nullToAbsent
          ? const Value.absent()
          : Value(photoHash),
      photoUploadState: Value(photoUploadState),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory OrderPhoto.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderPhoto(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      photoHash: serializer.fromJson<String?>(json['photoHash']),
      photoUploadState: serializer.fromJson<String>(json['photoUploadState']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'photoPath': serializer.toJson<String>(photoPath),
      'photoHash': serializer.toJson<String?>(photoHash),
      'photoUploadState': serializer.toJson<String>(photoUploadState),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  OrderPhoto copyWith(
          {String? id,
          String? orderId,
          String? photoPath,
          Value<String?> photoHash = const Value.absent(),
          String? photoUploadState,
          int? position,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      OrderPhoto(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        photoPath: photoPath ?? this.photoPath,
        photoHash: photoHash.present ? photoHash.value : this.photoHash,
        photoUploadState: photoUploadState ?? this.photoUploadState,
        position: position ?? this.position,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  OrderPhoto copyWithCompanion(OrderPhotosCompanion data) {
    return OrderPhoto(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoHash: data.photoHash.present ? data.photoHash.value : this.photoHash,
      photoUploadState: data.photoUploadState.present
          ? data.photoUploadState.value
          : this.photoUploadState,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderPhoto(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoHash: $photoHash, ')
          ..write('photoUploadState: $photoUploadState, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, orderId, photoPath, photoHash,
      photoUploadState, position, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderPhoto &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.photoPath == this.photoPath &&
          other.photoHash == this.photoHash &&
          other.photoUploadState == this.photoUploadState &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class OrderPhotosCompanion extends UpdateCompanion<OrderPhoto> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> photoPath;
  final Value<String?> photoHash;
  final Value<String> photoUploadState;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const OrderPhotosCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoHash = const Value.absent(),
    this.photoUploadState = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderPhotosCompanion.insert({
    required String id,
    required String orderId,
    required String photoPath,
    this.photoHash = const Value.absent(),
    this.photoUploadState = const Value.absent(),
    this.position = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orderId = Value(orderId),
        photoPath = Value(photoPath),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<OrderPhoto> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? photoPath,
    Expression<String>? photoHash,
    Expression<String>? photoUploadState,
    Expression<int>? position,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoHash != null) 'photo_hash': photoHash,
      if (photoUploadState != null) 'photo_upload_state': photoUploadState,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderPhotosCompanion copyWith(
      {Value<String>? id,
      Value<String>? orderId,
      Value<String>? photoPath,
      Value<String?>? photoHash,
      Value<String>? photoUploadState,
      Value<int>? position,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return OrderPhotosCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      photoPath: photoPath ?? this.photoPath,
      photoHash: photoHash ?? this.photoHash,
      photoUploadState: photoUploadState ?? this.photoUploadState,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoHash.present) {
      map['photo_hash'] = Variable<String>(photoHash.value);
    }
    if (photoUploadState.present) {
      map['photo_upload_state'] = Variable<String>(photoUploadState.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $OrderPhotosTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $OrderPhotosTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
          $OrderPhotosTable.$converterdeletedAt.toSql(deletedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderPhotosCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoHash: $photoHash, ')
          ..write('photoUploadState: $photoUploadState, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientPaymentsTable extends ClientPayments
    with TableInfo<$ClientPaymentsTable, ClientPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orders (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> paidAt =
      GeneratedColumn<int>('paid_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ClientPaymentsTable.$converterpaidAt);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _receiptNumberMeta =
      const VerificationMeta('receiptNumber');
  @override
  late final GeneratedColumn<int> receiptNumber = GeneratedColumn<int>(
      'receipt_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> voidedAt =
      GeneratedColumn<int>('voided_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($ClientPaymentsTable.$convertervoidedAt);
  static const VerificationMeta _voidReasonMeta =
      const VerificationMeta('voidReason');
  @override
  late final GeneratedColumn<String> voidReason = GeneratedColumn<String>(
      'void_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ClientPaymentsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ClientPaymentsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>('deleted_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($ClientPaymentsTable.$converterdeletedAt);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        amount,
        paidAt,
        note,
        receiptNumber,
        voidedAt,
        voidReason,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'client_payments';
  @override
  VerificationContext validateIntegrity(Insertable<ClientPayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('receipt_number')) {
      context.handle(
          _receiptNumberMeta,
          receiptNumber.isAcceptableOrUnknown(
              data['receipt_number']!, _receiptNumberMeta));
    } else if (isInserting) {
      context.missing(_receiptNumberMeta);
    }
    if (data.containsKey('void_reason')) {
      context.handle(
          _voidReasonMeta,
          voidReason.isAcceptableOrUnknown(
              data['void_reason']!, _voidReasonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientPayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      paidAt: $ClientPaymentsTable.$converterpaidAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}paid_at'])!),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      receiptNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}receipt_number'])!,
      voidedAt: $ClientPaymentsTable.$convertervoidedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}voided_at'])),
      voidReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}void_reason']),
      createdAt: $ClientPaymentsTable.$convertercreatedAt.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updatedAt: $ClientPaymentsTable.$converterupdatedAt.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
      deletedAt: $ClientPaymentsTable.$converterdeletedAt.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}deleted_at'])),
    );
  }

  @override
  $ClientPaymentsTable createAlias(String alias) {
    return $ClientPaymentsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterpaidAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $convertervoidedAt =
      const NullableDateTimeConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAt =
      const NullableDateTimeConverter();
}

class ClientPayment extends DataClass implements Insertable<ClientPayment> {
  final String id;
  final String orderId;
  final int amount;
  final DateTime paidAt;
  final String note;
  final int receiptNumber;
  final DateTime? voidedAt;
  final String? voidReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const ClientPayment(
      {required this.id,
      required this.orderId,
      required this.amount,
      required this.paidAt,
      required this.note,
      required this.receiptNumber,
      this.voidedAt,
      this.voidReason,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['amount'] = Variable<int>(amount);
    {
      map['paid_at'] =
          Variable<int>($ClientPaymentsTable.$converterpaidAt.toSql(paidAt));
    }
    map['note'] = Variable<String>(note);
    map['receipt_number'] = Variable<int>(receiptNumber);
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<int>(
          $ClientPaymentsTable.$convertervoidedAt.toSql(voidedAt));
    }
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    {
      map['created_at'] = Variable<int>(
          $ClientPaymentsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(
          $ClientPaymentsTable.$converterupdatedAt.toSql(updatedAt));
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
          $ClientPaymentsTable.$converterdeletedAt.toSql(deletedAt));
    }
    return map;
  }

  ClientPaymentsCompanion toCompanion(bool nullToAbsent) {
    return ClientPaymentsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      amount: Value(amount),
      paidAt: Value(paidAt),
      note: Value(note),
      receiptNumber: Value(receiptNumber),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ClientPayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientPayment(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      amount: serializer.fromJson<int>(json['amount']),
      paidAt: serializer.fromJson<DateTime>(json['paidAt']),
      note: serializer.fromJson<String>(json['note']),
      receiptNumber: serializer.fromJson<int>(json['receiptNumber']),
      voidedAt: serializer.fromJson<DateTime?>(json['voidedAt']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'amount': serializer.toJson<int>(amount),
      'paidAt': serializer.toJson<DateTime>(paidAt),
      'note': serializer.toJson<String>(note),
      'receiptNumber': serializer.toJson<int>(receiptNumber),
      'voidedAt': serializer.toJson<DateTime?>(voidedAt),
      'voidReason': serializer.toJson<String?>(voidReason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ClientPayment copyWith(
          {String? id,
          String? orderId,
          int? amount,
          DateTime? paidAt,
          String? note,
          int? receiptNumber,
          Value<DateTime?> voidedAt = const Value.absent(),
          Value<String?> voidReason = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      ClientPayment(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        amount: amount ?? this.amount,
        paidAt: paidAt ?? this.paidAt,
        note: note ?? this.note,
        receiptNumber: receiptNumber ?? this.receiptNumber,
        voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
        voidReason: voidReason.present ? voidReason.value : this.voidReason,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  ClientPayment copyWithCompanion(ClientPaymentsCompanion data) {
    return ClientPayment(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      amount: data.amount.present ? data.amount.value : this.amount,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      note: data.note.present ? data.note.value : this.note,
      receiptNumber: data.receiptNumber.present
          ? data.receiptNumber.value
          : this.receiptNumber,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
      voidReason:
          data.voidReason.present ? data.voidReason.value : this.voidReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientPayment(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('amount: $amount, ')
          ..write('paidAt: $paidAt, ')
          ..write('note: $note, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, orderId, amount, paidAt, note,
      receiptNumber, voidedAt, voidReason, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientPayment &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.amount == this.amount &&
          other.paidAt == this.paidAt &&
          other.note == this.note &&
          other.receiptNumber == this.receiptNumber &&
          other.voidedAt == this.voidedAt &&
          other.voidReason == this.voidReason &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ClientPaymentsCompanion extends UpdateCompanion<ClientPayment> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<int> amount;
  final Value<DateTime> paidAt;
  final Value<String> note;
  final Value<int> receiptNumber;
  final Value<DateTime?> voidedAt;
  final Value<String?> voidReason;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ClientPaymentsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.amount = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.note = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientPaymentsCompanion.insert({
    required String id,
    required String orderId,
    required int amount,
    required DateTime paidAt,
    this.note = const Value.absent(),
    required int receiptNumber,
    this.voidedAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orderId = Value(orderId),
        amount = Value(amount),
        paidAt = Value(paidAt),
        receiptNumber = Value(receiptNumber),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ClientPayment> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<int>? amount,
    Expression<int>? paidAt,
    Expression<String>? note,
    Expression<int>? receiptNumber,
    Expression<int>? voidedAt,
    Expression<String>? voidReason,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (amount != null) 'amount': amount,
      if (paidAt != null) 'paid_at': paidAt,
      if (note != null) 'note': note,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (voidReason != null) 'void_reason': voidReason,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientPaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? orderId,
      Value<int>? amount,
      Value<DateTime>? paidAt,
      Value<String>? note,
      Value<int>? receiptNumber,
      Value<DateTime?>? voidedAt,
      Value<String?>? voidReason,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return ClientPaymentsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      voidedAt: voidedAt ?? this.voidedAt,
      voidReason: voidReason ?? this.voidReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<int>(
          $ClientPaymentsTable.$converterpaidAt.toSql(paidAt.value));
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (receiptNumber.present) {
      map['receipt_number'] = Variable<int>(receiptNumber.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<int>(
          $ClientPaymentsTable.$convertervoidedAt.toSql(voidedAt.value));
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $ClientPaymentsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $ClientPaymentsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
          $ClientPaymentsTable.$converterdeletedAt.toSql(deletedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('amount: $amount, ')
          ..write('paidAt: $paidAt, ')
          ..write('note: $note, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApprenticesTable extends Apprentices
    with TableInfo<$ApprenticesTable, Apprentice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApprenticesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startDate =
      GeneratedColumn<int>('start_date', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ApprenticesTable.$converterstartDate);
  static const VerificationMeta _totalFeeMeta =
      const VerificationMeta('totalFee');
  @override
  late final GeneratedColumn<int> totalFee = GeneratedColumn<int>(
      'total_fee', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> nextDue =
      GeneratedColumn<int>('next_due', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($ApprenticesTable.$converternextDue);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ApprenticesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ApprenticesTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>('deleted_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($ApprenticesTable.$converterdeletedAt);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phone,
        startDate,
        totalFee,
        nextDue,
        notes,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'apprentices';
  @override
  VerificationContext validateIntegrity(Insertable<Apprentice> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('total_fee')) {
      context.handle(_totalFeeMeta,
          totalFee.isAcceptableOrUnknown(data['total_fee']!, _totalFeeMeta));
    } else if (isInserting) {
      context.missing(_totalFeeMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Apprentice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Apprentice(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      startDate: $ApprenticesTable.$converterstartDate.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_date'])!),
      totalFee: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_fee'])!,
      nextDue: $ApprenticesTable.$converternextDue.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_due'])),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdAt: $ApprenticesTable.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updatedAt: $ApprenticesTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
      deletedAt: $ApprenticesTable.$converterdeletedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at'])),
    );
  }

  @override
  $ApprenticesTable createAlias(String alias) {
    return $ApprenticesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterstartDate =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converternextDue =
      const NullableDateTimeConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAt =
      const NullableDateTimeConverter();
}

class Apprentice extends DataClass implements Insertable<Apprentice> {
  final String id;
  final String name;
  final String phone;
  final DateTime startDate;
  final int totalFee;
  final DateTime? nextDue;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Apprentice(
      {required this.id,
      required this.name,
      required this.phone,
      required this.startDate,
      required this.totalFee,
      this.nextDue,
      required this.notes,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    {
      map['start_date'] =
          Variable<int>($ApprenticesTable.$converterstartDate.toSql(startDate));
    }
    map['total_fee'] = Variable<int>(totalFee);
    if (!nullToAbsent || nextDue != null) {
      map['next_due'] =
          Variable<int>($ApprenticesTable.$converternextDue.toSql(nextDue));
    }
    map['notes'] = Variable<String>(notes);
    {
      map['created_at'] =
          Variable<int>($ApprenticesTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] =
          Variable<int>($ApprenticesTable.$converterupdatedAt.toSql(updatedAt));
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] =
          Variable<int>($ApprenticesTable.$converterdeletedAt.toSql(deletedAt));
    }
    return map;
  }

  ApprenticesCompanion toCompanion(bool nullToAbsent) {
    return ApprenticesCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      startDate: Value(startDate),
      totalFee: Value(totalFee),
      nextDue: nextDue == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDue),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Apprentice.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Apprentice(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      totalFee: serializer.fromJson<int>(json['totalFee']),
      nextDue: serializer.fromJson<DateTime?>(json['nextDue']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'startDate': serializer.toJson<DateTime>(startDate),
      'totalFee': serializer.toJson<int>(totalFee),
      'nextDue': serializer.toJson<DateTime?>(nextDue),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Apprentice copyWith(
          {String? id,
          String? name,
          String? phone,
          DateTime? startDate,
          int? totalFee,
          Value<DateTime?> nextDue = const Value.absent(),
          String? notes,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Apprentice(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        startDate: startDate ?? this.startDate,
        totalFee: totalFee ?? this.totalFee,
        nextDue: nextDue.present ? nextDue.value : this.nextDue,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Apprentice copyWithCompanion(ApprenticesCompanion data) {
    return Apprentice(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      totalFee: data.totalFee.present ? data.totalFee.value : this.totalFee,
      nextDue: data.nextDue.present ? data.nextDue.value : this.nextDue,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Apprentice(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('startDate: $startDate, ')
          ..write('totalFee: $totalFee, ')
          ..write('nextDue: $nextDue, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, startDate, totalFee, nextDue,
      notes, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Apprentice &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.startDate == this.startDate &&
          other.totalFee == this.totalFee &&
          other.nextDue == this.nextDue &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ApprenticesCompanion extends UpdateCompanion<Apprentice> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<DateTime> startDate;
  final Value<int> totalFee;
  final Value<DateTime?> nextDue;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ApprenticesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.startDate = const Value.absent(),
    this.totalFee = const Value.absent(),
    this.nextDue = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApprenticesCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    required DateTime startDate,
    required int totalFee,
    this.nextDue = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        startDate = Value(startDate),
        totalFee = Value(totalFee),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Apprentice> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<int>? startDate,
    Expression<int>? totalFee,
    Expression<int>? nextDue,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (startDate != null) 'start_date': startDate,
      if (totalFee != null) 'total_fee': totalFee,
      if (nextDue != null) 'next_due': nextDue,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApprenticesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? phone,
      Value<DateTime>? startDate,
      Value<int>? totalFee,
      Value<DateTime?>? nextDue,
      Value<String>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return ApprenticesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      startDate: startDate ?? this.startDate,
      totalFee: totalFee ?? this.totalFee,
      nextDue: nextDue ?? this.nextDue,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(
          $ApprenticesTable.$converterstartDate.toSql(startDate.value));
    }
    if (totalFee.present) {
      map['total_fee'] = Variable<int>(totalFee.value);
    }
    if (nextDue.present) {
      map['next_due'] = Variable<int>(
          $ApprenticesTable.$converternextDue.toSql(nextDue.value));
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $ApprenticesTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $ApprenticesTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
          $ApprenticesTable.$converterdeletedAt.toSql(deletedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApprenticesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('startDate: $startDate, ')
          ..write('totalFee: $totalFee, ')
          ..write('nextDue: $nextDue, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApprenticePaymentsTable extends ApprenticePayments
    with TableInfo<$ApprenticePaymentsTable, ApprenticePayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApprenticePaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _apprenticeIdMeta =
      const VerificationMeta('apprenticeId');
  @override
  late final GeneratedColumn<String> apprenticeId = GeneratedColumn<String>(
      'apprentice_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES apprentices (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> paidAt =
      GeneratedColumn<int>('paid_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ApprenticePaymentsTable.$converterpaidAt);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _receiptNumberMeta =
      const VerificationMeta('receiptNumber');
  @override
  late final GeneratedColumn<int> receiptNumber = GeneratedColumn<int>(
      'receipt_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> voidedAt =
      GeneratedColumn<int>('voided_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>(
              $ApprenticePaymentsTable.$convertervoidedAt);
  static const VerificationMeta _voidReasonMeta =
      const VerificationMeta('voidReason');
  @override
  late final GeneratedColumn<String> voidReason = GeneratedColumn<String>(
      'void_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>(
              $ApprenticePaymentsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>(
              $ApprenticePaymentsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>('deleted_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>(
              $ApprenticePaymentsTable.$converterdeletedAt);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        apprenticeId,
        amount,
        paidAt,
        note,
        receiptNumber,
        voidedAt,
        voidReason,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'apprentice_payments';
  @override
  VerificationContext validateIntegrity(Insertable<ApprenticePayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('apprentice_id')) {
      context.handle(
          _apprenticeIdMeta,
          apprenticeId.isAcceptableOrUnknown(
              data['apprentice_id']!, _apprenticeIdMeta));
    } else if (isInserting) {
      context.missing(_apprenticeIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('receipt_number')) {
      context.handle(
          _receiptNumberMeta,
          receiptNumber.isAcceptableOrUnknown(
              data['receipt_number']!, _receiptNumberMeta));
    } else if (isInserting) {
      context.missing(_receiptNumberMeta);
    }
    if (data.containsKey('void_reason')) {
      context.handle(
          _voidReasonMeta,
          voidReason.isAcceptableOrUnknown(
              data['void_reason']!, _voidReasonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApprenticePayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApprenticePayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      apprenticeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}apprentice_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      paidAt: $ApprenticePaymentsTable.$converterpaidAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}paid_at'])!),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      receiptNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}receipt_number'])!,
      voidedAt: $ApprenticePaymentsTable.$convertervoidedAt.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}voided_at'])),
      voidReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}void_reason']),
      createdAt: $ApprenticePaymentsTable.$convertercreatedAt.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updatedAt: $ApprenticePaymentsTable.$converterupdatedAt.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
      deletedAt: $ApprenticePaymentsTable.$converterdeletedAt.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}deleted_at'])),
    );
  }

  @override
  $ApprenticePaymentsTable createAlias(String alias) {
    return $ApprenticePaymentsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterpaidAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $convertervoidedAt =
      const NullableDateTimeConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAt =
      const NullableDateTimeConverter();
}

class ApprenticePayment extends DataClass
    implements Insertable<ApprenticePayment> {
  final String id;
  final String apprenticeId;
  final int amount;
  final DateTime paidAt;
  final String note;
  final int receiptNumber;
  final DateTime? voidedAt;
  final String? voidReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const ApprenticePayment(
      {required this.id,
      required this.apprenticeId,
      required this.amount,
      required this.paidAt,
      required this.note,
      required this.receiptNumber,
      this.voidedAt,
      this.voidReason,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['apprentice_id'] = Variable<String>(apprenticeId);
    map['amount'] = Variable<int>(amount);
    {
      map['paid_at'] = Variable<int>(
          $ApprenticePaymentsTable.$converterpaidAt.toSql(paidAt));
    }
    map['note'] = Variable<String>(note);
    map['receipt_number'] = Variable<int>(receiptNumber);
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<int>(
          $ApprenticePaymentsTable.$convertervoidedAt.toSql(voidedAt));
    }
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    {
      map['created_at'] = Variable<int>(
          $ApprenticePaymentsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(
          $ApprenticePaymentsTable.$converterupdatedAt.toSql(updatedAt));
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
          $ApprenticePaymentsTable.$converterdeletedAt.toSql(deletedAt));
    }
    return map;
  }

  ApprenticePaymentsCompanion toCompanion(bool nullToAbsent) {
    return ApprenticePaymentsCompanion(
      id: Value(id),
      apprenticeId: Value(apprenticeId),
      amount: Value(amount),
      paidAt: Value(paidAt),
      note: Value(note),
      receiptNumber: Value(receiptNumber),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ApprenticePayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApprenticePayment(
      id: serializer.fromJson<String>(json['id']),
      apprenticeId: serializer.fromJson<String>(json['apprenticeId']),
      amount: serializer.fromJson<int>(json['amount']),
      paidAt: serializer.fromJson<DateTime>(json['paidAt']),
      note: serializer.fromJson<String>(json['note']),
      receiptNumber: serializer.fromJson<int>(json['receiptNumber']),
      voidedAt: serializer.fromJson<DateTime?>(json['voidedAt']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'apprenticeId': serializer.toJson<String>(apprenticeId),
      'amount': serializer.toJson<int>(amount),
      'paidAt': serializer.toJson<DateTime>(paidAt),
      'note': serializer.toJson<String>(note),
      'receiptNumber': serializer.toJson<int>(receiptNumber),
      'voidedAt': serializer.toJson<DateTime?>(voidedAt),
      'voidReason': serializer.toJson<String?>(voidReason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ApprenticePayment copyWith(
          {String? id,
          String? apprenticeId,
          int? amount,
          DateTime? paidAt,
          String? note,
          int? receiptNumber,
          Value<DateTime?> voidedAt = const Value.absent(),
          Value<String?> voidReason = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      ApprenticePayment(
        id: id ?? this.id,
        apprenticeId: apprenticeId ?? this.apprenticeId,
        amount: amount ?? this.amount,
        paidAt: paidAt ?? this.paidAt,
        note: note ?? this.note,
        receiptNumber: receiptNumber ?? this.receiptNumber,
        voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
        voidReason: voidReason.present ? voidReason.value : this.voidReason,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  ApprenticePayment copyWithCompanion(ApprenticePaymentsCompanion data) {
    return ApprenticePayment(
      id: data.id.present ? data.id.value : this.id,
      apprenticeId: data.apprenticeId.present
          ? data.apprenticeId.value
          : this.apprenticeId,
      amount: data.amount.present ? data.amount.value : this.amount,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      note: data.note.present ? data.note.value : this.note,
      receiptNumber: data.receiptNumber.present
          ? data.receiptNumber.value
          : this.receiptNumber,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
      voidReason:
          data.voidReason.present ? data.voidReason.value : this.voidReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApprenticePayment(')
          ..write('id: $id, ')
          ..write('apprenticeId: $apprenticeId, ')
          ..write('amount: $amount, ')
          ..write('paidAt: $paidAt, ')
          ..write('note: $note, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, apprenticeId, amount, paidAt, note,
      receiptNumber, voidedAt, voidReason, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApprenticePayment &&
          other.id == this.id &&
          other.apprenticeId == this.apprenticeId &&
          other.amount == this.amount &&
          other.paidAt == this.paidAt &&
          other.note == this.note &&
          other.receiptNumber == this.receiptNumber &&
          other.voidedAt == this.voidedAt &&
          other.voidReason == this.voidReason &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ApprenticePaymentsCompanion extends UpdateCompanion<ApprenticePayment> {
  final Value<String> id;
  final Value<String> apprenticeId;
  final Value<int> amount;
  final Value<DateTime> paidAt;
  final Value<String> note;
  final Value<int> receiptNumber;
  final Value<DateTime?> voidedAt;
  final Value<String?> voidReason;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ApprenticePaymentsCompanion({
    this.id = const Value.absent(),
    this.apprenticeId = const Value.absent(),
    this.amount = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.note = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApprenticePaymentsCompanion.insert({
    required String id,
    required String apprenticeId,
    required int amount,
    required DateTime paidAt,
    this.note = const Value.absent(),
    required int receiptNumber,
    this.voidedAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        apprenticeId = Value(apprenticeId),
        amount = Value(amount),
        paidAt = Value(paidAt),
        receiptNumber = Value(receiptNumber),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ApprenticePayment> custom({
    Expression<String>? id,
    Expression<String>? apprenticeId,
    Expression<int>? amount,
    Expression<int>? paidAt,
    Expression<String>? note,
    Expression<int>? receiptNumber,
    Expression<int>? voidedAt,
    Expression<String>? voidReason,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (apprenticeId != null) 'apprentice_id': apprenticeId,
      if (amount != null) 'amount': amount,
      if (paidAt != null) 'paid_at': paidAt,
      if (note != null) 'note': note,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (voidReason != null) 'void_reason': voidReason,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApprenticePaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? apprenticeId,
      Value<int>? amount,
      Value<DateTime>? paidAt,
      Value<String>? note,
      Value<int>? receiptNumber,
      Value<DateTime?>? voidedAt,
      Value<String?>? voidReason,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return ApprenticePaymentsCompanion(
      id: id ?? this.id,
      apprenticeId: apprenticeId ?? this.apprenticeId,
      amount: amount ?? this.amount,
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      voidedAt: voidedAt ?? this.voidedAt,
      voidReason: voidReason ?? this.voidReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (apprenticeId.present) {
      map['apprentice_id'] = Variable<String>(apprenticeId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<int>(
          $ApprenticePaymentsTable.$converterpaidAt.toSql(paidAt.value));
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (receiptNumber.present) {
      map['receipt_number'] = Variable<int>(receiptNumber.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<int>(
          $ApprenticePaymentsTable.$convertervoidedAt.toSql(voidedAt.value));
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $ApprenticePaymentsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $ApprenticePaymentsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
          $ApprenticePaymentsTable.$converterdeletedAt.toSql(deletedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApprenticePaymentsCompanion(')
          ..write('id: $id, ')
          ..write('apprenticeId: $apprenticeId, ')
          ..write('amount: $amount, ')
          ..write('paidAt: $paidAt, ')
          ..write('note: $note, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RealisationsTable extends Realisations
    with TableInfo<$RealisationsTable, Realisation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RealisationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Autre'));
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
      'client_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES clients (id)'));
  static const VerificationMeta _captionMeta =
      const VerificationMeta('caption');
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
      'caption', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photoHashMeta =
      const VerificationMeta('photoHash');
  @override
  late final GeneratedColumn<String> photoHash = GeneratedColumn<String>(
      'photo_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoUploadStateMeta =
      const VerificationMeta('photoUploadState');
  @override
  late final GeneratedColumn<String> photoUploadState = GeneratedColumn<String>(
      'photo_upload_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($RealisationsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($RealisationsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>('deleted_at', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DateTime?>($RealisationsTable.$converterdeletedAt);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        category,
        clientId,
        caption,
        photoPath,
        photoHash,
        photoUploadState,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'realisations';
  @override
  VerificationContext validateIntegrity(Insertable<Realisation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    }
    if (data.containsKey('caption')) {
      context.handle(_captionMeta,
          caption.isAcceptableOrUnknown(data['caption']!, _captionMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    } else if (isInserting) {
      context.missing(_photoPathMeta);
    }
    if (data.containsKey('photo_hash')) {
      context.handle(_photoHashMeta,
          photoHash.isAcceptableOrUnknown(data['photo_hash']!, _photoHashMeta));
    }
    if (data.containsKey('photo_upload_state')) {
      context.handle(
          _photoUploadStateMeta,
          photoUploadState.isAcceptableOrUnknown(
              data['photo_upload_state']!, _photoUploadStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Realisation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Realisation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_id']),
      caption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caption'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path'])!,
      photoHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_hash']),
      photoUploadState: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}photo_upload_state'])!,
      createdAt: $RealisationsTable.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updatedAt: $RealisationsTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
      deletedAt: $RealisationsTable.$converterdeletedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at'])),
    );
  }

  @override
  $RealisationsTable createAlias(String alias) {
    return $RealisationsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAt =
      const NullableDateTimeConverter();
}

class Realisation extends DataClass implements Insertable<Realisation> {
  final String id;
  final String category;
  final String? clientId;
  final String caption;
  final String photoPath;
  final String? photoHash;
  final String photoUploadState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Realisation(
      {required this.id,
      required this.category,
      this.clientId,
      required this.caption,
      required this.photoPath,
      this.photoHash,
      required this.photoUploadState,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['caption'] = Variable<String>(caption);
    map['photo_path'] = Variable<String>(photoPath);
    if (!nullToAbsent || photoHash != null) {
      map['photo_hash'] = Variable<String>(photoHash);
    }
    map['photo_upload_state'] = Variable<String>(photoUploadState);
    {
      map['created_at'] = Variable<int>(
          $RealisationsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>(
          $RealisationsTable.$converterupdatedAt.toSql(updatedAt));
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
          $RealisationsTable.$converterdeletedAt.toSql(deletedAt));
    }
    return map;
  }

  RealisationsCompanion toCompanion(bool nullToAbsent) {
    return RealisationsCompanion(
      id: Value(id),
      category: Value(category),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      caption: Value(caption),
      photoPath: Value(photoPath),
      photoHash: photoHash == null && nullToAbsent
          ? const Value.absent()
          : Value(photoHash),
      photoUploadState: Value(photoUploadState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Realisation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Realisation(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      caption: serializer.fromJson<String>(json['caption']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      photoHash: serializer.fromJson<String?>(json['photoHash']),
      photoUploadState: serializer.fromJson<String>(json['photoUploadState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'clientId': serializer.toJson<String?>(clientId),
      'caption': serializer.toJson<String>(caption),
      'photoPath': serializer.toJson<String>(photoPath),
      'photoHash': serializer.toJson<String?>(photoHash),
      'photoUploadState': serializer.toJson<String>(photoUploadState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Realisation copyWith(
          {String? id,
          String? category,
          Value<String?> clientId = const Value.absent(),
          String? caption,
          String? photoPath,
          Value<String?> photoHash = const Value.absent(),
          String? photoUploadState,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Realisation(
        id: id ?? this.id,
        category: category ?? this.category,
        clientId: clientId.present ? clientId.value : this.clientId,
        caption: caption ?? this.caption,
        photoPath: photoPath ?? this.photoPath,
        photoHash: photoHash.present ? photoHash.value : this.photoHash,
        photoUploadState: photoUploadState ?? this.photoUploadState,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Realisation copyWithCompanion(RealisationsCompanion data) {
    return Realisation(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      caption: data.caption.present ? data.caption.value : this.caption,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoHash: data.photoHash.present ? data.photoHash.value : this.photoHash,
      photoUploadState: data.photoUploadState.present
          ? data.photoUploadState.value
          : this.photoUploadState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Realisation(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('clientId: $clientId, ')
          ..write('caption: $caption, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoHash: $photoHash, ')
          ..write('photoUploadState: $photoUploadState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, category, clientId, caption, photoPath,
      photoHash, photoUploadState, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Realisation &&
          other.id == this.id &&
          other.category == this.category &&
          other.clientId == this.clientId &&
          other.caption == this.caption &&
          other.photoPath == this.photoPath &&
          other.photoHash == this.photoHash &&
          other.photoUploadState == this.photoUploadState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class RealisationsCompanion extends UpdateCompanion<Realisation> {
  final Value<String> id;
  final Value<String> category;
  final Value<String?> clientId;
  final Value<String> caption;
  final Value<String> photoPath;
  final Value<String?> photoHash;
  final Value<String> photoUploadState;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const RealisationsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.clientId = const Value.absent(),
    this.caption = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoHash = const Value.absent(),
    this.photoUploadState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RealisationsCompanion.insert({
    required String id,
    this.category = const Value.absent(),
    this.clientId = const Value.absent(),
    this.caption = const Value.absent(),
    required String photoPath,
    this.photoHash = const Value.absent(),
    this.photoUploadState = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        photoPath = Value(photoPath),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Realisation> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? clientId,
    Expression<String>? caption,
    Expression<String>? photoPath,
    Expression<String>? photoHash,
    Expression<String>? photoUploadState,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (clientId != null) 'client_id': clientId,
      if (caption != null) 'caption': caption,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoHash != null) 'photo_hash': photoHash,
      if (photoUploadState != null) 'photo_upload_state': photoUploadState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RealisationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? category,
      Value<String?>? clientId,
      Value<String>? caption,
      Value<String>? photoPath,
      Value<String?>? photoHash,
      Value<String>? photoUploadState,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return RealisationsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      clientId: clientId ?? this.clientId,
      caption: caption ?? this.caption,
      photoPath: photoPath ?? this.photoPath,
      photoHash: photoHash ?? this.photoHash,
      photoUploadState: photoUploadState ?? this.photoUploadState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoHash.present) {
      map['photo_hash'] = Variable<String>(photoHash.value);
    }
    if (photoUploadState.present) {
      map['photo_upload_state'] = Variable<String>(photoUploadState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $RealisationsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $RealisationsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
          $RealisationsTable.$converterdeletedAt.toSql(deletedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RealisationsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('clientId: $clientId, ')
          ..write('caption: $caption, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoHash: $photoHash, ')
          ..write('photoUploadState: $photoUploadState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($SettingsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($SettingsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, key, value, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      createdAt: $SettingsTable.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      updatedAt: $SettingsTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
}

class Setting extends DataClass implements Insertable<Setting> {
  final String id;
  final String key;
  final String value;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Setting(
      {required this.id,
      required this.key,
      required this.value,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    {
      map['created_at'] =
          Variable<int>($SettingsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] =
          Variable<int>($SettingsTable.$converterupdatedAt.toSql(updatedAt));
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<String>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Setting copyWith(
          {String? id,
          String? key,
          String? value,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Setting(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> id;
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String id,
    required String key,
    required String value,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        key = Value(key),
        value = Value(value),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<String>? id,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? key,
      Value<String>? value,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $SettingsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $SettingsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptCountersTable extends ReceiptCounters
    with TableInfo<$ReceiptCountersTable, ReceiptCounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptCountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _counterNameMeta =
      const VerificationMeta('counterName');
  @override
  late final GeneratedColumn<String> counterName = GeneratedColumn<String>(
      'counter_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastValueMeta =
      const VerificationMeta('lastValue');
  @override
  late final GeneratedColumn<int> lastValue = GeneratedColumn<int>(
      'last_value', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($ReceiptCountersTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [counterName, lastValue, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_counters';
  @override
  VerificationContext validateIntegrity(Insertable<ReceiptCounter> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('counter_name')) {
      context.handle(
          _counterNameMeta,
          counterName.isAcceptableOrUnknown(
              data['counter_name']!, _counterNameMeta));
    } else if (isInserting) {
      context.missing(_counterNameMeta);
    }
    if (data.containsKey('last_value')) {
      context.handle(_lastValueMeta,
          lastValue.isAcceptableOrUnknown(data['last_value']!, _lastValueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {counterName};
  @override
  ReceiptCounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptCounter(
      counterName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}counter_name'])!,
      lastValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_value'])!,
      updatedAt: $ReceiptCountersTable.$converterupdatedAt.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
    );
  }

  @override
  $ReceiptCountersTable createAlias(String alias) {
    return $ReceiptCountersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
}

class ReceiptCounter extends DataClass implements Insertable<ReceiptCounter> {
  final String counterName;
  final int lastValue;
  final DateTime updatedAt;
  const ReceiptCounter(
      {required this.counterName,
      required this.lastValue,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['counter_name'] = Variable<String>(counterName);
    map['last_value'] = Variable<int>(lastValue);
    {
      map['updated_at'] = Variable<int>(
          $ReceiptCountersTable.$converterupdatedAt.toSql(updatedAt));
    }
    return map;
  }

  ReceiptCountersCompanion toCompanion(bool nullToAbsent) {
    return ReceiptCountersCompanion(
      counterName: Value(counterName),
      lastValue: Value(lastValue),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReceiptCounter.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptCounter(
      counterName: serializer.fromJson<String>(json['counterName']),
      lastValue: serializer.fromJson<int>(json['lastValue']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'counterName': serializer.toJson<String>(counterName),
      'lastValue': serializer.toJson<int>(lastValue),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReceiptCounter copyWith(
          {String? counterName, int? lastValue, DateTime? updatedAt}) =>
      ReceiptCounter(
        counterName: counterName ?? this.counterName,
        lastValue: lastValue ?? this.lastValue,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ReceiptCounter copyWithCompanion(ReceiptCountersCompanion data) {
    return ReceiptCounter(
      counterName:
          data.counterName.present ? data.counterName.value : this.counterName,
      lastValue: data.lastValue.present ? data.lastValue.value : this.lastValue,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptCounter(')
          ..write('counterName: $counterName, ')
          ..write('lastValue: $lastValue, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(counterName, lastValue, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptCounter &&
          other.counterName == this.counterName &&
          other.lastValue == this.lastValue &&
          other.updatedAt == this.updatedAt);
}

class ReceiptCountersCompanion extends UpdateCompanion<ReceiptCounter> {
  final Value<String> counterName;
  final Value<int> lastValue;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReceiptCountersCompanion({
    this.counterName = const Value.absent(),
    this.lastValue = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptCountersCompanion.insert({
    required String counterName,
    this.lastValue = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : counterName = Value(counterName),
        updatedAt = Value(updatedAt);
  static Insertable<ReceiptCounter> custom({
    Expression<String>? counterName,
    Expression<int>? lastValue,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (counterName != null) 'counter_name': counterName,
      if (lastValue != null) 'last_value': lastValue,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptCountersCompanion copyWith(
      {Value<String>? counterName,
      Value<int>? lastValue,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ReceiptCountersCompanion(
      counterName: counterName ?? this.counterName,
      lastValue: lastValue ?? this.lastValue,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (counterName.present) {
      map['counter_name'] = Variable<String>(counterName.value);
    }
    if (lastValue.present) {
      map['last_value'] = Variable<int>(lastValue.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $ReceiptCountersTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptCountersCompanion(')
          ..write('counterName: $counterName, ')
          ..write('lastValue: $lastValue, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
      'op', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>('created_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($SyncOutboxTable.$convertercreatedAt);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entity, entityId, op, createdAt, attempts, lastError];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(Insertable<SyncOutboxData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      op: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op'])!,
      createdAt: $SyncOutboxTable.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!),
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final String id;
  final String entity;
  final String entityId;
  final String op;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  const SyncOutboxData(
      {required this.id,
      required this.entity,
      required this.entityId,
      required this.op,
      required this.createdAt,
      required this.attempts,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['op'] = Variable<String>(op);
    {
      map['created_at'] =
          Variable<int>($SyncOutboxTable.$convertercreatedAt.toSql(createdAt));
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      id: Value(id),
      entity: Value(entity),
      entityId: Value(entityId),
      op: Value(op),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOutboxData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      id: serializer.fromJson<String>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      op: serializer.fromJson<String>(json['op']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'op': serializer.toJson<String>(op),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOutboxData copyWith(
          {String? id,
          String? entity,
          String? entityId,
          String? op,
          DateTime? createdAt,
          int? attempts,
          Value<String?> lastError = const Value.absent()}) =>
      SyncOutboxData(
        id: id ?? this.id,
        entity: entity ?? this.entity,
        entityId: entityId ?? this.entityId,
        op: op ?? this.op,
        createdAt: createdAt ?? this.createdAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      op: data.op.present ? data.op.value : this.op,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entity, entityId, op, createdAt, attempts, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.op == this.op &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<String> id;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> op;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncOutboxCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.op = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    required String id,
    required String entity,
    required String entityId,
    required String op,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        entity = Value(entity),
        entityId = Value(entityId),
        op = Value(op),
        createdAt = Value(createdAt);
  static Insertable<SyncOutboxData> custom({
    Expression<String>? id,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? op,
    Expression<int>? createdAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (op != null) 'op': op,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxCompanion copyWith(
      {Value<String>? id,
      Value<String>? entity,
      Value<String>? entityId,
      Value<String>? op,
      Value<DateTime>? createdAt,
      Value<int>? attempts,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return SyncOutboxCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
          $SyncOutboxTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>('updated_at', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DateTime>($SyncStateTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: $SyncStateTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const SyncStateData(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    {
      map['updated_at'] =
          Variable<int>($SyncStateTable.$converterupdatedAt.toSql(updatedAt));
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncStateData copyWith({String? key, String? value, DateTime? updatedAt}) =>
      SyncStateData(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<SyncStateData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
          $SyncStateTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClientsTable clients = $ClientsTable(this);
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final $ModelesTable modeles = $ModelesTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderPhotosTable orderPhotos = $OrderPhotosTable(this);
  late final $ClientPaymentsTable clientPayments = $ClientPaymentsTable(this);
  late final $ApprenticesTable apprentices = $ApprenticesTable(this);
  late final $ApprenticePaymentsTable apprenticePayments =
      $ApprenticePaymentsTable(this);
  late final $RealisationsTable realisations = $RealisationsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ReceiptCountersTable receiptCounters =
      $ReceiptCountersTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final Index idxClientsDeletedAt = Index('idx_clients_deleted_at',
      'CREATE INDEX idx_clients_deleted_at ON clients (deleted_at)');
  late final Index idxClientsUpdatedAt = Index('idx_clients_updated_at',
      'CREATE INDEX idx_clients_updated_at ON clients (updated_at)');
  late final Index idxClientsName = Index(
      'idx_clients_name', 'CREATE INDEX idx_clients_name ON clients (name)');
  late final Index idxMeasurementsClientId = Index('idx_measurements_client_id',
      'CREATE INDEX idx_measurements_client_id ON measurements (client_id)');
  late final Index idxMeasurementsTakenAt = Index('idx_measurements_taken_at',
      'CREATE INDEX idx_measurements_taken_at ON measurements (taken_at)');
  late final Index idxMeasurementsDeletedAt = Index(
      'idx_measurements_deleted_at',
      'CREATE INDEX idx_measurements_deleted_at ON measurements (deleted_at)');
  late final Index idxMeasurementsUpdatedAt = Index(
      'idx_measurements_updated_at',
      'CREATE INDEX idx_measurements_updated_at ON measurements (updated_at)');
  late final Index idxModelesDeletedAt = Index('idx_modeles_deleted_at',
      'CREATE INDEX idx_modeles_deleted_at ON modeles (deleted_at)');
  late final Index idxModelesUpdatedAt = Index('idx_modeles_updated_at',
      'CREATE INDEX idx_modeles_updated_at ON modeles (updated_at)');
  late final Index idxModelesName = Index(
      'idx_modeles_name', 'CREATE INDEX idx_modeles_name ON modeles (name)');
  late final Index idxOrdersClientId = Index('idx_orders_client_id',
      'CREATE INDEX idx_orders_client_id ON orders (client_id)');
  late final Index idxOrdersModeleId = Index('idx_orders_modele_id',
      'CREATE INDEX idx_orders_modele_id ON orders (modele_id)');
  late final Index idxOrdersDeliveryDate = Index('idx_orders_delivery_date',
      'CREATE INDEX idx_orders_delivery_date ON orders (delivery_date)');
  late final Index idxOrdersStatus = Index(
      'idx_orders_status', 'CREATE INDEX idx_orders_status ON orders (status)');
  late final Index idxOrdersDeletedAt = Index('idx_orders_deleted_at',
      'CREATE INDEX idx_orders_deleted_at ON orders (deleted_at)');
  late final Index idxOrdersUpdatedAt = Index('idx_orders_updated_at',
      'CREATE INDEX idx_orders_updated_at ON orders (updated_at)');
  late final Index idxOrderPhotosOrderId = Index('idx_order_photos_order_id',
      'CREATE INDEX idx_order_photos_order_id ON order_photos (order_id)');
  late final Index idxOrderPhotosUpdatedAt = Index(
      'idx_order_photos_updated_at',
      'CREATE INDEX idx_order_photos_updated_at ON order_photos (updated_at)');
  late final Index idxOrderPhotosDeletedAt = Index(
      'idx_order_photos_deleted_at',
      'CREATE INDEX idx_order_photos_deleted_at ON order_photos (deleted_at)');
  late final Index idxClientPaymentsOrderId = Index(
      'idx_client_payments_order_id',
      'CREATE INDEX idx_client_payments_order_id ON client_payments (order_id)');
  late final Index idxClientPaymentsReceiptNumber = Index(
      'idx_client_payments_receipt_number',
      'CREATE UNIQUE INDEX idx_client_payments_receipt_number ON client_payments (receipt_number)');
  late final Index idxClientPaymentsPaidAt = Index(
      'idx_client_payments_paid_at',
      'CREATE INDEX idx_client_payments_paid_at ON client_payments (paid_at)');
  late final Index idxClientPaymentsVoidedAt = Index(
      'idx_client_payments_voided_at',
      'CREATE INDEX idx_client_payments_voided_at ON client_payments (voided_at)');
  late final Index idxClientPaymentsDeletedAt = Index(
      'idx_client_payments_deleted_at',
      'CREATE INDEX idx_client_payments_deleted_at ON client_payments (deleted_at)');
  late final Index idxClientPaymentsUpdatedAt = Index(
      'idx_client_payments_updated_at',
      'CREATE INDEX idx_client_payments_updated_at ON client_payments (updated_at)');
  late final Index idxApprenticesName = Index('idx_apprentices_name',
      'CREATE INDEX idx_apprentices_name ON apprentices (name)');
  late final Index idxApprenticesNextDue = Index('idx_apprentices_next_due',
      'CREATE INDEX idx_apprentices_next_due ON apprentices (next_due)');
  late final Index idxApprenticesDeletedAt = Index('idx_apprentices_deleted_at',
      'CREATE INDEX idx_apprentices_deleted_at ON apprentices (deleted_at)');
  late final Index idxApprenticesUpdatedAt = Index('idx_apprentices_updated_at',
      'CREATE INDEX idx_apprentices_updated_at ON apprentices (updated_at)');
  late final Index idxApprenticePaymentsApprenticeId = Index(
      'idx_apprentice_payments_apprentice_id',
      'CREATE INDEX idx_apprentice_payments_apprentice_id ON apprentice_payments (apprentice_id)');
  late final Index idxApprenticePaymentsReceiptNumber = Index(
      'idx_apprentice_payments_receipt_number',
      'CREATE UNIQUE INDEX idx_apprentice_payments_receipt_number ON apprentice_payments (receipt_number)');
  late final Index idxApprenticePaymentsPaidAt = Index(
      'idx_apprentice_payments_paid_at',
      'CREATE INDEX idx_apprentice_payments_paid_at ON apprentice_payments (paid_at)');
  late final Index idxApprenticePaymentsVoidedAt = Index(
      'idx_apprentice_payments_voided_at',
      'CREATE INDEX idx_apprentice_payments_voided_at ON apprentice_payments (voided_at)');
  late final Index idxApprenticePaymentsDeletedAt = Index(
      'idx_apprentice_payments_deleted_at',
      'CREATE INDEX idx_apprentice_payments_deleted_at ON apprentice_payments (deleted_at)');
  late final Index idxApprenticePaymentsUpdatedAt = Index(
      'idx_apprentice_payments_updated_at',
      'CREATE INDEX idx_apprentice_payments_updated_at ON apprentice_payments (updated_at)');
  late final Index idxRealisationsCategory = Index('idx_realisations_category',
      'CREATE INDEX idx_realisations_category ON realisations (category)');
  late final Index idxRealisationsClientId = Index('idx_realisations_client_id',
      'CREATE INDEX idx_realisations_client_id ON realisations (client_id)');
  late final Index idxRealisationsDeletedAt = Index(
      'idx_realisations_deleted_at',
      'CREATE INDEX idx_realisations_deleted_at ON realisations (deleted_at)');
  late final Index idxRealisationsUpdatedAt = Index(
      'idx_realisations_updated_at',
      'CREATE INDEX idx_realisations_updated_at ON realisations (updated_at)');
  late final Index idxSettingsKey = Index('idx_settings_key',
      'CREATE UNIQUE INDEX idx_settings_key ON settings ("key")');
  late final Index idxSettingsUpdatedAt = Index('idx_settings_updated_at',
      'CREATE INDEX idx_settings_updated_at ON settings (updated_at)');
  late final Index idxSyncOutboxCreatedAt = Index('idx_sync_outbox_created_at',
      'CREATE INDEX idx_sync_outbox_created_at ON sync_outbox (created_at)');
  late final Index idxSyncOutboxEntityRow = Index('idx_sync_outbox_entity_row',
      'CREATE INDEX idx_sync_outbox_entity_row ON sync_outbox (entity, entity_id)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        clients,
        measurements,
        modeles,
        orders,
        orderPhotos,
        clientPayments,
        apprentices,
        apprenticePayments,
        realisations,
        settings,
        receiptCounters,
        syncOutbox,
        syncState,
        idxClientsDeletedAt,
        idxClientsUpdatedAt,
        idxClientsName,
        idxMeasurementsClientId,
        idxMeasurementsTakenAt,
        idxMeasurementsDeletedAt,
        idxMeasurementsUpdatedAt,
        idxModelesDeletedAt,
        idxModelesUpdatedAt,
        idxModelesName,
        idxOrdersClientId,
        idxOrdersModeleId,
        idxOrdersDeliveryDate,
        idxOrdersStatus,
        idxOrdersDeletedAt,
        idxOrdersUpdatedAt,
        idxOrderPhotosOrderId,
        idxOrderPhotosUpdatedAt,
        idxOrderPhotosDeletedAt,
        idxClientPaymentsOrderId,
        idxClientPaymentsReceiptNumber,
        idxClientPaymentsPaidAt,
        idxClientPaymentsVoidedAt,
        idxClientPaymentsDeletedAt,
        idxClientPaymentsUpdatedAt,
        idxApprenticesName,
        idxApprenticesNextDue,
        idxApprenticesDeletedAt,
        idxApprenticesUpdatedAt,
        idxApprenticePaymentsApprenticeId,
        idxApprenticePaymentsReceiptNumber,
        idxApprenticePaymentsPaidAt,
        idxApprenticePaymentsVoidedAt,
        idxApprenticePaymentsDeletedAt,
        idxApprenticePaymentsUpdatedAt,
        idxRealisationsCategory,
        idxRealisationsClientId,
        idxRealisationsDeletedAt,
        idxRealisationsUpdatedAt,
        idxSettingsKey,
        idxSettingsUpdatedAt,
        idxSyncOutboxCreatedAt,
        idxSyncOutboxEntityRow
      ];
}

typedef $$ClientsTableCreateCompanionBuilder = ClientsCompanion Function({
  required String id,
  required String name,
  Value<String> phone,
  Value<String> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$ClientsTableUpdateCompanionBuilder = ClientsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> phone,
  Value<String> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$ClientsTableReferences
    extends BaseReferences<_$AppDatabase, $ClientsTable, Client> {
  $$ClientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MeasurementsTable, List<Measurement>>
      _measurementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.measurements,
              aliasName: 'clients__id__measurements__client_id');

  $$MeasurementsTableProcessedTableManager get measurementsRefs {
    final manager = $$MeasurementsTableTableManager($_db, $_db.measurements)
        .filter((f) => f.clientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_measurementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$OrdersTable, List<Order>> _ordersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.orders,
          aliasName: 'clients__id__orders__client_id');

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.clientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RealisationsTable, List<Realisation>>
      _realisationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.realisations,
              aliasName: 'clients__id__realisations__client_id');

  $$RealisationsTableProcessedTableManager get realisationsRefs {
    final manager = $$RealisationsTableTableManager($_db, $_db.realisations)
        .filter((f) => f.clientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_realisationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ClientsTableFilterComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
          column: $table.deletedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  Expression<bool> measurementsRefs(
      Expression<bool> Function($$MeasurementsTableFilterComposer f) f) {
    final $$MeasurementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.measurements,
        getReferencedColumn: (t) => t.clientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeasurementsTableFilterComposer(
              $db: $db,
              $table: $db.measurements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ordersRefs(
      Expression<bool> Function($$OrdersTableFilterComposer f) f) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.clientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> realisationsRefs(
      Expression<bool> Function($$RealisationsTableFilterComposer f) f) {
    final $$RealisationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.realisations,
        getReferencedColumn: (t) => t.clientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RealisationsTableFilterComposer(
              $db: $db,
              $table: $db.realisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ClientsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$ClientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> measurementsRefs<T extends Object>(
      Expression<T> Function($$MeasurementsTableAnnotationComposer a) f) {
    final $$MeasurementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.measurements,
        getReferencedColumn: (t) => t.clientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeasurementsTableAnnotationComposer(
              $db: $db,
              $table: $db.measurements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ordersRefs<T extends Object>(
      Expression<T> Function($$OrdersTableAnnotationComposer a) f) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.clientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> realisationsRefs<T extends Object>(
      Expression<T> Function($$RealisationsTableAnnotationComposer a) f) {
    final $$RealisationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.realisations,
        getReferencedColumn: (t) => t.clientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RealisationsTableAnnotationComposer(
              $db: $db,
              $table: $db.realisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ClientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClientsTable,
    Client,
    $$ClientsTableFilterComposer,
    $$ClientsTableOrderingComposer,
    $$ClientsTableAnnotationComposer,
    $$ClientsTableCreateCompanionBuilder,
    $$ClientsTableUpdateCompanionBuilder,
    (Client, $$ClientsTableReferences),
    Client,
    PrefetchHooks Function(
        {bool measurementsRefs, bool ordersRefs, bool realisationsRefs})> {
  $$ClientsTableTableManager(_$AppDatabase db, $ClientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClientsCompanion(
            id: id,
            name: name,
            phone: phone,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> phone = const Value.absent(),
            Value<String> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClientsCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ClientsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {measurementsRefs = false,
              ordersRefs = false,
              realisationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (measurementsRefs) db.measurements,
                if (ordersRefs) db.orders,
                if (realisationsRefs) db.realisations
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (measurementsRefs)
                    await $_getPrefetchedData<Client, $ClientsTable,
                            Measurement>(
                        currentTable: table,
                        referencedTable:
                            $$ClientsTableReferences._measurementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClientsTableReferences(db, table, p0)
                                .measurementsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.clientId == item.id),
                        typedResults: items),
                  if (ordersRefs)
                    await $_getPrefetchedData<Client, $ClientsTable, Order>(
                        currentTable: table,
                        referencedTable:
                            $$ClientsTableReferences._ordersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClientsTableReferences(db, table, p0).ordersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.clientId == item.id),
                        typedResults: items),
                  if (realisationsRefs)
                    await $_getPrefetchedData<Client, $ClientsTable,
                            Realisation>(
                        currentTable: table,
                        referencedTable:
                            $$ClientsTableReferences._realisationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClientsTableReferences(db, table, p0)
                                .realisationsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.clientId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ClientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClientsTable,
    Client,
    $$ClientsTableFilterComposer,
    $$ClientsTableOrderingComposer,
    $$ClientsTableAnnotationComposer,
    $$ClientsTableCreateCompanionBuilder,
    $$ClientsTableUpdateCompanionBuilder,
    (Client, $$ClientsTableReferences),
    Client,
    PrefetchHooks Function(
        {bool measurementsRefs, bool ordersRefs, bool realisationsRefs})>;
typedef $$MeasurementsTableCreateCompanionBuilder = MeasurementsCompanion
    Function({
  required String id,
  required String clientId,
  required DateTime takenAt,
  required Map<String, double> measures,
  Value<String> note,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$MeasurementsTableUpdateCompanionBuilder = MeasurementsCompanion
    Function({
  Value<String> id,
  Value<String> clientId,
  Value<DateTime> takenAt,
  Value<Map<String, double>> measures,
  Value<String> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$MeasurementsTableReferences
    extends BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement> {
  $$MeasurementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClientsTable _clientIdTable(_$AppDatabase db) =>
      db.clients.createAlias('measurements__client_id__clients__id');

  $$ClientsTableProcessedTableManager get clientId {
    final $_column = $_itemColumn<String>('client_id')!;

    final manager = $$ClientsTableTableManager($_db, $_db.clients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get takenAt =>
      $composableBuilder(
          column: $table.takenAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Map<String, double>, Map<String, double>,
          String>
      get measures => $composableBuilder(
          column: $table.measures,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
          column: $table.deletedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$ClientsTableFilterComposer get clientId {
    final $$ClientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableFilterComposer(
              $db: $db,
              $table: $db.clients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get measures => $composableBuilder(
      column: $table.measures, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$ClientsTableOrderingComposer get clientId {
    final $$ClientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableOrderingComposer(
              $db: $db,
              $table: $db.clients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, double>, String> get measures =>
      $composableBuilder(column: $table.measures, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ClientsTableAnnotationComposer get clientId {
    final $$ClientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableAnnotationComposer(
              $db: $db,
              $table: $db.clients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MeasurementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    Measurement,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableAnnotationComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder,
    (Measurement, $$MeasurementsTableReferences),
    Measurement,
    PrefetchHooks Function({bool clientId})> {
  $$MeasurementsTableTableManager(_$AppDatabase db, $MeasurementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> clientId = const Value.absent(),
            Value<DateTime> takenAt = const Value.absent(),
            Value<Map<String, double>> measures = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeasurementsCompanion(
            id: id,
            clientId: clientId,
            takenAt: takenAt,
            measures: measures,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String clientId,
            required DateTime takenAt,
            required Map<String, double> measures,
            Value<String> note = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeasurementsCompanion.insert(
            id: id,
            clientId: clientId,
            takenAt: takenAt,
            measures: measures,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MeasurementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({clientId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (clientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.clientId,
                    referencedTable:
                        $$MeasurementsTableReferences._clientIdTable(db),
                    referencedColumn:
                        $$MeasurementsTableReferences._clientIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MeasurementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    Measurement,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableAnnotationComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder,
    (Measurement, $$MeasurementsTableReferences),
    Measurement,
    PrefetchHooks Function({bool clientId})>;
typedef $$ModelesTableCreateCompanionBuilder = ModelesCompanion Function({
  required String id,
  required String name,
  Value<String> description,
  Value<String?> photoPath,
  Value<String?> photoHash,
  Value<String> photoUploadState,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$ModelesTableUpdateCompanionBuilder = ModelesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> description,
  Value<String?> photoPath,
  Value<String?> photoHash,
  Value<String> photoUploadState,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$ModelesTableReferences
    extends BaseReferences<_$AppDatabase, $ModelesTable, Modele> {
  $$ModelesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrdersTable, List<Order>> _ordersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.orders,
          aliasName: 'modeles__id__orders__modele_id');

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.modeleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ModelesTableFilterComposer
    extends Composer<_$AppDatabase, $ModelesTable> {
  $$ModelesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoHash => $composableBuilder(
      column: $table.photoHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
          column: $table.deletedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  Expression<bool> ordersRefs(
      Expression<bool> Function($$OrdersTableFilterComposer f) f) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.modeleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ModelesTableOrderingComposer
    extends Composer<_$AppDatabase, $ModelesTable> {
  $$ModelesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoHash => $composableBuilder(
      column: $table.photoHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$ModelesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModelesTable> {
  $$ModelesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get photoHash =>
      $composableBuilder(column: $table.photoHash, builder: (column) => column);

  GeneratedColumn<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> ordersRefs<T extends Object>(
      Expression<T> Function($$OrdersTableAnnotationComposer a) f) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.modeleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ModelesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ModelesTable,
    Modele,
    $$ModelesTableFilterComposer,
    $$ModelesTableOrderingComposer,
    $$ModelesTableAnnotationComposer,
    $$ModelesTableCreateCompanionBuilder,
    $$ModelesTableUpdateCompanionBuilder,
    (Modele, $$ModelesTableReferences),
    Modele,
    PrefetchHooks Function({bool ordersRefs})> {
  $$ModelesTableTableManager(_$AppDatabase db, $ModelesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String?> photoHash = const Value.absent(),
            Value<String> photoUploadState = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ModelesCompanion(
            id: id,
            name: name,
            description: description,
            photoPath: photoPath,
            photoHash: photoHash,
            photoUploadState: photoUploadState,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> description = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String?> photoHash = const Value.absent(),
            Value<String> photoUploadState = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ModelesCompanion.insert(
            id: id,
            name: name,
            description: description,
            photoPath: photoPath,
            photoHash: photoHash,
            photoUploadState: photoUploadState,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ModelesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({ordersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ordersRefs) db.orders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ordersRefs)
                    await $_getPrefetchedData<Modele, $ModelesTable, Order>(
                        currentTable: table,
                        referencedTable:
                            $$ModelesTableReferences._ordersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ModelesTableReferences(db, table, p0).ordersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.modeleId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ModelesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ModelesTable,
    Modele,
    $$ModelesTableFilterComposer,
    $$ModelesTableOrderingComposer,
    $$ModelesTableAnnotationComposer,
    $$ModelesTableCreateCompanionBuilder,
    $$ModelesTableUpdateCompanionBuilder,
    (Modele, $$ModelesTableReferences),
    Modele,
    PrefetchHooks Function({bool ordersRefs})>;
typedef $$OrdersTableCreateCompanionBuilder = OrdersCompanion Function({
  required String id,
  required String clientId,
  Value<String?> modeleId,
  required String title,
  Value<String> fabric,
  required int price,
  required DateTime deliveryDate,
  Value<DateTime?> fittingDate,
  Value<String> status,
  Value<String?> photoPath,
  Value<String?> photoHash,
  Value<String> photoUploadState,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$OrdersTableUpdateCompanionBuilder = OrdersCompanion Function({
  Value<String> id,
  Value<String> clientId,
  Value<String?> modeleId,
  Value<String> title,
  Value<String> fabric,
  Value<int> price,
  Value<DateTime> deliveryDate,
  Value<DateTime?> fittingDate,
  Value<String> status,
  Value<String?> photoPath,
  Value<String?> photoHash,
  Value<String> photoUploadState,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$OrdersTableReferences
    extends BaseReferences<_$AppDatabase, $OrdersTable, Order> {
  $$OrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClientsTable _clientIdTable(_$AppDatabase db) =>
      db.clients.createAlias('orders__client_id__clients__id');

  $$ClientsTableProcessedTableManager get clientId {
    final $_column = $_itemColumn<String>('client_id')!;

    final manager = $$ClientsTableTableManager($_db, $_db.clients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ModelesTable _modeleIdTable(_$AppDatabase db) =>
      db.modeles.createAlias('orders__modele_id__modeles__id');

  $$ModelesTableProcessedTableManager? get modeleId {
    final $_column = $_itemColumn<String>('modele_id');
    if ($_column == null) return null;
    final manager = $$ModelesTableTableManager($_db, $_db.modeles)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_modeleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$OrderPhotosTable, List<OrderPhoto>>
      _orderPhotosRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.orderPhotos,
              aliasName: 'orders__id__order_photos__order_id');

  $$OrderPhotosTableProcessedTableManager get orderPhotosRefs {
    final manager = $$OrderPhotosTableTableManager($_db, $_db.orderPhotos)
        .filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderPhotosRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ClientPaymentsTable, List<ClientPayment>>
      _clientPaymentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.clientPayments,
              aliasName: 'orders__id__client_payments__order_id');

  $$ClientPaymentsTableProcessedTableManager get clientPaymentsRefs {
    final manager = $$ClientPaymentsTableTableManager($_db, $_db.clientPayments)
        .filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_clientPaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fabric => $composableBuilder(
      column: $table.fabric, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get deliveryDate =>
      $composableBuilder(
          column: $table.deliveryDate,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get fittingDate =>
      $composableBuilder(
          column: $table.fittingDate,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoHash => $composableBuilder(
      column: $table.photoHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
          column: $table.deletedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$ClientsTableFilterComposer get clientId {
    final $$ClientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableFilterComposer(
              $db: $db,
              $table: $db.clients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ModelesTableFilterComposer get modeleId {
    final $$ModelesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.modeleId,
        referencedTable: $db.modeles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ModelesTableFilterComposer(
              $db: $db,
              $table: $db.modeles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> orderPhotosRefs(
      Expression<bool> Function($$OrderPhotosTableFilterComposer f) f) {
    final $$OrderPhotosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orderPhotos,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderPhotosTableFilterComposer(
              $db: $db,
              $table: $db.orderPhotos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> clientPaymentsRefs(
      Expression<bool> Function($$ClientPaymentsTableFilterComposer f) f) {
    final $$ClientPaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.clientPayments,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientPaymentsTableFilterComposer(
              $db: $db,
              $table: $db.clientPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fabric => $composableBuilder(
      column: $table.fabric, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deliveryDate => $composableBuilder(
      column: $table.deliveryDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fittingDate => $composableBuilder(
      column: $table.fittingDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoHash => $composableBuilder(
      column: $table.photoHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$ClientsTableOrderingComposer get clientId {
    final $$ClientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableOrderingComposer(
              $db: $db,
              $table: $db.clients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ModelesTableOrderingComposer get modeleId {
    final $$ModelesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.modeleId,
        referencedTable: $db.modeles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ModelesTableOrderingComposer(
              $db: $db,
              $table: $db.modeles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get fabric =>
      $composableBuilder(column: $table.fabric, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get deliveryDate =>
      $composableBuilder(
          column: $table.deliveryDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get fittingDate =>
      $composableBuilder(
          column: $table.fittingDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get photoHash =>
      $composableBuilder(column: $table.photoHash, builder: (column) => column);

  GeneratedColumn<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ClientsTableAnnotationComposer get clientId {
    final $$ClientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableAnnotationComposer(
              $db: $db,
              $table: $db.clients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ModelesTableAnnotationComposer get modeleId {
    final $$ModelesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.modeleId,
        referencedTable: $db.modeles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ModelesTableAnnotationComposer(
              $db: $db,
              $table: $db.modeles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> orderPhotosRefs<T extends Object>(
      Expression<T> Function($$OrderPhotosTableAnnotationComposer a) f) {
    final $$OrderPhotosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orderPhotos,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderPhotosTableAnnotationComposer(
              $db: $db,
              $table: $db.orderPhotos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> clientPaymentsRefs<T extends Object>(
      Expression<T> Function($$ClientPaymentsTableAnnotationComposer a) f) {
    final $$ClientPaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.clientPayments,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientPaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.clientPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrdersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, $$OrdersTableReferences),
    Order,
    PrefetchHooks Function(
        {bool clientId,
        bool modeleId,
        bool orderPhotosRefs,
        bool clientPaymentsRefs})> {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> clientId = const Value.absent(),
            Value<String?> modeleId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> fabric = const Value.absent(),
            Value<int> price = const Value.absent(),
            Value<DateTime> deliveryDate = const Value.absent(),
            Value<DateTime?> fittingDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String?> photoHash = const Value.absent(),
            Value<String> photoUploadState = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrdersCompanion(
            id: id,
            clientId: clientId,
            modeleId: modeleId,
            title: title,
            fabric: fabric,
            price: price,
            deliveryDate: deliveryDate,
            fittingDate: fittingDate,
            status: status,
            photoPath: photoPath,
            photoHash: photoHash,
            photoUploadState: photoUploadState,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String clientId,
            Value<String?> modeleId = const Value.absent(),
            required String title,
            Value<String> fabric = const Value.absent(),
            required int price,
            required DateTime deliveryDate,
            Value<DateTime?> fittingDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String?> photoHash = const Value.absent(),
            Value<String> photoUploadState = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrdersCompanion.insert(
            id: id,
            clientId: clientId,
            modeleId: modeleId,
            title: title,
            fabric: fabric,
            price: price,
            deliveryDate: deliveryDate,
            fittingDate: fittingDate,
            status: status,
            photoPath: photoPath,
            photoHash: photoHash,
            photoUploadState: photoUploadState,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$OrdersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {clientId = false,
              modeleId = false,
              orderPhotosRefs = false,
              clientPaymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (orderPhotosRefs) db.orderPhotos,
                if (clientPaymentsRefs) db.clientPayments
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (clientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.clientId,
                    referencedTable: $$OrdersTableReferences._clientIdTable(db),
                    referencedColumn:
                        $$OrdersTableReferences._clientIdTable(db).id,
                  ) as T;
                }
                if (modeleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.modeleId,
                    referencedTable: $$OrdersTableReferences._modeleIdTable(db),
                    referencedColumn:
                        $$OrdersTableReferences._modeleIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (orderPhotosRefs)
                    await $_getPrefetchedData<Order, $OrdersTable, OrderPhoto>(
                        currentTable: table,
                        referencedTable:
                            $$OrdersTableReferences._orderPhotosRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrdersTableReferences(db, table, p0)
                                .orderPhotosRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orderId == item.id),
                        typedResults: items),
                  if (clientPaymentsRefs)
                    await $_getPrefetchedData<Order, $OrdersTable,
                            ClientPayment>(
                        currentTable: table,
                        referencedTable: $$OrdersTableReferences
                            ._clientPaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrdersTableReferences(db, table, p0)
                                .clientPaymentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orderId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$OrdersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, $$OrdersTableReferences),
    Order,
    PrefetchHooks Function(
        {bool clientId,
        bool modeleId,
        bool orderPhotosRefs,
        bool clientPaymentsRefs})>;
typedef $$OrderPhotosTableCreateCompanionBuilder = OrderPhotosCompanion
    Function({
  required String id,
  required String orderId,
  required String photoPath,
  Value<String?> photoHash,
  Value<String> photoUploadState,
  Value<int> position,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$OrderPhotosTableUpdateCompanionBuilder = OrderPhotosCompanion
    Function({
  Value<String> id,
  Value<String> orderId,
  Value<String> photoPath,
  Value<String?> photoHash,
  Value<String> photoUploadState,
  Value<int> position,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$OrderPhotosTableReferences
    extends BaseReferences<_$AppDatabase, $OrderPhotosTable, OrderPhoto> {
  $$OrderPhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) =>
      db.orders.createAlias('order_photos__order_id__orders__id');

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<String>('order_id')!;

    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$OrderPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $OrderPhotosTable> {
  $$OrderPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoHash => $composableBuilder(
      column: $table.photoHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
          column: $table.deletedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrderPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderPhotosTable> {
  $$OrderPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoHash => $composableBuilder(
      column: $table.photoHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableOrderingComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrderPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderPhotosTable> {
  $$OrderPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get photoHash =>
      $composableBuilder(column: $table.photoHash, builder: (column) => column);

  GeneratedColumn<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrderPhotosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrderPhotosTable,
    OrderPhoto,
    $$OrderPhotosTableFilterComposer,
    $$OrderPhotosTableOrderingComposer,
    $$OrderPhotosTableAnnotationComposer,
    $$OrderPhotosTableCreateCompanionBuilder,
    $$OrderPhotosTableUpdateCompanionBuilder,
    (OrderPhoto, $$OrderPhotosTableReferences),
    OrderPhoto,
    PrefetchHooks Function({bool orderId})> {
  $$OrderPhotosTableTableManager(_$AppDatabase db, $OrderPhotosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<String> photoPath = const Value.absent(),
            Value<String?> photoHash = const Value.absent(),
            Value<String> photoUploadState = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrderPhotosCompanion(
            id: id,
            orderId: orderId,
            photoPath: photoPath,
            photoHash: photoHash,
            photoUploadState: photoUploadState,
            position: position,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orderId,
            required String photoPath,
            Value<String?> photoHash = const Value.absent(),
            Value<String> photoUploadState = const Value.absent(),
            Value<int> position = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrderPhotosCompanion.insert(
            id: id,
            orderId: orderId,
            photoPath: photoPath,
            photoHash: photoHash,
            photoUploadState: photoUploadState,
            position: position,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$OrderPhotosTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({orderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (orderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderId,
                    referencedTable:
                        $$OrderPhotosTableReferences._orderIdTable(db),
                    referencedColumn:
                        $$OrderPhotosTableReferences._orderIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$OrderPhotosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrderPhotosTable,
    OrderPhoto,
    $$OrderPhotosTableFilterComposer,
    $$OrderPhotosTableOrderingComposer,
    $$OrderPhotosTableAnnotationComposer,
    $$OrderPhotosTableCreateCompanionBuilder,
    $$OrderPhotosTableUpdateCompanionBuilder,
    (OrderPhoto, $$OrderPhotosTableReferences),
    OrderPhoto,
    PrefetchHooks Function({bool orderId})>;
typedef $$ClientPaymentsTableCreateCompanionBuilder = ClientPaymentsCompanion
    Function({
  required String id,
  required String orderId,
  required int amount,
  required DateTime paidAt,
  Value<String> note,
  required int receiptNumber,
  Value<DateTime?> voidedAt,
  Value<String?> voidReason,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$ClientPaymentsTableUpdateCompanionBuilder = ClientPaymentsCompanion
    Function({
  Value<String> id,
  Value<String> orderId,
  Value<int> amount,
  Value<DateTime> paidAt,
  Value<String> note,
  Value<int> receiptNumber,
  Value<DateTime?> voidedAt,
  Value<String?> voidReason,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$ClientPaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $ClientPaymentsTable, ClientPayment> {
  $$ClientPaymentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) =>
      db.orders.createAlias('client_payments__order_id__orders__id');

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<String>('order_id')!;

    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ClientPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $ClientPaymentsTable> {
  $$ClientPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get paidAt =>
      $composableBuilder(
          column: $table.paidAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get receiptNumber => $composableBuilder(
      column: $table.receiptNumber, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get voidedAt =>
      $composableBuilder(
          column: $table.voidedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get voidReason => $composableBuilder(
      column: $table.voidReason, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
          column: $table.deletedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ClientPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientPaymentsTable> {
  $$ClientPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get receiptNumber => $composableBuilder(
      column: $table.receiptNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get voidedAt => $composableBuilder(
      column: $table.voidedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get voidReason => $composableBuilder(
      column: $table.voidReason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableOrderingComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ClientPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientPaymentsTable> {
  $$ClientPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get receiptNumber => $composableBuilder(
      column: $table.receiptNumber, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
      column: $table.voidReason, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ClientPaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClientPaymentsTable,
    ClientPayment,
    $$ClientPaymentsTableFilterComposer,
    $$ClientPaymentsTableOrderingComposer,
    $$ClientPaymentsTableAnnotationComposer,
    $$ClientPaymentsTableCreateCompanionBuilder,
    $$ClientPaymentsTableUpdateCompanionBuilder,
    (ClientPayment, $$ClientPaymentsTableReferences),
    ClientPayment,
    PrefetchHooks Function({bool orderId})> {
  $$ClientPaymentsTableTableManager(
      _$AppDatabase db, $ClientPaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<DateTime> paidAt = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> receiptNumber = const Value.absent(),
            Value<DateTime?> voidedAt = const Value.absent(),
            Value<String?> voidReason = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClientPaymentsCompanion(
            id: id,
            orderId: orderId,
            amount: amount,
            paidAt: paidAt,
            note: note,
            receiptNumber: receiptNumber,
            voidedAt: voidedAt,
            voidReason: voidReason,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orderId,
            required int amount,
            required DateTime paidAt,
            Value<String> note = const Value.absent(),
            required int receiptNumber,
            Value<DateTime?> voidedAt = const Value.absent(),
            Value<String?> voidReason = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClientPaymentsCompanion.insert(
            id: id,
            orderId: orderId,
            amount: amount,
            paidAt: paidAt,
            note: note,
            receiptNumber: receiptNumber,
            voidedAt: voidedAt,
            voidReason: voidReason,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ClientPaymentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({orderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (orderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderId,
                    referencedTable:
                        $$ClientPaymentsTableReferences._orderIdTable(db),
                    referencedColumn:
                        $$ClientPaymentsTableReferences._orderIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ClientPaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClientPaymentsTable,
    ClientPayment,
    $$ClientPaymentsTableFilterComposer,
    $$ClientPaymentsTableOrderingComposer,
    $$ClientPaymentsTableAnnotationComposer,
    $$ClientPaymentsTableCreateCompanionBuilder,
    $$ClientPaymentsTableUpdateCompanionBuilder,
    (ClientPayment, $$ClientPaymentsTableReferences),
    ClientPayment,
    PrefetchHooks Function({bool orderId})>;
typedef $$ApprenticesTableCreateCompanionBuilder = ApprenticesCompanion
    Function({
  required String id,
  required String name,
  Value<String> phone,
  required DateTime startDate,
  required int totalFee,
  Value<DateTime?> nextDue,
  Value<String> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$ApprenticesTableUpdateCompanionBuilder = ApprenticesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> phone,
  Value<DateTime> startDate,
  Value<int> totalFee,
  Value<DateTime?> nextDue,
  Value<String> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$ApprenticesTableReferences
    extends BaseReferences<_$AppDatabase, $ApprenticesTable, Apprentice> {
  $$ApprenticesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ApprenticePaymentsTable, List<ApprenticePayment>>
      _apprenticePaymentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.apprenticePayments,
              aliasName: 'apprentices__id__apprentice_payments__apprentice_id');

  $$ApprenticePaymentsTableProcessedTableManager get apprenticePaymentsRefs {
    final manager = $$ApprenticePaymentsTableTableManager(
            $_db, $_db.apprenticePayments)
        .filter(
            (f) => f.apprenticeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_apprenticePaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ApprenticesTableFilterComposer
    extends Composer<_$AppDatabase, $ApprenticesTable> {
  $$ApprenticesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get startDate =>
      $composableBuilder(
          column: $table.startDate,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get totalFee => $composableBuilder(
      column: $table.totalFee, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get nextDue =>
      $composableBuilder(
          column: $table.nextDue,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
          column: $table.deletedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  Expression<bool> apprenticePaymentsRefs(
      Expression<bool> Function($$ApprenticePaymentsTableFilterComposer f) f) {
    final $$ApprenticePaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.apprenticePayments,
        getReferencedColumn: (t) => t.apprenticeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ApprenticePaymentsTableFilterComposer(
              $db: $db,
              $table: $db.apprenticePayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ApprenticesTableOrderingComposer
    extends Composer<_$AppDatabase, $ApprenticesTable> {
  $$ApprenticesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalFee => $composableBuilder(
      column: $table.totalFee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextDue => $composableBuilder(
      column: $table.nextDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$ApprenticesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApprenticesTable> {
  $$ApprenticesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get totalFee =>
      $composableBuilder(column: $table.totalFee, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get nextDue =>
      $composableBuilder(column: $table.nextDue, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> apprenticePaymentsRefs<T extends Object>(
      Expression<T> Function($$ApprenticePaymentsTableAnnotationComposer a) f) {
    final $$ApprenticePaymentsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.apprenticePayments,
            getReferencedColumn: (t) => t.apprenticeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ApprenticePaymentsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.apprenticePayments,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ApprenticesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ApprenticesTable,
    Apprentice,
    $$ApprenticesTableFilterComposer,
    $$ApprenticesTableOrderingComposer,
    $$ApprenticesTableAnnotationComposer,
    $$ApprenticesTableCreateCompanionBuilder,
    $$ApprenticesTableUpdateCompanionBuilder,
    (Apprentice, $$ApprenticesTableReferences),
    Apprentice,
    PrefetchHooks Function({bool apprenticePaymentsRefs})> {
  $$ApprenticesTableTableManager(_$AppDatabase db, $ApprenticesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApprenticesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApprenticesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApprenticesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<int> totalFee = const Value.absent(),
            Value<DateTime?> nextDue = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ApprenticesCompanion(
            id: id,
            name: name,
            phone: phone,
            startDate: startDate,
            totalFee: totalFee,
            nextDue: nextDue,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> phone = const Value.absent(),
            required DateTime startDate,
            required int totalFee,
            Value<DateTime?> nextDue = const Value.absent(),
            Value<String> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ApprenticesCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            startDate: startDate,
            totalFee: totalFee,
            nextDue: nextDue,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ApprenticesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({apprenticePaymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (apprenticePaymentsRefs) db.apprenticePayments
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (apprenticePaymentsRefs)
                    await $_getPrefetchedData<Apprentice, $ApprenticesTable,
                            ApprenticePayment>(
                        currentTable: table,
                        referencedTable: $$ApprenticesTableReferences
                            ._apprenticePaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ApprenticesTableReferences(db, table, p0)
                                .apprenticePaymentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.apprenticeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ApprenticesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ApprenticesTable,
    Apprentice,
    $$ApprenticesTableFilterComposer,
    $$ApprenticesTableOrderingComposer,
    $$ApprenticesTableAnnotationComposer,
    $$ApprenticesTableCreateCompanionBuilder,
    $$ApprenticesTableUpdateCompanionBuilder,
    (Apprentice, $$ApprenticesTableReferences),
    Apprentice,
    PrefetchHooks Function({bool apprenticePaymentsRefs})>;
typedef $$ApprenticePaymentsTableCreateCompanionBuilder
    = ApprenticePaymentsCompanion Function({
  required String id,
  required String apprenticeId,
  required int amount,
  required DateTime paidAt,
  Value<String> note,
  required int receiptNumber,
  Value<DateTime?> voidedAt,
  Value<String?> voidReason,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$ApprenticePaymentsTableUpdateCompanionBuilder
    = ApprenticePaymentsCompanion Function({
  Value<String> id,
  Value<String> apprenticeId,
  Value<int> amount,
  Value<DateTime> paidAt,
  Value<String> note,
  Value<int> receiptNumber,
  Value<DateTime?> voidedAt,
  Value<String?> voidReason,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$ApprenticePaymentsTableReferences extends BaseReferences<
    _$AppDatabase, $ApprenticePaymentsTable, ApprenticePayment> {
  $$ApprenticePaymentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ApprenticesTable _apprenticeIdTable(_$AppDatabase db) =>
      db.apprentices
          .createAlias('apprentice_payments__apprentice_id__apprentices__id');

  $$ApprenticesTableProcessedTableManager get apprenticeId {
    final $_column = $_itemColumn<String>('apprentice_id')!;

    final manager = $$ApprenticesTableTableManager($_db, $_db.apprentices)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_apprenticeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ApprenticePaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $ApprenticePaymentsTable> {
  $$ApprenticePaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get paidAt =>
      $composableBuilder(
          column: $table.paidAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get receiptNumber => $composableBuilder(
      column: $table.receiptNumber, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get voidedAt =>
      $composableBuilder(
          column: $table.voidedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get voidReason => $composableBuilder(
      column: $table.voidReason, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
          column: $table.deletedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$ApprenticesTableFilterComposer get apprenticeId {
    final $$ApprenticesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.apprenticeId,
        referencedTable: $db.apprentices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ApprenticesTableFilterComposer(
              $db: $db,
              $table: $db.apprentices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ApprenticePaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ApprenticePaymentsTable> {
  $$ApprenticePaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get receiptNumber => $composableBuilder(
      column: $table.receiptNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get voidedAt => $composableBuilder(
      column: $table.voidedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get voidReason => $composableBuilder(
      column: $table.voidReason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$ApprenticesTableOrderingComposer get apprenticeId {
    final $$ApprenticesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.apprenticeId,
        referencedTable: $db.apprentices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ApprenticesTableOrderingComposer(
              $db: $db,
              $table: $db.apprentices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ApprenticePaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApprenticePaymentsTable> {
  $$ApprenticePaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get receiptNumber => $composableBuilder(
      column: $table.receiptNumber, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
      column: $table.voidReason, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ApprenticesTableAnnotationComposer get apprenticeId {
    final $$ApprenticesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.apprenticeId,
        referencedTable: $db.apprentices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ApprenticesTableAnnotationComposer(
              $db: $db,
              $table: $db.apprentices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ApprenticePaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ApprenticePaymentsTable,
    ApprenticePayment,
    $$ApprenticePaymentsTableFilterComposer,
    $$ApprenticePaymentsTableOrderingComposer,
    $$ApprenticePaymentsTableAnnotationComposer,
    $$ApprenticePaymentsTableCreateCompanionBuilder,
    $$ApprenticePaymentsTableUpdateCompanionBuilder,
    (ApprenticePayment, $$ApprenticePaymentsTableReferences),
    ApprenticePayment,
    PrefetchHooks Function({bool apprenticeId})> {
  $$ApprenticePaymentsTableTableManager(
      _$AppDatabase db, $ApprenticePaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApprenticePaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApprenticePaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApprenticePaymentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> apprenticeId = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<DateTime> paidAt = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> receiptNumber = const Value.absent(),
            Value<DateTime?> voidedAt = const Value.absent(),
            Value<String?> voidReason = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ApprenticePaymentsCompanion(
            id: id,
            apprenticeId: apprenticeId,
            amount: amount,
            paidAt: paidAt,
            note: note,
            receiptNumber: receiptNumber,
            voidedAt: voidedAt,
            voidReason: voidReason,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String apprenticeId,
            required int amount,
            required DateTime paidAt,
            Value<String> note = const Value.absent(),
            required int receiptNumber,
            Value<DateTime?> voidedAt = const Value.absent(),
            Value<String?> voidReason = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ApprenticePaymentsCompanion.insert(
            id: id,
            apprenticeId: apprenticeId,
            amount: amount,
            paidAt: paidAt,
            note: note,
            receiptNumber: receiptNumber,
            voidedAt: voidedAt,
            voidReason: voidReason,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ApprenticePaymentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({apprenticeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (apprenticeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.apprenticeId,
                    referencedTable: $$ApprenticePaymentsTableReferences
                        ._apprenticeIdTable(db),
                    referencedColumn: $$ApprenticePaymentsTableReferences
                        ._apprenticeIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ApprenticePaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ApprenticePaymentsTable,
    ApprenticePayment,
    $$ApprenticePaymentsTableFilterComposer,
    $$ApprenticePaymentsTableOrderingComposer,
    $$ApprenticePaymentsTableAnnotationComposer,
    $$ApprenticePaymentsTableCreateCompanionBuilder,
    $$ApprenticePaymentsTableUpdateCompanionBuilder,
    (ApprenticePayment, $$ApprenticePaymentsTableReferences),
    ApprenticePayment,
    PrefetchHooks Function({bool apprenticeId})>;
typedef $$RealisationsTableCreateCompanionBuilder = RealisationsCompanion
    Function({
  required String id,
  Value<String> category,
  Value<String?> clientId,
  Value<String> caption,
  required String photoPath,
  Value<String?> photoHash,
  Value<String> photoUploadState,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$RealisationsTableUpdateCompanionBuilder = RealisationsCompanion
    Function({
  Value<String> id,
  Value<String> category,
  Value<String?> clientId,
  Value<String> caption,
  Value<String> photoPath,
  Value<String?> photoHash,
  Value<String> photoUploadState,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$RealisationsTableReferences
    extends BaseReferences<_$AppDatabase, $RealisationsTable, Realisation> {
  $$RealisationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClientsTable _clientIdTable(_$AppDatabase db) =>
      db.clients.createAlias('realisations__client_id__clients__id');

  $$ClientsTableProcessedTableManager? get clientId {
    final $_column = $_itemColumn<String>('client_id');
    if ($_column == null) return null;
    final manager = $$ClientsTableTableManager($_db, $_db.clients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RealisationsTableFilterComposer
    extends Composer<_$AppDatabase, $RealisationsTable> {
  $$RealisationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoHash => $composableBuilder(
      column: $table.photoHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
          column: $table.deletedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$ClientsTableFilterComposer get clientId {
    final $$ClientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableFilterComposer(
              $db: $db,
              $table: $db.clients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RealisationsTableOrderingComposer
    extends Composer<_$AppDatabase, $RealisationsTable> {
  $$RealisationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoHash => $composableBuilder(
      column: $table.photoHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$ClientsTableOrderingComposer get clientId {
    final $$ClientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableOrderingComposer(
              $db: $db,
              $table: $db.clients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RealisationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RealisationsTable> {
  $$RealisationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get photoHash =>
      $composableBuilder(column: $table.photoHash, builder: (column) => column);

  GeneratedColumn<String> get photoUploadState => $composableBuilder(
      column: $table.photoUploadState, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ClientsTableAnnotationComposer get clientId {
    final $$ClientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableAnnotationComposer(
              $db: $db,
              $table: $db.clients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RealisationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RealisationsTable,
    Realisation,
    $$RealisationsTableFilterComposer,
    $$RealisationsTableOrderingComposer,
    $$RealisationsTableAnnotationComposer,
    $$RealisationsTableCreateCompanionBuilder,
    $$RealisationsTableUpdateCompanionBuilder,
    (Realisation, $$RealisationsTableReferences),
    Realisation,
    PrefetchHooks Function({bool clientId})> {
  $$RealisationsTableTableManager(_$AppDatabase db, $RealisationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RealisationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RealisationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RealisationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String?> clientId = const Value.absent(),
            Value<String> caption = const Value.absent(),
            Value<String> photoPath = const Value.absent(),
            Value<String?> photoHash = const Value.absent(),
            Value<String> photoUploadState = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RealisationsCompanion(
            id: id,
            category: category,
            clientId: clientId,
            caption: caption,
            photoPath: photoPath,
            photoHash: photoHash,
            photoUploadState: photoUploadState,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> category = const Value.absent(),
            Value<String?> clientId = const Value.absent(),
            Value<String> caption = const Value.absent(),
            required String photoPath,
            Value<String?> photoHash = const Value.absent(),
            Value<String> photoUploadState = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RealisationsCompanion.insert(
            id: id,
            category: category,
            clientId: clientId,
            caption: caption,
            photoPath: photoPath,
            photoHash: photoHash,
            photoUploadState: photoUploadState,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RealisationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({clientId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (clientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.clientId,
                    referencedTable:
                        $$RealisationsTableReferences._clientIdTable(db),
                    referencedColumn:
                        $$RealisationsTableReferences._clientIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RealisationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RealisationsTable,
    Realisation,
    $$RealisationsTableFilterComposer,
    $$RealisationsTableOrderingComposer,
    $$RealisationsTableAnnotationComposer,
    $$RealisationsTableCreateCompanionBuilder,
    $$RealisationsTableUpdateCompanionBuilder,
    (Realisation, $$RealisationsTableReferences),
    Realisation,
    PrefetchHooks Function({bool clientId})>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String id,
  required String key,
  required String value,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> id,
  Value<String> key,
  Value<String> value,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            id: id,
            key: key,
            value: value,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String key,
            required String value,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            id: id,
            key: key,
            value: value,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;
typedef $$ReceiptCountersTableCreateCompanionBuilder = ReceiptCountersCompanion
    Function({
  required String counterName,
  Value<int> lastValue,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ReceiptCountersTableUpdateCompanionBuilder = ReceiptCountersCompanion
    Function({
  Value<String> counterName,
  Value<int> lastValue,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ReceiptCountersTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptCountersTable> {
  $$ReceiptCountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get counterName => $composableBuilder(
      column: $table.counterName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastValue => $composableBuilder(
      column: $table.lastValue, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$ReceiptCountersTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptCountersTable> {
  $$ReceiptCountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get counterName => $composableBuilder(
      column: $table.counterName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastValue => $composableBuilder(
      column: $table.lastValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ReceiptCountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptCountersTable> {
  $$ReceiptCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get counterName => $composableBuilder(
      column: $table.counterName, builder: (column) => column);

  GeneratedColumn<int> get lastValue =>
      $composableBuilder(column: $table.lastValue, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReceiptCountersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReceiptCountersTable,
    ReceiptCounter,
    $$ReceiptCountersTableFilterComposer,
    $$ReceiptCountersTableOrderingComposer,
    $$ReceiptCountersTableAnnotationComposer,
    $$ReceiptCountersTableCreateCompanionBuilder,
    $$ReceiptCountersTableUpdateCompanionBuilder,
    (
      ReceiptCounter,
      BaseReferences<_$AppDatabase, $ReceiptCountersTable, ReceiptCounter>
    ),
    ReceiptCounter,
    PrefetchHooks Function()> {
  $$ReceiptCountersTableTableManager(
      _$AppDatabase db, $ReceiptCountersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptCountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptCountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> counterName = const Value.absent(),
            Value<int> lastValue = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceiptCountersCompanion(
            counterName: counterName,
            lastValue: lastValue,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String counterName,
            Value<int> lastValue = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceiptCountersCompanion.insert(
            counterName: counterName,
            lastValue: lastValue,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReceiptCountersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReceiptCountersTable,
    ReceiptCounter,
    $$ReceiptCountersTableFilterComposer,
    $$ReceiptCountersTableOrderingComposer,
    $$ReceiptCountersTableAnnotationComposer,
    $$ReceiptCountersTableCreateCompanionBuilder,
    $$ReceiptCountersTableUpdateCompanionBuilder,
    (
      ReceiptCounter,
      BaseReferences<_$AppDatabase, $ReceiptCountersTable, ReceiptCounter>
    ),
    ReceiptCounter,
    PrefetchHooks Function()>;
typedef $$SyncOutboxTableCreateCompanionBuilder = SyncOutboxCompanion Function({
  required String id,
  required String entity,
  required String entityId,
  required String op,
  required DateTime createdAt,
  Value<int> attempts,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SyncOutboxTableUpdateCompanionBuilder = SyncOutboxCompanion Function({
  Value<String> id,
  Value<String> entity,
  Value<String> entityId,
  Value<String> op,
  Value<DateTime> createdAt,
  Value<int> attempts,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOutboxTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncOutboxTable,
    SyncOutboxData,
    $$SyncOutboxTableFilterComposer,
    $$SyncOutboxTableOrderingComposer,
    $$SyncOutboxTableAnnotationComposer,
    $$SyncOutboxTableCreateCompanionBuilder,
    $$SyncOutboxTableUpdateCompanionBuilder,
    (
      SyncOutboxData,
      BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>
    ),
    SyncOutboxData,
    PrefetchHooks Function()> {
  $$SyncOutboxTableTableManager(_$AppDatabase db, $SyncOutboxTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> entity = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> op = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncOutboxCompanion(
            id: id,
            entity: entity,
            entityId: entityId,
            op: op,
            createdAt: createdAt,
            attempts: attempts,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String entity,
            required String entityId,
            required String op,
            required DateTime createdAt,
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncOutboxCompanion.insert(
            id: id,
            entity: entity,
            entityId: entityId,
            op: op,
            createdAt: createdAt,
            attempts: attempts,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncOutboxTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncOutboxTable,
    SyncOutboxData,
    $$SyncOutboxTableFilterComposer,
    $$SyncOutboxTableOrderingComposer,
    $$SyncOutboxTableAnnotationComposer,
    $$SyncOutboxTableCreateCompanionBuilder,
    $$SyncOutboxTableUpdateCompanionBuilder,
    (
      SyncOutboxData,
      BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>
    ),
    SyncOutboxData,
    PrefetchHooks Function()>;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String key,
  required String value,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()> {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClientsTableTableManager get clients =>
      $$ClientsTableTableManager(_db, _db.clients);
  $$MeasurementsTableTableManager get measurements =>
      $$MeasurementsTableTableManager(_db, _db.measurements);
  $$ModelesTableTableManager get modeles =>
      $$ModelesTableTableManager(_db, _db.modeles);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderPhotosTableTableManager get orderPhotos =>
      $$OrderPhotosTableTableManager(_db, _db.orderPhotos);
  $$ClientPaymentsTableTableManager get clientPayments =>
      $$ClientPaymentsTableTableManager(_db, _db.clientPayments);
  $$ApprenticesTableTableManager get apprentices =>
      $$ApprenticesTableTableManager(_db, _db.apprentices);
  $$ApprenticePaymentsTableTableManager get apprenticePayments =>
      $$ApprenticePaymentsTableTableManager(_db, _db.apprenticePayments);
  $$RealisationsTableTableManager get realisations =>
      $$RealisationsTableTableManager(_db, _db.realisations);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$ReceiptCountersTableTableManager get receiptCounters =>
      $$ReceiptCountersTableTableManager(_db, _db.receiptCounters);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
