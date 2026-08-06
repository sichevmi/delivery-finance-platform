// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PricingTableTable extends PricingTable
    with TableInfo<$PricingTableTable, PricingTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PricingTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _receivingFeeMeta =
      const VerificationMeta('receivingFee');
  @override
  late final GeneratedColumn<double> receivingFee = GeneratedColumn<double>(
      'receiving_fee', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _deliveryFeeMeta =
      const VerificationMeta('deliveryFee');
  @override
  late final GeneratedColumn<double> deliveryFee = GeneratedColumn<double>(
      'delivery_fee', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _pricePerKgMeta =
      const VerificationMeta('pricePerKg');
  @override
  late final GeneratedColumn<double> pricePerKg = GeneratedColumn<double>(
      'price_per_kg', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _pricePerKmMeta =
      const VerificationMeta('pricePerKm');
  @override
  late final GeneratedColumn<double> pricePerKm = GeneratedColumn<double>(
      'price_per_km', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _baseCoefficientMeta =
      const VerificationMeta('baseCoefficient');
  @override
  late final GeneratedColumn<double> baseCoefficient = GeneratedColumn<double>(
      'base_coefficient', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Стандартный'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        receivingFee,
        deliveryFee,
        pricePerKg,
        pricePerKm,
        baseCoefficient,
        name,
        isActive,
        isDefault,
        version,
        isSynced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pricing_table';
  @override
  VerificationContext validateIntegrity(Insertable<PricingTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('receiving_fee')) {
      context.handle(
          _receivingFeeMeta,
          receivingFee.isAcceptableOrUnknown(
              data['receiving_fee']!, _receivingFeeMeta));
    }
    if (data.containsKey('delivery_fee')) {
      context.handle(
          _deliveryFeeMeta,
          deliveryFee.isAcceptableOrUnknown(
              data['delivery_fee']!, _deliveryFeeMeta));
    }
    if (data.containsKey('price_per_kg')) {
      context.handle(
          _pricePerKgMeta,
          pricePerKg.isAcceptableOrUnknown(
              data['price_per_kg']!, _pricePerKgMeta));
    }
    if (data.containsKey('price_per_km')) {
      context.handle(
          _pricePerKmMeta,
          pricePerKm.isAcceptableOrUnknown(
              data['price_per_km']!, _pricePerKmMeta));
    }
    if (data.containsKey('base_coefficient')) {
      context.handle(
          _baseCoefficientMeta,
          baseCoefficient.isAcceptableOrUnknown(
              data['base_coefficient']!, _baseCoefficientMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PricingTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PricingTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      receivingFee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}receiving_fee'])!,
      deliveryFee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}delivery_fee'])!,
      pricePerKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_per_kg'])!,
      pricePerKm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_per_km'])!,
      baseCoefficient: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}base_coefficient'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $PricingTableTable createAlias(String alias) {
    return $PricingTableTable(attachedDatabase, alias);
  }
}

class PricingTableData extends DataClass
    implements Insertable<PricingTableData> {
  final int id;
  final int? serverId;
  final double receivingFee;
  final double deliveryFee;
  final double pricePerKg;
  final double pricePerKm;
  final double baseCoefficient;
  final String name;
  final bool isActive;
  final bool isDefault;
  final int version;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const PricingTableData(
      {required this.id,
      this.serverId,
      required this.receivingFee,
      required this.deliveryFee,
      required this.pricePerKg,
      required this.pricePerKm,
      required this.baseCoefficient,
      required this.name,
      required this.isActive,
      required this.isDefault,
      required this.version,
      required this.isSynced,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['receiving_fee'] = Variable<double>(receivingFee);
    map['delivery_fee'] = Variable<double>(deliveryFee);
    map['price_per_kg'] = Variable<double>(pricePerKg);
    map['price_per_km'] = Variable<double>(pricePerKm);
    map['base_coefficient'] = Variable<double>(baseCoefficient);
    map['name'] = Variable<String>(name);
    map['is_active'] = Variable<bool>(isActive);
    map['is_default'] = Variable<bool>(isDefault);
    map['version'] = Variable<int>(version);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  PricingTableCompanion toCompanion(bool nullToAbsent) {
    return PricingTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      receivingFee: Value(receivingFee),
      deliveryFee: Value(deliveryFee),
      pricePerKg: Value(pricePerKg),
      pricePerKm: Value(pricePerKm),
      baseCoefficient: Value(baseCoefficient),
      name: Value(name),
      isActive: Value(isActive),
      isDefault: Value(isDefault),
      version: Value(version),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory PricingTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PricingTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      receivingFee: serializer.fromJson<double>(json['receivingFee']),
      deliveryFee: serializer.fromJson<double>(json['deliveryFee']),
      pricePerKg: serializer.fromJson<double>(json['pricePerKg']),
      pricePerKm: serializer.fromJson<double>(json['pricePerKm']),
      baseCoefficient: serializer.fromJson<double>(json['baseCoefficient']),
      name: serializer.fromJson<String>(json['name']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      version: serializer.fromJson<int>(json['version']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'receivingFee': serializer.toJson<double>(receivingFee),
      'deliveryFee': serializer.toJson<double>(deliveryFee),
      'pricePerKg': serializer.toJson<double>(pricePerKg),
      'pricePerKm': serializer.toJson<double>(pricePerKm),
      'baseCoefficient': serializer.toJson<double>(baseCoefficient),
      'name': serializer.toJson<String>(name),
      'isActive': serializer.toJson<bool>(isActive),
      'isDefault': serializer.toJson<bool>(isDefault),
      'version': serializer.toJson<int>(version),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  PricingTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          double? receivingFee,
          double? deliveryFee,
          double? pricePerKg,
          double? pricePerKm,
          double? baseCoefficient,
          String? name,
          bool? isActive,
          bool? isDefault,
          int? version,
          bool? isSynced,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      PricingTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        receivingFee: receivingFee ?? this.receivingFee,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        pricePerKg: pricePerKg ?? this.pricePerKg,
        pricePerKm: pricePerKm ?? this.pricePerKm,
        baseCoefficient: baseCoefficient ?? this.baseCoefficient,
        name: name ?? this.name,
        isActive: isActive ?? this.isActive,
        isDefault: isDefault ?? this.isDefault,
        version: version ?? this.version,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  PricingTableData copyWithCompanion(PricingTableCompanion data) {
    return PricingTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      receivingFee: data.receivingFee.present
          ? data.receivingFee.value
          : this.receivingFee,
      deliveryFee:
          data.deliveryFee.present ? data.deliveryFee.value : this.deliveryFee,
      pricePerKg:
          data.pricePerKg.present ? data.pricePerKg.value : this.pricePerKg,
      pricePerKm:
          data.pricePerKm.present ? data.pricePerKm.value : this.pricePerKm,
      baseCoefficient: data.baseCoefficient.present
          ? data.baseCoefficient.value
          : this.baseCoefficient,
      name: data.name.present ? data.name.value : this.name,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      version: data.version.present ? data.version.value : this.version,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PricingTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('receivingFee: $receivingFee, ')
          ..write('deliveryFee: $deliveryFee, ')
          ..write('pricePerKg: $pricePerKg, ')
          ..write('pricePerKm: $pricePerKm, ')
          ..write('baseCoefficient: $baseCoefficient, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('isDefault: $isDefault, ')
          ..write('version: $version, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      receivingFee,
      deliveryFee,
      pricePerKg,
      pricePerKm,
      baseCoefficient,
      name,
      isActive,
      isDefault,
      version,
      isSynced,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PricingTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.receivingFee == this.receivingFee &&
          other.deliveryFee == this.deliveryFee &&
          other.pricePerKg == this.pricePerKg &&
          other.pricePerKm == this.pricePerKm &&
          other.baseCoefficient == this.baseCoefficient &&
          other.name == this.name &&
          other.isActive == this.isActive &&
          other.isDefault == this.isDefault &&
          other.version == this.version &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PricingTableCompanion extends UpdateCompanion<PricingTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<double> receivingFee;
  final Value<double> deliveryFee;
  final Value<double> pricePerKg;
  final Value<double> pricePerKm;
  final Value<double> baseCoefficient;
  final Value<String> name;
  final Value<bool> isActive;
  final Value<bool> isDefault;
  final Value<int> version;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const PricingTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.receivingFee = const Value.absent(),
    this.deliveryFee = const Value.absent(),
    this.pricePerKg = const Value.absent(),
    this.pricePerKm = const Value.absent(),
    this.baseCoefficient = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.version = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PricingTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.receivingFee = const Value.absent(),
    this.deliveryFee = const Value.absent(),
    this.pricePerKg = const Value.absent(),
    this.pricePerKm = const Value.absent(),
    this.baseCoefficient = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.version = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
  }) : createdAt = Value(createdAt);
  static Insertable<PricingTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<double>? receivingFee,
    Expression<double>? deliveryFee,
    Expression<double>? pricePerKg,
    Expression<double>? pricePerKm,
    Expression<double>? baseCoefficient,
    Expression<String>? name,
    Expression<bool>? isActive,
    Expression<bool>? isDefault,
    Expression<int>? version,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (receivingFee != null) 'receiving_fee': receivingFee,
      if (deliveryFee != null) 'delivery_fee': deliveryFee,
      if (pricePerKg != null) 'price_per_kg': pricePerKg,
      if (pricePerKm != null) 'price_per_km': pricePerKm,
      if (baseCoefficient != null) 'base_coefficient': baseCoefficient,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (isDefault != null) 'is_default': isDefault,
      if (version != null) 'version': version,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PricingTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<double>? receivingFee,
      Value<double>? deliveryFee,
      Value<double>? pricePerKg,
      Value<double>? pricePerKm,
      Value<double>? baseCoefficient,
      Value<String>? name,
      Value<bool>? isActive,
      Value<bool>? isDefault,
      Value<int>? version,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt}) {
    return PricingTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      receivingFee: receivingFee ?? this.receivingFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      baseCoefficient: baseCoefficient ?? this.baseCoefficient,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      version: version ?? this.version,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (receivingFee.present) {
      map['receiving_fee'] = Variable<double>(receivingFee.value);
    }
    if (deliveryFee.present) {
      map['delivery_fee'] = Variable<double>(deliveryFee.value);
    }
    if (pricePerKg.present) {
      map['price_per_kg'] = Variable<double>(pricePerKg.value);
    }
    if (pricePerKm.present) {
      map['price_per_km'] = Variable<double>(pricePerKm.value);
    }
    if (baseCoefficient.present) {
      map['base_coefficient'] = Variable<double>(baseCoefficient.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PricingTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('receivingFee: $receivingFee, ')
          ..write('deliveryFee: $deliveryFee, ')
          ..write('pricePerKg: $pricePerKg, ')
          ..write('pricePerKm: $pricePerKm, ')
          ..write('baseCoefficient: $baseCoefficient, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('isDefault: $isDefault, ')
          ..write('version: $version, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _fuelConsumptionMeta =
      const VerificationMeta('fuelConsumption');
  @override
  late final GeneratedColumn<double> fuelConsumption = GeneratedColumn<double>(
      'fuel_consumption', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(10.0));
  static const VerificationMeta _fuelPriceMeta =
      const VerificationMeta('fuelPrice');
  @override
  late final GeneratedColumn<double> fuelPrice = GeneratedColumn<double>(
      'fuel_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(50.0));
  static const VerificationMeta _repairCostMeta =
      const VerificationMeta('repairCost');
  @override
  late final GeneratedColumn<double> repairCost = GeneratedColumn<double>(
      'repair_cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(2.0));
  static const VerificationMeta _additionalCostsMeta =
      const VerificationMeta('additionalCosts');
  @override
  late final GeneratedColumn<double> additionalCosts = GeneratedColumn<double>(
      'additional_costs', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Стандартные'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        fuelConsumption,
        fuelPrice,
        repairCost,
        additionalCosts,
        name,
        isActive,
        isDefault,
        version,
        isSynced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_table';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('fuel_consumption')) {
      context.handle(
          _fuelConsumptionMeta,
          fuelConsumption.isAcceptableOrUnknown(
              data['fuel_consumption']!, _fuelConsumptionMeta));
    }
    if (data.containsKey('fuel_price')) {
      context.handle(_fuelPriceMeta,
          fuelPrice.isAcceptableOrUnknown(data['fuel_price']!, _fuelPriceMeta));
    }
    if (data.containsKey('repair_cost')) {
      context.handle(
          _repairCostMeta,
          repairCost.isAcceptableOrUnknown(
              data['repair_cost']!, _repairCostMeta));
    }
    if (data.containsKey('additional_costs')) {
      context.handle(
          _additionalCostsMeta,
          additionalCosts.isAcceptableOrUnknown(
              data['additional_costs']!, _additionalCostsMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      fuelConsumption: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}fuel_consumption'])!,
      fuelPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fuel_price'])!,
      repairCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}repair_cost'])!,
      additionalCosts: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}additional_costs'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsTableData extends DataClass
    implements Insertable<SettingsTableData> {
  final int id;
  final int? serverId;
  final double fuelConsumption;
  final double fuelPrice;
  final double repairCost;
  final double additionalCosts;
  final String name;
  final bool isActive;
  final bool isDefault;
  final int version;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const SettingsTableData(
      {required this.id,
      this.serverId,
      required this.fuelConsumption,
      required this.fuelPrice,
      required this.repairCost,
      required this.additionalCosts,
      required this.name,
      required this.isActive,
      required this.isDefault,
      required this.version,
      required this.isSynced,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['fuel_consumption'] = Variable<double>(fuelConsumption);
    map['fuel_price'] = Variable<double>(fuelPrice);
    map['repair_cost'] = Variable<double>(repairCost);
    map['additional_costs'] = Variable<double>(additionalCosts);
    map['name'] = Variable<String>(name);
    map['is_active'] = Variable<bool>(isActive);
    map['is_default'] = Variable<bool>(isDefault);
    map['version'] = Variable<int>(version);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      fuelConsumption: Value(fuelConsumption),
      fuelPrice: Value(fuelPrice),
      repairCost: Value(repairCost),
      additionalCosts: Value(additionalCosts),
      name: Value(name),
      isActive: Value(isActive),
      isDefault: Value(isDefault),
      version: Value(version),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SettingsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      fuelConsumption: serializer.fromJson<double>(json['fuelConsumption']),
      fuelPrice: serializer.fromJson<double>(json['fuelPrice']),
      repairCost: serializer.fromJson<double>(json['repairCost']),
      additionalCosts: serializer.fromJson<double>(json['additionalCosts']),
      name: serializer.fromJson<String>(json['name']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      version: serializer.fromJson<int>(json['version']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'fuelConsumption': serializer.toJson<double>(fuelConsumption),
      'fuelPrice': serializer.toJson<double>(fuelPrice),
      'repairCost': serializer.toJson<double>(repairCost),
      'additionalCosts': serializer.toJson<double>(additionalCosts),
      'name': serializer.toJson<String>(name),
      'isActive': serializer.toJson<bool>(isActive),
      'isDefault': serializer.toJson<bool>(isDefault),
      'version': serializer.toJson<int>(version),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  SettingsTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          double? fuelConsumption,
          double? fuelPrice,
          double? repairCost,
          double? additionalCosts,
          String? name,
          bool? isActive,
          bool? isDefault,
          int? version,
          bool? isSynced,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      SettingsTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        fuelConsumption: fuelConsumption ?? this.fuelConsumption,
        fuelPrice: fuelPrice ?? this.fuelPrice,
        repairCost: repairCost ?? this.repairCost,
        additionalCosts: additionalCosts ?? this.additionalCosts,
        name: name ?? this.name,
        isActive: isActive ?? this.isActive,
        isDefault: isDefault ?? this.isDefault,
        version: version ?? this.version,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  SettingsTableData copyWithCompanion(SettingsTableCompanion data) {
    return SettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      fuelConsumption: data.fuelConsumption.present
          ? data.fuelConsumption.value
          : this.fuelConsumption,
      fuelPrice: data.fuelPrice.present ? data.fuelPrice.value : this.fuelPrice,
      repairCost:
          data.repairCost.present ? data.repairCost.value : this.repairCost,
      additionalCosts: data.additionalCosts.present
          ? data.additionalCosts.value
          : this.additionalCosts,
      name: data.name.present ? data.name.value : this.name,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      version: data.version.present ? data.version.value : this.version,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('fuelConsumption: $fuelConsumption, ')
          ..write('fuelPrice: $fuelPrice, ')
          ..write('repairCost: $repairCost, ')
          ..write('additionalCosts: $additionalCosts, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('isDefault: $isDefault, ')
          ..write('version: $version, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      fuelConsumption,
      fuelPrice,
      repairCost,
      additionalCosts,
      name,
      isActive,
      isDefault,
      version,
      isSynced,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.fuelConsumption == this.fuelConsumption &&
          other.fuelPrice == this.fuelPrice &&
          other.repairCost == this.repairCost &&
          other.additionalCosts == this.additionalCosts &&
          other.name == this.name &&
          other.isActive == this.isActive &&
          other.isDefault == this.isDefault &&
          other.version == this.version &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<double> fuelConsumption;
  final Value<double> fuelPrice;
  final Value<double> repairCost;
  final Value<double> additionalCosts;
  final Value<String> name;
  final Value<bool> isActive;
  final Value<bool> isDefault;
  final Value<int> version;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const SettingsTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.fuelConsumption = const Value.absent(),
    this.fuelPrice = const Value.absent(),
    this.repairCost = const Value.absent(),
    this.additionalCosts = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.version = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.fuelConsumption = const Value.absent(),
    this.fuelPrice = const Value.absent(),
    this.repairCost = const Value.absent(),
    this.additionalCosts = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.version = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
  }) : createdAt = Value(createdAt);
  static Insertable<SettingsTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<double>? fuelConsumption,
    Expression<double>? fuelPrice,
    Expression<double>? repairCost,
    Expression<double>? additionalCosts,
    Expression<String>? name,
    Expression<bool>? isActive,
    Expression<bool>? isDefault,
    Expression<int>? version,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (fuelConsumption != null) 'fuel_consumption': fuelConsumption,
      if (fuelPrice != null) 'fuel_price': fuelPrice,
      if (repairCost != null) 'repair_cost': repairCost,
      if (additionalCosts != null) 'additional_costs': additionalCosts,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (isDefault != null) 'is_default': isDefault,
      if (version != null) 'version': version,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SettingsTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<double>? fuelConsumption,
      Value<double>? fuelPrice,
      Value<double>? repairCost,
      Value<double>? additionalCosts,
      Value<String>? name,
      Value<bool>? isActive,
      Value<bool>? isDefault,
      Value<int>? version,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt}) {
    return SettingsTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      fuelPrice: fuelPrice ?? this.fuelPrice,
      repairCost: repairCost ?? this.repairCost,
      additionalCosts: additionalCosts ?? this.additionalCosts,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      version: version ?? this.version,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (fuelConsumption.present) {
      map['fuel_consumption'] = Variable<double>(fuelConsumption.value);
    }
    if (fuelPrice.present) {
      map['fuel_price'] = Variable<double>(fuelPrice.value);
    }
    if (repairCost.present) {
      map['repair_cost'] = Variable<double>(repairCost.value);
    }
    if (additionalCosts.present) {
      map['additional_costs'] = Variable<double>(additionalCosts.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('fuelConsumption: $fuelConsumption, ')
          ..write('fuelPrice: $fuelPrice, ')
          ..write('repairCost: $repairCost, ')
          ..write('additionalCosts: $additionalCosts, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('isDefault: $isDefault, ')
          ..write('version: $version, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $X5SettingsTableTable extends X5SettingsTable
    with TableInfo<$X5SettingsTableTable, X5SettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $X5SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pickupPriceMeta =
      const VerificationMeta('pickupPrice');
  @override
  late final GeneratedColumn<double> pickupPrice = GeneratedColumn<double>(
      'pickup_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(250.0));
  static const VerificationMeta _deliveryPriceMeta =
      const VerificationMeta('deliveryPrice');
  @override
  late final GeneratedColumn<double> deliveryPrice = GeneratedColumn<double>(
      'delivery_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(150.0));
  static const VerificationMeta _perKmPriceMeta =
      const VerificationMeta('perKmPrice');
  @override
  late final GeneratedColumn<double> perKmPrice = GeneratedColumn<double>(
      'per_km_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(25.0));
  static const VerificationMeta _perKgPriceMeta =
      const VerificationMeta('perKgPrice');
  @override
  late final GeneratedColumn<double> perKgPrice = GeneratedColumn<double>(
      'per_kg_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(10.0));
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pickupPrice,
        deliveryPrice,
        perKmPrice,
        perKgPrice,
        isDefault,
        isActive,
        isSynced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'x5_settings_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<X5SettingsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pickup_price')) {
      context.handle(
          _pickupPriceMeta,
          pickupPrice.isAcceptableOrUnknown(
              data['pickup_price']!, _pickupPriceMeta));
    }
    if (data.containsKey('delivery_price')) {
      context.handle(
          _deliveryPriceMeta,
          deliveryPrice.isAcceptableOrUnknown(
              data['delivery_price']!, _deliveryPriceMeta));
    }
    if (data.containsKey('per_km_price')) {
      context.handle(
          _perKmPriceMeta,
          perKmPrice.isAcceptableOrUnknown(
              data['per_km_price']!, _perKmPriceMeta));
    }
    if (data.containsKey('per_kg_price')) {
      context.handle(
          _perKgPriceMeta,
          perKgPrice.isAcceptableOrUnknown(
              data['per_kg_price']!, _perKgPriceMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  X5SettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return X5SettingsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pickupPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}pickup_price'])!,
      deliveryPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}delivery_price'])!,
      perKmPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}per_km_price'])!,
      perKgPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}per_kg_price'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $X5SettingsTableTable createAlias(String alias) {
    return $X5SettingsTableTable(attachedDatabase, alias);
  }
}

class X5SettingsTableData extends DataClass
    implements Insertable<X5SettingsTableData> {
  final int id;
  final double pickupPrice;
  final double deliveryPrice;
  final double perKmPrice;
  final double perKgPrice;
  final bool isDefault;
  final bool isActive;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const X5SettingsTableData(
      {required this.id,
      required this.pickupPrice,
      required this.deliveryPrice,
      required this.perKmPrice,
      required this.perKgPrice,
      required this.isDefault,
      required this.isActive,
      required this.isSynced,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pickup_price'] = Variable<double>(pickupPrice);
    map['delivery_price'] = Variable<double>(deliveryPrice);
    map['per_km_price'] = Variable<double>(perKmPrice);
    map['per_kg_price'] = Variable<double>(perKgPrice);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_active'] = Variable<bool>(isActive);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  X5SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return X5SettingsTableCompanion(
      id: Value(id),
      pickupPrice: Value(pickupPrice),
      deliveryPrice: Value(deliveryPrice),
      perKmPrice: Value(perKmPrice),
      perKgPrice: Value(perKgPrice),
      isDefault: Value(isDefault),
      isActive: Value(isActive),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory X5SettingsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return X5SettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      pickupPrice: serializer.fromJson<double>(json['pickupPrice']),
      deliveryPrice: serializer.fromJson<double>(json['deliveryPrice']),
      perKmPrice: serializer.fromJson<double>(json['perKmPrice']),
      perKgPrice: serializer.fromJson<double>(json['perKgPrice']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pickupPrice': serializer.toJson<double>(pickupPrice),
      'deliveryPrice': serializer.toJson<double>(deliveryPrice),
      'perKmPrice': serializer.toJson<double>(perKmPrice),
      'perKgPrice': serializer.toJson<double>(perKgPrice),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isActive': serializer.toJson<bool>(isActive),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  X5SettingsTableData copyWith(
          {int? id,
          double? pickupPrice,
          double? deliveryPrice,
          double? perKmPrice,
          double? perKgPrice,
          bool? isDefault,
          bool? isActive,
          bool? isSynced,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      X5SettingsTableData(
        id: id ?? this.id,
        pickupPrice: pickupPrice ?? this.pickupPrice,
        deliveryPrice: deliveryPrice ?? this.deliveryPrice,
        perKmPrice: perKmPrice ?? this.perKmPrice,
        perKgPrice: perKgPrice ?? this.perKgPrice,
        isDefault: isDefault ?? this.isDefault,
        isActive: isActive ?? this.isActive,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  X5SettingsTableData copyWithCompanion(X5SettingsTableCompanion data) {
    return X5SettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      pickupPrice:
          data.pickupPrice.present ? data.pickupPrice.value : this.pickupPrice,
      deliveryPrice: data.deliveryPrice.present
          ? data.deliveryPrice.value
          : this.deliveryPrice,
      perKmPrice:
          data.perKmPrice.present ? data.perKmPrice.value : this.perKmPrice,
      perKgPrice:
          data.perKgPrice.present ? data.perKgPrice.value : this.perKgPrice,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('X5SettingsTableData(')
          ..write('id: $id, ')
          ..write('pickupPrice: $pickupPrice, ')
          ..write('deliveryPrice: $deliveryPrice, ')
          ..write('perKmPrice: $perKmPrice, ')
          ..write('perKgPrice: $perKgPrice, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pickupPrice, deliveryPrice, perKmPrice,
      perKgPrice, isDefault, isActive, isSynced, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is X5SettingsTableData &&
          other.id == this.id &&
          other.pickupPrice == this.pickupPrice &&
          other.deliveryPrice == this.deliveryPrice &&
          other.perKmPrice == this.perKmPrice &&
          other.perKgPrice == this.perKgPrice &&
          other.isDefault == this.isDefault &&
          other.isActive == this.isActive &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class X5SettingsTableCompanion extends UpdateCompanion<X5SettingsTableData> {
  final Value<int> id;
  final Value<double> pickupPrice;
  final Value<double> deliveryPrice;
  final Value<double> perKmPrice;
  final Value<double> perKgPrice;
  final Value<bool> isDefault;
  final Value<bool> isActive;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const X5SettingsTableCompanion({
    this.id = const Value.absent(),
    this.pickupPrice = const Value.absent(),
    this.deliveryPrice = const Value.absent(),
    this.perKmPrice = const Value.absent(),
    this.perKgPrice = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  X5SettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.pickupPrice = const Value.absent(),
    this.deliveryPrice = const Value.absent(),
    this.perKmPrice = const Value.absent(),
    this.perKgPrice = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
  }) : createdAt = Value(createdAt);
  static Insertable<X5SettingsTableData> custom({
    Expression<int>? id,
    Expression<double>? pickupPrice,
    Expression<double>? deliveryPrice,
    Expression<double>? perKmPrice,
    Expression<double>? perKgPrice,
    Expression<bool>? isDefault,
    Expression<bool>? isActive,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pickupPrice != null) 'pickup_price': pickupPrice,
      if (deliveryPrice != null) 'delivery_price': deliveryPrice,
      if (perKmPrice != null) 'per_km_price': perKmPrice,
      if (perKgPrice != null) 'per_kg_price': perKgPrice,
      if (isDefault != null) 'is_default': isDefault,
      if (isActive != null) 'is_active': isActive,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  X5SettingsTableCompanion copyWith(
      {Value<int>? id,
      Value<double>? pickupPrice,
      Value<double>? deliveryPrice,
      Value<double>? perKmPrice,
      Value<double>? perKgPrice,
      Value<bool>? isDefault,
      Value<bool>? isActive,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt}) {
    return X5SettingsTableCompanion(
      id: id ?? this.id,
      pickupPrice: pickupPrice ?? this.pickupPrice,
      deliveryPrice: deliveryPrice ?? this.deliveryPrice,
      perKmPrice: perKmPrice ?? this.perKmPrice,
      perKgPrice: perKgPrice ?? this.perKgPrice,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pickupPrice.present) {
      map['pickup_price'] = Variable<double>(pickupPrice.value);
    }
    if (deliveryPrice.present) {
      map['delivery_price'] = Variable<double>(deliveryPrice.value);
    }
    if (perKmPrice.present) {
      map['per_km_price'] = Variable<double>(perKmPrice.value);
    }
    if (perKgPrice.present) {
      map['per_kg_price'] = Variable<double>(perKgPrice.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('X5SettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('pickupPrice: $pickupPrice, ')
          ..write('deliveryPrice: $deliveryPrice, ')
          ..write('perKmPrice: $perKmPrice, ')
          ..write('perKgPrice: $perKgPrice, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ShiftTableTable extends ShiftTable
    with TableInfo<$ShiftTableTable, ShiftTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
      'start_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
      'end_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalPaidDistanceMeta =
      const VerificationMeta('totalPaidDistance');
  @override
  late final GeneratedColumn<double> totalPaidDistance =
      GeneratedColumn<double>('total_paid_distance', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _totalIdleDistanceMeta =
      const VerificationMeta('totalIdleDistance');
  @override
  late final GeneratedColumn<double> totalIdleDistance =
      GeneratedColumn<double>('total_idle_distance', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _ordersCountMeta =
      const VerificationMeta('ordersCount');
  @override
  late final GeneratedColumn<int> ordersCount = GeneratedColumn<int>(
      'orders_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalIncomeMeta =
      const VerificationMeta('totalIncome');
  @override
  late final GeneratedColumn<double> totalIncome = GeneratedColumn<double>(
      'total_income', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _totalExpensesMeta =
      const VerificationMeta('totalExpenses');
  @override
  late final GeneratedColumn<double> totalExpenses = GeneratedColumn<double>(
      'total_expenses', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _netProfitMeta =
      const VerificationMeta('netProfit');
  @override
  late final GeneratedColumn<double> netProfit = GeneratedColumn<double>(
      'net_profit', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        startTime,
        endTime,
        durationSeconds,
        totalPaidDistance,
        totalIdleDistance,
        ordersCount,
        totalIncome,
        totalExpenses,
        netProfit,
        status,
        isSynced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_table';
  @override
  VerificationContext validateIntegrity(Insertable<ShiftTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('total_paid_distance')) {
      context.handle(
          _totalPaidDistanceMeta,
          totalPaidDistance.isAcceptableOrUnknown(
              data['total_paid_distance']!, _totalPaidDistanceMeta));
    }
    if (data.containsKey('total_idle_distance')) {
      context.handle(
          _totalIdleDistanceMeta,
          totalIdleDistance.isAcceptableOrUnknown(
              data['total_idle_distance']!, _totalIdleDistanceMeta));
    }
    if (data.containsKey('orders_count')) {
      context.handle(
          _ordersCountMeta,
          ordersCount.isAcceptableOrUnknown(
              data['orders_count']!, _ordersCountMeta));
    }
    if (data.containsKey('total_income')) {
      context.handle(
          _totalIncomeMeta,
          totalIncome.isAcceptableOrUnknown(
              data['total_income']!, _totalIncomeMeta));
    }
    if (data.containsKey('total_expenses')) {
      context.handle(
          _totalExpensesMeta,
          totalExpenses.isAcceptableOrUnknown(
              data['total_expenses']!, _totalExpensesMeta));
    }
    if (data.containsKey('net_profit')) {
      context.handle(_netProfitMeta,
          netProfit.isAcceptableOrUnknown(data['net_profit']!, _netProfitMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_time']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      totalPaidDistance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_paid_distance'])!,
      totalIdleDistance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_idle_distance'])!,
      ordersCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}orders_count'])!,
      totalIncome: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_income'])!,
      totalExpenses: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_expenses'])!,
      netProfit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}net_profit'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $ShiftTableTable createAlias(String alias) {
    return $ShiftTableTable(attachedDatabase, alias);
  }
}

class ShiftTableData extends DataClass implements Insertable<ShiftTableData> {
  final int id;
  final int? serverId;
  final String startTime;
  final String? endTime;
  final int durationSeconds;
  final double totalPaidDistance;
  final double totalIdleDistance;
  final int ordersCount;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final String status;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const ShiftTableData(
      {required this.id,
      this.serverId,
      required this.startTime,
      this.endTime,
      required this.durationSeconds,
      required this.totalPaidDistance,
      required this.totalIdleDistance,
      required this.ordersCount,
      required this.totalIncome,
      required this.totalExpenses,
      required this.netProfit,
      required this.status,
      required this.isSynced,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['start_time'] = Variable<String>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['total_paid_distance'] = Variable<double>(totalPaidDistance);
    map['total_idle_distance'] = Variable<double>(totalIdleDistance);
    map['orders_count'] = Variable<int>(ordersCount);
    map['total_income'] = Variable<double>(totalIncome);
    map['total_expenses'] = Variable<double>(totalExpenses);
    map['net_profit'] = Variable<double>(netProfit);
    map['status'] = Variable<String>(status);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ShiftTableCompanion toCompanion(bool nullToAbsent) {
    return ShiftTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      durationSeconds: Value(durationSeconds),
      totalPaidDistance: Value(totalPaidDistance),
      totalIdleDistance: Value(totalIdleDistance),
      ordersCount: Value(ordersCount),
      totalIncome: Value(totalIncome),
      totalExpenses: Value(totalExpenses),
      netProfit: Value(netProfit),
      status: Value(status),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ShiftTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      totalPaidDistance: serializer.fromJson<double>(json['totalPaidDistance']),
      totalIdleDistance: serializer.fromJson<double>(json['totalIdleDistance']),
      ordersCount: serializer.fromJson<int>(json['ordersCount']),
      totalIncome: serializer.fromJson<double>(json['totalIncome']),
      totalExpenses: serializer.fromJson<double>(json['totalExpenses']),
      netProfit: serializer.fromJson<double>(json['netProfit']),
      status: serializer.fromJson<String>(json['status']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'totalPaidDistance': serializer.toJson<double>(totalPaidDistance),
      'totalIdleDistance': serializer.toJson<double>(totalIdleDistance),
      'ordersCount': serializer.toJson<int>(ordersCount),
      'totalIncome': serializer.toJson<double>(totalIncome),
      'totalExpenses': serializer.toJson<double>(totalExpenses),
      'netProfit': serializer.toJson<double>(netProfit),
      'status': serializer.toJson<String>(status),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  ShiftTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          String? startTime,
          Value<String?> endTime = const Value.absent(),
          int? durationSeconds,
          double? totalPaidDistance,
          double? totalIdleDistance,
          int? ordersCount,
          double? totalIncome,
          double? totalExpenses,
          double? netProfit,
          String? status,
          bool? isSynced,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      ShiftTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        totalPaidDistance: totalPaidDistance ?? this.totalPaidDistance,
        totalIdleDistance: totalIdleDistance ?? this.totalIdleDistance,
        ordersCount: ordersCount ?? this.ordersCount,
        totalIncome: totalIncome ?? this.totalIncome,
        totalExpenses: totalExpenses ?? this.totalExpenses,
        netProfit: netProfit ?? this.netProfit,
        status: status ?? this.status,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  ShiftTableData copyWithCompanion(ShiftTableCompanion data) {
    return ShiftTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      totalPaidDistance: data.totalPaidDistance.present
          ? data.totalPaidDistance.value
          : this.totalPaidDistance,
      totalIdleDistance: data.totalIdleDistance.present
          ? data.totalIdleDistance.value
          : this.totalIdleDistance,
      ordersCount:
          data.ordersCount.present ? data.ordersCount.value : this.ordersCount,
      totalIncome:
          data.totalIncome.present ? data.totalIncome.value : this.totalIncome,
      totalExpenses: data.totalExpenses.present
          ? data.totalExpenses.value
          : this.totalExpenses,
      netProfit: data.netProfit.present ? data.netProfit.value : this.netProfit,
      status: data.status.present ? data.status.value : this.status,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('totalPaidDistance: $totalPaidDistance, ')
          ..write('totalIdleDistance: $totalIdleDistance, ')
          ..write('ordersCount: $ordersCount, ')
          ..write('totalIncome: $totalIncome, ')
          ..write('totalExpenses: $totalExpenses, ')
          ..write('netProfit: $netProfit, ')
          ..write('status: $status, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      startTime,
      endTime,
      durationSeconds,
      totalPaidDistance,
      totalIdleDistance,
      ordersCount,
      totalIncome,
      totalExpenses,
      netProfit,
      status,
      isSynced,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationSeconds == this.durationSeconds &&
          other.totalPaidDistance == this.totalPaidDistance &&
          other.totalIdleDistance == this.totalIdleDistance &&
          other.ordersCount == this.ordersCount &&
          other.totalIncome == this.totalIncome &&
          other.totalExpenses == this.totalExpenses &&
          other.netProfit == this.netProfit &&
          other.status == this.status &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShiftTableCompanion extends UpdateCompanion<ShiftTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> startTime;
  final Value<String?> endTime;
  final Value<int> durationSeconds;
  final Value<double> totalPaidDistance;
  final Value<double> totalIdleDistance;
  final Value<int> ordersCount;
  final Value<double> totalIncome;
  final Value<double> totalExpenses;
  final Value<double> netProfit;
  final Value<String> status;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const ShiftTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.totalPaidDistance = const Value.absent(),
    this.totalIdleDistance = const Value.absent(),
    this.ordersCount = const Value.absent(),
    this.totalIncome = const Value.absent(),
    this.totalExpenses = const Value.absent(),
    this.netProfit = const Value.absent(),
    this.status = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ShiftTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String startTime,
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.totalPaidDistance = const Value.absent(),
    this.totalIdleDistance = const Value.absent(),
    this.ordersCount = const Value.absent(),
    this.totalIncome = const Value.absent(),
    this.totalExpenses = const Value.absent(),
    this.netProfit = const Value.absent(),
    this.status = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
  })  : startTime = Value(startTime),
        createdAt = Value(createdAt);
  static Insertable<ShiftTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<int>? durationSeconds,
    Expression<double>? totalPaidDistance,
    Expression<double>? totalIdleDistance,
    Expression<int>? ordersCount,
    Expression<double>? totalIncome,
    Expression<double>? totalExpenses,
    Expression<double>? netProfit,
    Expression<String>? status,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (totalPaidDistance != null) 'total_paid_distance': totalPaidDistance,
      if (totalIdleDistance != null) 'total_idle_distance': totalIdleDistance,
      if (ordersCount != null) 'orders_count': ordersCount,
      if (totalIncome != null) 'total_income': totalIncome,
      if (totalExpenses != null) 'total_expenses': totalExpenses,
      if (netProfit != null) 'net_profit': netProfit,
      if (status != null) 'status': status,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ShiftTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<String>? startTime,
      Value<String?>? endTime,
      Value<int>? durationSeconds,
      Value<double>? totalPaidDistance,
      Value<double>? totalIdleDistance,
      Value<int>? ordersCount,
      Value<double>? totalIncome,
      Value<double>? totalExpenses,
      Value<double>? netProfit,
      Value<String>? status,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt}) {
    return ShiftTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalPaidDistance: totalPaidDistance ?? this.totalPaidDistance,
      totalIdleDistance: totalIdleDistance ?? this.totalIdleDistance,
      ordersCount: ordersCount ?? this.ordersCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (totalPaidDistance.present) {
      map['total_paid_distance'] = Variable<double>(totalPaidDistance.value);
    }
    if (totalIdleDistance.present) {
      map['total_idle_distance'] = Variable<double>(totalIdleDistance.value);
    }
    if (ordersCount.present) {
      map['orders_count'] = Variable<int>(ordersCount.value);
    }
    if (totalIncome.present) {
      map['total_income'] = Variable<double>(totalIncome.value);
    }
    if (totalExpenses.present) {
      map['total_expenses'] = Variable<double>(totalExpenses.value);
    }
    if (netProfit.present) {
      map['net_profit'] = Variable<double>(netProfit.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('totalPaidDistance: $totalPaidDistance, ')
          ..write('totalIdleDistance: $totalIdleDistance, ')
          ..write('ordersCount: $ordersCount, ')
          ..write('totalIncome: $totalIncome, ')
          ..write('totalExpenses: $totalExpenses, ')
          ..write('netProfit: $netProfit, ')
          ..write('status: $status, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $OrderTableTable extends OrderTable
    with TableInfo<$OrderTableTable, OrderTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _shiftIdMeta =
      const VerificationMeta('shiftId');
  @override
  late final GeneratedColumn<int> shiftId = GeneratedColumn<int>(
      'shift_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deliveryNumberMeta =
      const VerificationMeta('deliveryNumber');
  @override
  late final GeneratedColumn<int> deliveryNumber = GeneratedColumn<int>(
      'delivery_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _coefficientMeta =
      const VerificationMeta('coefficient');
  @override
  late final GeneratedColumn<double> coefficient = GeneratedColumn<double>(
      'coefficient', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _serviceNameMeta =
      const VerificationMeta('serviceName');
  @override
  late final GeneratedColumn<String> serviceName = GeneratedColumn<String>(
      'service_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        shiftId,
        deliveryNumber,
        coefficient,
        serviceName,
        status,
        isSynced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_table';
  @override
  VerificationContext validateIntegrity(Insertable<OrderTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('shift_id')) {
      context.handle(_shiftIdMeta,
          shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta));
    }
    if (data.containsKey('delivery_number')) {
      context.handle(
          _deliveryNumberMeta,
          deliveryNumber.isAcceptableOrUnknown(
              data['delivery_number']!, _deliveryNumberMeta));
    }
    if (data.containsKey('coefficient')) {
      context.handle(
          _coefficientMeta,
          coefficient.isAcceptableOrUnknown(
              data['coefficient']!, _coefficientMeta));
    }
    if (data.containsKey('service_name')) {
      context.handle(
          _serviceNameMeta,
          serviceName.isAcceptableOrUnknown(
              data['service_name']!, _serviceNameMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      shiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shift_id']),
      deliveryNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}delivery_number']),
      coefficient: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}coefficient']),
      serviceName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}service_name']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $OrderTableTable createAlias(String alias) {
    return $OrderTableTable(attachedDatabase, alias);
  }
}

class OrderTableData extends DataClass implements Insertable<OrderTableData> {
  final int id;
  final int? serverId;
  final int? shiftId;
  final int? deliveryNumber;
  final double? coefficient;
  final String? serviceName;
  final String status;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const OrderTableData(
      {required this.id,
      this.serverId,
      this.shiftId,
      this.deliveryNumber,
      this.coefficient,
      this.serviceName,
      required this.status,
      required this.isSynced,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<int>(shiftId);
    }
    if (!nullToAbsent || deliveryNumber != null) {
      map['delivery_number'] = Variable<int>(deliveryNumber);
    }
    if (!nullToAbsent || coefficient != null) {
      map['coefficient'] = Variable<double>(coefficient);
    }
    if (!nullToAbsent || serviceName != null) {
      map['service_name'] = Variable<String>(serviceName);
    }
    map['status'] = Variable<String>(status);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  OrderTableCompanion toCompanion(bool nullToAbsent) {
    return OrderTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      deliveryNumber: deliveryNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryNumber),
      coefficient: coefficient == null && nullToAbsent
          ? const Value.absent()
          : Value(coefficient),
      serviceName: serviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceName),
      status: Value(status),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory OrderTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      shiftId: serializer.fromJson<int?>(json['shiftId']),
      deliveryNumber: serializer.fromJson<int?>(json['deliveryNumber']),
      coefficient: serializer.fromJson<double?>(json['coefficient']),
      serviceName: serializer.fromJson<String?>(json['serviceName']),
      status: serializer.fromJson<String>(json['status']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'shiftId': serializer.toJson<int?>(shiftId),
      'deliveryNumber': serializer.toJson<int?>(deliveryNumber),
      'coefficient': serializer.toJson<double?>(coefficient),
      'serviceName': serializer.toJson<String?>(serviceName),
      'status': serializer.toJson<String>(status),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  OrderTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          Value<int?> shiftId = const Value.absent(),
          Value<int?> deliveryNumber = const Value.absent(),
          Value<double?> coefficient = const Value.absent(),
          Value<String?> serviceName = const Value.absent(),
          String? status,
          bool? isSynced,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      OrderTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        shiftId: shiftId.present ? shiftId.value : this.shiftId,
        deliveryNumber:
            deliveryNumber.present ? deliveryNumber.value : this.deliveryNumber,
        coefficient: coefficient.present ? coefficient.value : this.coefficient,
        serviceName: serviceName.present ? serviceName.value : this.serviceName,
        status: status ?? this.status,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  OrderTableData copyWithCompanion(OrderTableCompanion data) {
    return OrderTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      deliveryNumber: data.deliveryNumber.present
          ? data.deliveryNumber.value
          : this.deliveryNumber,
      coefficient:
          data.coefficient.present ? data.coefficient.value : this.coefficient,
      serviceName:
          data.serviceName.present ? data.serviceName.value : this.serviceName,
      status: data.status.present ? data.status.value : this.status,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('shiftId: $shiftId, ')
          ..write('deliveryNumber: $deliveryNumber, ')
          ..write('coefficient: $coefficient, ')
          ..write('serviceName: $serviceName, ')
          ..write('status: $status, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverId, shiftId, deliveryNumber,
      coefficient, serviceName, status, isSynced, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.shiftId == this.shiftId &&
          other.deliveryNumber == this.deliveryNumber &&
          other.coefficient == this.coefficient &&
          other.serviceName == this.serviceName &&
          other.status == this.status &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OrderTableCompanion extends UpdateCompanion<OrderTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int?> shiftId;
  final Value<int?> deliveryNumber;
  final Value<double?> coefficient;
  final Value<String?> serviceName;
  final Value<String> status;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const OrderTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.deliveryNumber = const Value.absent(),
    this.coefficient = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.status = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  OrderTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.deliveryNumber = const Value.absent(),
    this.coefficient = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.status = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
  }) : createdAt = Value(createdAt);
  static Insertable<OrderTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? shiftId,
    Expression<int>? deliveryNumber,
    Expression<double>? coefficient,
    Expression<String>? serviceName,
    Expression<String>? status,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (shiftId != null) 'shift_id': shiftId,
      if (deliveryNumber != null) 'delivery_number': deliveryNumber,
      if (coefficient != null) 'coefficient': coefficient,
      if (serviceName != null) 'service_name': serviceName,
      if (status != null) 'status': status,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  OrderTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<int?>? shiftId,
      Value<int?>? deliveryNumber,
      Value<double?>? coefficient,
      Value<String?>? serviceName,
      Value<String>? status,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt}) {
    return OrderTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      shiftId: shiftId ?? this.shiftId,
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      coefficient: coefficient ?? this.coefficient,
      serviceName: serviceName ?? this.serviceName,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<int>(shiftId.value);
    }
    if (deliveryNumber.present) {
      map['delivery_number'] = Variable<int>(deliveryNumber.value);
    }
    if (coefficient.present) {
      map['coefficient'] = Variable<double>(coefficient.value);
    }
    if (serviceName.present) {
      map['service_name'] = Variable<String>(serviceName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('shiftId: $shiftId, ')
          ..write('deliveryNumber: $deliveryNumber, ')
          ..write('coefficient: $coefficient, ')
          ..write('serviceName: $serviceName, ')
          ..write('status: $status, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DeliveryTableTable extends DeliveryTable
    with TableInfo<$DeliveryTableTable, DeliveryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliveryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
      'order_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _clientAddressMeta =
      const VerificationMeta('clientAddress');
  @override
  late final GeneratedColumn<String> clientAddress = GeneratedColumn<String>(
      'client_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _apartmentMeta =
      const VerificationMeta('apartment');
  @override
  late final GeneratedColumn<String> apartment = GeneratedColumn<String>(
      'apartment', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _timeToShopMeta =
      const VerificationMeta('timeToShop');
  @override
  late final GeneratedColumn<int> timeToShop = GeneratedColumn<int>(
      'time_to_shop', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _distanceToShopMeta =
      const VerificationMeta('distanceToShop');
  @override
  late final GeneratedColumn<double> distanceToShop = GeneratedColumn<double>(
      'distance_to_shop', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _timeReceivingMeta =
      const VerificationMeta('timeReceiving');
  @override
  late final GeneratedColumn<int> timeReceiving = GeneratedColumn<int>(
      'time_receiving', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _timeToClientMeta =
      const VerificationMeta('timeToClient');
  @override
  late final GeneratedColumn<int> timeToClient = GeneratedColumn<int>(
      'time_to_client', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _distanceToClientMeta =
      const VerificationMeta('distanceToClient');
  @override
  late final GeneratedColumn<double> distanceToClient = GeneratedColumn<double>(
      'distance_to_client', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _timeDeliveryMeta =
      const VerificationMeta('timeDelivery');
  @override
  late final GeneratedColumn<int> timeDelivery = GeneratedColumn<int>(
      'time_delivery', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        orderId,
        number,
        clientAddress,
        apartment,
        weight,
        timeToShop,
        distanceToShop,
        timeReceiving,
        timeToClient,
        distanceToClient,
        timeDelivery,
        status,
        isSynced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_table';
  @override
  VerificationContext validateIntegrity(Insertable<DeliveryTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('client_address')) {
      context.handle(
          _clientAddressMeta,
          clientAddress.isAcceptableOrUnknown(
              data['client_address']!, _clientAddressMeta));
    } else if (isInserting) {
      context.missing(_clientAddressMeta);
    }
    if (data.containsKey('apartment')) {
      context.handle(_apartmentMeta,
          apartment.isAcceptableOrUnknown(data['apartment']!, _apartmentMeta));
    } else if (isInserting) {
      context.missing(_apartmentMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('time_to_shop')) {
      context.handle(
          _timeToShopMeta,
          timeToShop.isAcceptableOrUnknown(
              data['time_to_shop']!, _timeToShopMeta));
    }
    if (data.containsKey('distance_to_shop')) {
      context.handle(
          _distanceToShopMeta,
          distanceToShop.isAcceptableOrUnknown(
              data['distance_to_shop']!, _distanceToShopMeta));
    }
    if (data.containsKey('time_receiving')) {
      context.handle(
          _timeReceivingMeta,
          timeReceiving.isAcceptableOrUnknown(
              data['time_receiving']!, _timeReceivingMeta));
    }
    if (data.containsKey('time_to_client')) {
      context.handle(
          _timeToClientMeta,
          timeToClient.isAcceptableOrUnknown(
              data['time_to_client']!, _timeToClientMeta));
    }
    if (data.containsKey('distance_to_client')) {
      context.handle(
          _distanceToClientMeta,
          distanceToClient.isAcceptableOrUnknown(
              data['distance_to_client']!, _distanceToClientMeta));
    }
    if (data.containsKey('time_delivery')) {
      context.handle(
          _timeDeliveryMeta,
          timeDelivery.isAcceptableOrUnknown(
              data['time_delivery']!, _timeDeliveryMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeliveryTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_id']),
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number'])!,
      clientAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_address'])!,
      apartment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}apartment'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      timeToShop: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_to_shop'])!,
      distanceToShop: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}distance_to_shop'])!,
      timeReceiving: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_receiving'])!,
      timeToClient: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_to_client'])!,
      distanceToClient: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}distance_to_client'])!,
      timeDelivery: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_delivery'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $DeliveryTableTable createAlias(String alias) {
    return $DeliveryTableTable(attachedDatabase, alias);
  }
}

class DeliveryTableData extends DataClass
    implements Insertable<DeliveryTableData> {
  final int id;
  final int? serverId;
  final int? orderId;
  final int number;
  final String clientAddress;
  final String apartment;
  final double weight;
  final int timeToShop;
  final double distanceToShop;
  final int timeReceiving;
  final int timeToClient;
  final double distanceToClient;
  final int timeDelivery;
  final String status;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const DeliveryTableData(
      {required this.id,
      this.serverId,
      this.orderId,
      required this.number,
      required this.clientAddress,
      required this.apartment,
      required this.weight,
      required this.timeToShop,
      required this.distanceToShop,
      required this.timeReceiving,
      required this.timeToClient,
      required this.distanceToClient,
      required this.timeDelivery,
      required this.status,
      required this.isSynced,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<int>(orderId);
    }
    map['number'] = Variable<int>(number);
    map['client_address'] = Variable<String>(clientAddress);
    map['apartment'] = Variable<String>(apartment);
    map['weight'] = Variable<double>(weight);
    map['time_to_shop'] = Variable<int>(timeToShop);
    map['distance_to_shop'] = Variable<double>(distanceToShop);
    map['time_receiving'] = Variable<int>(timeReceiving);
    map['time_to_client'] = Variable<int>(timeToClient);
    map['distance_to_client'] = Variable<double>(distanceToClient);
    map['time_delivery'] = Variable<int>(timeDelivery);
    map['status'] = Variable<String>(status);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  DeliveryTableCompanion toCompanion(bool nullToAbsent) {
    return DeliveryTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      number: Value(number),
      clientAddress: Value(clientAddress),
      apartment: Value(apartment),
      weight: Value(weight),
      timeToShop: Value(timeToShop),
      distanceToShop: Value(distanceToShop),
      timeReceiving: Value(timeReceiving),
      timeToClient: Value(timeToClient),
      distanceToClient: Value(distanceToClient),
      timeDelivery: Value(timeDelivery),
      status: Value(status),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory DeliveryTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      orderId: serializer.fromJson<int?>(json['orderId']),
      number: serializer.fromJson<int>(json['number']),
      clientAddress: serializer.fromJson<String>(json['clientAddress']),
      apartment: serializer.fromJson<String>(json['apartment']),
      weight: serializer.fromJson<double>(json['weight']),
      timeToShop: serializer.fromJson<int>(json['timeToShop']),
      distanceToShop: serializer.fromJson<double>(json['distanceToShop']),
      timeReceiving: serializer.fromJson<int>(json['timeReceiving']),
      timeToClient: serializer.fromJson<int>(json['timeToClient']),
      distanceToClient: serializer.fromJson<double>(json['distanceToClient']),
      timeDelivery: serializer.fromJson<int>(json['timeDelivery']),
      status: serializer.fromJson<String>(json['status']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'orderId': serializer.toJson<int?>(orderId),
      'number': serializer.toJson<int>(number),
      'clientAddress': serializer.toJson<String>(clientAddress),
      'apartment': serializer.toJson<String>(apartment),
      'weight': serializer.toJson<double>(weight),
      'timeToShop': serializer.toJson<int>(timeToShop),
      'distanceToShop': serializer.toJson<double>(distanceToShop),
      'timeReceiving': serializer.toJson<int>(timeReceiving),
      'timeToClient': serializer.toJson<int>(timeToClient),
      'distanceToClient': serializer.toJson<double>(distanceToClient),
      'timeDelivery': serializer.toJson<int>(timeDelivery),
      'status': serializer.toJson<String>(status),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  DeliveryTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          Value<int?> orderId = const Value.absent(),
          int? number,
          String? clientAddress,
          String? apartment,
          double? weight,
          int? timeToShop,
          double? distanceToShop,
          int? timeReceiving,
          int? timeToClient,
          double? distanceToClient,
          int? timeDelivery,
          String? status,
          bool? isSynced,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      DeliveryTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        orderId: orderId.present ? orderId.value : this.orderId,
        number: number ?? this.number,
        clientAddress: clientAddress ?? this.clientAddress,
        apartment: apartment ?? this.apartment,
        weight: weight ?? this.weight,
        timeToShop: timeToShop ?? this.timeToShop,
        distanceToShop: distanceToShop ?? this.distanceToShop,
        timeReceiving: timeReceiving ?? this.timeReceiving,
        timeToClient: timeToClient ?? this.timeToClient,
        distanceToClient: distanceToClient ?? this.distanceToClient,
        timeDelivery: timeDelivery ?? this.timeDelivery,
        status: status ?? this.status,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  DeliveryTableData copyWithCompanion(DeliveryTableCompanion data) {
    return DeliveryTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      number: data.number.present ? data.number.value : this.number,
      clientAddress: data.clientAddress.present
          ? data.clientAddress.value
          : this.clientAddress,
      apartment: data.apartment.present ? data.apartment.value : this.apartment,
      weight: data.weight.present ? data.weight.value : this.weight,
      timeToShop:
          data.timeToShop.present ? data.timeToShop.value : this.timeToShop,
      distanceToShop: data.distanceToShop.present
          ? data.distanceToShop.value
          : this.distanceToShop,
      timeReceiving: data.timeReceiving.present
          ? data.timeReceiving.value
          : this.timeReceiving,
      timeToClient: data.timeToClient.present
          ? data.timeToClient.value
          : this.timeToClient,
      distanceToClient: data.distanceToClient.present
          ? data.distanceToClient.value
          : this.distanceToClient,
      timeDelivery: data.timeDelivery.present
          ? data.timeDelivery.value
          : this.timeDelivery,
      status: data.status.present ? data.status.value : this.status,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('orderId: $orderId, ')
          ..write('number: $number, ')
          ..write('clientAddress: $clientAddress, ')
          ..write('apartment: $apartment, ')
          ..write('weight: $weight, ')
          ..write('timeToShop: $timeToShop, ')
          ..write('distanceToShop: $distanceToShop, ')
          ..write('timeReceiving: $timeReceiving, ')
          ..write('timeToClient: $timeToClient, ')
          ..write('distanceToClient: $distanceToClient, ')
          ..write('timeDelivery: $timeDelivery, ')
          ..write('status: $status, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      orderId,
      number,
      clientAddress,
      apartment,
      weight,
      timeToShop,
      distanceToShop,
      timeReceiving,
      timeToClient,
      distanceToClient,
      timeDelivery,
      status,
      isSynced,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.orderId == this.orderId &&
          other.number == this.number &&
          other.clientAddress == this.clientAddress &&
          other.apartment == this.apartment &&
          other.weight == this.weight &&
          other.timeToShop == this.timeToShop &&
          other.distanceToShop == this.distanceToShop &&
          other.timeReceiving == this.timeReceiving &&
          other.timeToClient == this.timeToClient &&
          other.distanceToClient == this.distanceToClient &&
          other.timeDelivery == this.timeDelivery &&
          other.status == this.status &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DeliveryTableCompanion extends UpdateCompanion<DeliveryTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int?> orderId;
  final Value<int> number;
  final Value<String> clientAddress;
  final Value<String> apartment;
  final Value<double> weight;
  final Value<int> timeToShop;
  final Value<double> distanceToShop;
  final Value<int> timeReceiving;
  final Value<int> timeToClient;
  final Value<double> distanceToClient;
  final Value<int> timeDelivery;
  final Value<String> status;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const DeliveryTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.orderId = const Value.absent(),
    this.number = const Value.absent(),
    this.clientAddress = const Value.absent(),
    this.apartment = const Value.absent(),
    this.weight = const Value.absent(),
    this.timeToShop = const Value.absent(),
    this.distanceToShop = const Value.absent(),
    this.timeReceiving = const Value.absent(),
    this.timeToClient = const Value.absent(),
    this.distanceToClient = const Value.absent(),
    this.timeDelivery = const Value.absent(),
    this.status = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DeliveryTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.orderId = const Value.absent(),
    required int number,
    required String clientAddress,
    required String apartment,
    required double weight,
    this.timeToShop = const Value.absent(),
    this.distanceToShop = const Value.absent(),
    this.timeReceiving = const Value.absent(),
    this.timeToClient = const Value.absent(),
    this.distanceToClient = const Value.absent(),
    this.timeDelivery = const Value.absent(),
    this.status = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
  })  : number = Value(number),
        clientAddress = Value(clientAddress),
        apartment = Value(apartment),
        weight = Value(weight),
        createdAt = Value(createdAt);
  static Insertable<DeliveryTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? orderId,
    Expression<int>? number,
    Expression<String>? clientAddress,
    Expression<String>? apartment,
    Expression<double>? weight,
    Expression<int>? timeToShop,
    Expression<double>? distanceToShop,
    Expression<int>? timeReceiving,
    Expression<int>? timeToClient,
    Expression<double>? distanceToClient,
    Expression<int>? timeDelivery,
    Expression<String>? status,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (orderId != null) 'order_id': orderId,
      if (number != null) 'number': number,
      if (clientAddress != null) 'client_address': clientAddress,
      if (apartment != null) 'apartment': apartment,
      if (weight != null) 'weight': weight,
      if (timeToShop != null) 'time_to_shop': timeToShop,
      if (distanceToShop != null) 'distance_to_shop': distanceToShop,
      if (timeReceiving != null) 'time_receiving': timeReceiving,
      if (timeToClient != null) 'time_to_client': timeToClient,
      if (distanceToClient != null) 'distance_to_client': distanceToClient,
      if (timeDelivery != null) 'time_delivery': timeDelivery,
      if (status != null) 'status': status,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DeliveryTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<int?>? orderId,
      Value<int>? number,
      Value<String>? clientAddress,
      Value<String>? apartment,
      Value<double>? weight,
      Value<int>? timeToShop,
      Value<double>? distanceToShop,
      Value<int>? timeReceiving,
      Value<int>? timeToClient,
      Value<double>? distanceToClient,
      Value<int>? timeDelivery,
      Value<String>? status,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt}) {
    return DeliveryTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      orderId: orderId ?? this.orderId,
      number: number ?? this.number,
      clientAddress: clientAddress ?? this.clientAddress,
      apartment: apartment ?? this.apartment,
      weight: weight ?? this.weight,
      timeToShop: timeToShop ?? this.timeToShop,
      distanceToShop: distanceToShop ?? this.distanceToShop,
      timeReceiving: timeReceiving ?? this.timeReceiving,
      timeToClient: timeToClient ?? this.timeToClient,
      distanceToClient: distanceToClient ?? this.distanceToClient,
      timeDelivery: timeDelivery ?? this.timeDelivery,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (clientAddress.present) {
      map['client_address'] = Variable<String>(clientAddress.value);
    }
    if (apartment.present) {
      map['apartment'] = Variable<String>(apartment.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (timeToShop.present) {
      map['time_to_shop'] = Variable<int>(timeToShop.value);
    }
    if (distanceToShop.present) {
      map['distance_to_shop'] = Variable<double>(distanceToShop.value);
    }
    if (timeReceiving.present) {
      map['time_receiving'] = Variable<int>(timeReceiving.value);
    }
    if (timeToClient.present) {
      map['time_to_client'] = Variable<int>(timeToClient.value);
    }
    if (distanceToClient.present) {
      map['distance_to_client'] = Variable<double>(distanceToClient.value);
    }
    if (timeDelivery.present) {
      map['time_delivery'] = Variable<int>(timeDelivery.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('orderId: $orderId, ')
          ..write('number: $number, ')
          ..write('clientAddress: $clientAddress, ')
          ..write('apartment: $apartment, ')
          ..write('weight: $weight, ')
          ..write('timeToShop: $timeToShop, ')
          ..write('distanceToShop: $distanceToShop, ')
          ..write('timeReceiving: $timeReceiving, ')
          ..write('timeToClient: $timeToClient, ')
          ..write('distanceToClient: $distanceToClient, ')
          ..write('timeDelivery: $timeDelivery, ')
          ..write('status: $status, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GpsPointTableTable extends GpsPointTable
    with TableInfo<$GpsPointTableTable, GpsPointTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GpsPointTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deliveryIdMeta =
      const VerificationMeta('deliveryId');
  @override
  late final GeneratedColumn<int> deliveryId = GeneratedColumn<int>(
      'delivery_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _segmentIndexMeta =
      const VerificationMeta('segmentIndex');
  @override
  late final GeneratedColumn<int> segmentIndex = GeneratedColumn<int>(
      'segment_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _accuracyMeta =
      const VerificationMeta('accuracy');
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
      'accuracy', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
      'speed', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deliveryId,
        segmentIndex,
        latitude,
        longitude,
        accuracy,
        speed,
        timestamp,
        isSynced,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gps_point_table';
  @override
  VerificationContext validateIntegrity(Insertable<GpsPointTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('delivery_id')) {
      context.handle(
          _deliveryIdMeta,
          deliveryId.isAcceptableOrUnknown(
              data['delivery_id']!, _deliveryIdMeta));
    }
    if (data.containsKey('segment_index')) {
      context.handle(
          _segmentIndexMeta,
          segmentIndex.isAcceptableOrUnknown(
              data['segment_index']!, _segmentIndexMeta));
    } else if (isInserting) {
      context.missing(_segmentIndexMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(_accuracyMeta,
          accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta));
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
          _speedMeta, speed.isAcceptableOrUnknown(data['speed']!, _speedMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GpsPointTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GpsPointTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deliveryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}delivery_id']),
      segmentIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}segment_index'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      accuracy: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}accuracy'])!,
      speed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GpsPointTableTable createAlias(String alias) {
    return $GpsPointTableTable(attachedDatabase, alias);
  }
}

class GpsPointTableData extends DataClass
    implements Insertable<GpsPointTableData> {
  final int id;
  final int? deliveryId;
  final int segmentIndex;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final int timestamp;
  final bool isSynced;
  final DateTime createdAt;
  const GpsPointTableData(
      {required this.id,
      this.deliveryId,
      required this.segmentIndex,
      required this.latitude,
      required this.longitude,
      required this.accuracy,
      this.speed,
      required this.timestamp,
      required this.isSynced,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || deliveryId != null) {
      map['delivery_id'] = Variable<int>(deliveryId);
    }
    map['segment_index'] = Variable<int>(segmentIndex);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['accuracy'] = Variable<double>(accuracy);
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    map['timestamp'] = Variable<int>(timestamp);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GpsPointTableCompanion toCompanion(bool nullToAbsent) {
    return GpsPointTableCompanion(
      id: Value(id),
      deliveryId: deliveryId == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryId),
      segmentIndex: Value(segmentIndex),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracy: Value(accuracy),
      speed:
          speed == null && nullToAbsent ? const Value.absent() : Value(speed),
      timestamp: Value(timestamp),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
    );
  }

  factory GpsPointTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GpsPointTableData(
      id: serializer.fromJson<int>(json['id']),
      deliveryId: serializer.fromJson<int?>(json['deliveryId']),
      segmentIndex: serializer.fromJson<int>(json['segmentIndex']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      speed: serializer.fromJson<double?>(json['speed']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deliveryId': serializer.toJson<int?>(deliveryId),
      'segmentIndex': serializer.toJson<int>(segmentIndex),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracy': serializer.toJson<double>(accuracy),
      'speed': serializer.toJson<double?>(speed),
      'timestamp': serializer.toJson<int>(timestamp),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GpsPointTableData copyWith(
          {int? id,
          Value<int?> deliveryId = const Value.absent(),
          int? segmentIndex,
          double? latitude,
          double? longitude,
          double? accuracy,
          Value<double?> speed = const Value.absent(),
          int? timestamp,
          bool? isSynced,
          DateTime? createdAt}) =>
      GpsPointTableData(
        id: id ?? this.id,
        deliveryId: deliveryId.present ? deliveryId.value : this.deliveryId,
        segmentIndex: segmentIndex ?? this.segmentIndex,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        accuracy: accuracy ?? this.accuracy,
        speed: speed.present ? speed.value : this.speed,
        timestamp: timestamp ?? this.timestamp,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
      );
  GpsPointTableData copyWithCompanion(GpsPointTableCompanion data) {
    return GpsPointTableData(
      id: data.id.present ? data.id.value : this.id,
      deliveryId:
          data.deliveryId.present ? data.deliveryId.value : this.deliveryId,
      segmentIndex: data.segmentIndex.present
          ? data.segmentIndex.value
          : this.segmentIndex,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      speed: data.speed.present ? data.speed.value : this.speed,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GpsPointTableData(')
          ..write('id: $id, ')
          ..write('deliveryId: $deliveryId, ')
          ..write('segmentIndex: $segmentIndex, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('speed: $speed, ')
          ..write('timestamp: $timestamp, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deliveryId, segmentIndex, latitude,
      longitude, accuracy, speed, timestamp, isSynced, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GpsPointTableData &&
          other.id == this.id &&
          other.deliveryId == this.deliveryId &&
          other.segmentIndex == this.segmentIndex &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracy == this.accuracy &&
          other.speed == this.speed &&
          other.timestamp == this.timestamp &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt);
}

class GpsPointTableCompanion extends UpdateCompanion<GpsPointTableData> {
  final Value<int> id;
  final Value<int?> deliveryId;
  final Value<int> segmentIndex;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> accuracy;
  final Value<double?> speed;
  final Value<int> timestamp;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  const GpsPointTableCompanion({
    this.id = const Value.absent(),
    this.deliveryId = const Value.absent(),
    this.segmentIndex = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.speed = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GpsPointTableCompanion.insert({
    this.id = const Value.absent(),
    this.deliveryId = const Value.absent(),
    required int segmentIndex,
    required double latitude,
    required double longitude,
    required double accuracy,
    this.speed = const Value.absent(),
    required int timestamp,
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
  })  : segmentIndex = Value(segmentIndex),
        latitude = Value(latitude),
        longitude = Value(longitude),
        accuracy = Value(accuracy),
        timestamp = Value(timestamp),
        createdAt = Value(createdAt);
  static Insertable<GpsPointTableData> custom({
    Expression<int>? id,
    Expression<int>? deliveryId,
    Expression<int>? segmentIndex,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracy,
    Expression<double>? speed,
    Expression<int>? timestamp,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deliveryId != null) 'delivery_id': deliveryId,
      if (segmentIndex != null) 'segment_index': segmentIndex,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null) 'speed': speed,
      if (timestamp != null) 'timestamp': timestamp,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GpsPointTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? deliveryId,
      Value<int>? segmentIndex,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<double>? accuracy,
      Value<double?>? speed,
      Value<int>? timestamp,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt}) {
    return GpsPointTableCompanion(
      id: id ?? this.id,
      deliveryId: deliveryId ?? this.deliveryId,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deliveryId.present) {
      map['delivery_id'] = Variable<int>(deliveryId.value);
    }
    if (segmentIndex.present) {
      map['segment_index'] = Variable<int>(segmentIndex.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GpsPointTableCompanion(')
          ..write('id: $id, ')
          ..write('deliveryId: $deliveryId, ')
          ..write('segmentIndex: $segmentIndex, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('speed: $speed, ')
          ..write('timestamp: $timestamp, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PricingTableTable pricingTable = $PricingTableTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final $X5SettingsTableTable x5SettingsTable =
      $X5SettingsTableTable(this);
  late final $ShiftTableTable shiftTable = $ShiftTableTable(this);
  late final $OrderTableTable orderTable = $OrderTableTable(this);
  late final $DeliveryTableTable deliveryTable = $DeliveryTableTable(this);
  late final $GpsPointTableTable gpsPointTable = $GpsPointTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        pricingTable,
        settingsTable,
        x5SettingsTable,
        shiftTable,
        orderTable,
        deliveryTable,
        gpsPointTable
      ];
}

typedef $$PricingTableTableCreateCompanionBuilder = PricingTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  Value<double> receivingFee,
  Value<double> deliveryFee,
  Value<double> pricePerKg,
  Value<double> pricePerKm,
  Value<double> baseCoefficient,
  Value<String> name,
  Value<bool> isActive,
  Value<bool> isDefault,
  Value<int> version,
  Value<bool> isSynced,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
});
typedef $$PricingTableTableUpdateCompanionBuilder = PricingTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  Value<double> receivingFee,
  Value<double> deliveryFee,
  Value<double> pricePerKg,
  Value<double> pricePerKm,
  Value<double> baseCoefficient,
  Value<String> name,
  Value<bool> isActive,
  Value<bool> isDefault,
  Value<int> version,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
});

class $$PricingTableTableFilterComposer
    extends Composer<_$AppDatabase, $PricingTableTable> {
  $$PricingTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get receivingFee => $composableBuilder(
      column: $table.receivingFee, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get deliveryFee => $composableBuilder(
      column: $table.deliveryFee, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pricePerKg => $composableBuilder(
      column: $table.pricePerKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pricePerKm => $composableBuilder(
      column: $table.pricePerKm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get baseCoefficient => $composableBuilder(
      column: $table.baseCoefficient,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PricingTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PricingTableTable> {
  $$PricingTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get receivingFee => $composableBuilder(
      column: $table.receivingFee,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get deliveryFee => $composableBuilder(
      column: $table.deliveryFee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pricePerKg => $composableBuilder(
      column: $table.pricePerKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pricePerKm => $composableBuilder(
      column: $table.pricePerKm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get baseCoefficient => $composableBuilder(
      column: $table.baseCoefficient,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PricingTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PricingTableTable> {
  $$PricingTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<double> get receivingFee => $composableBuilder(
      column: $table.receivingFee, builder: (column) => column);

  GeneratedColumn<double> get deliveryFee => $composableBuilder(
      column: $table.deliveryFee, builder: (column) => column);

  GeneratedColumn<double> get pricePerKg => $composableBuilder(
      column: $table.pricePerKg, builder: (column) => column);

  GeneratedColumn<double> get pricePerKm => $composableBuilder(
      column: $table.pricePerKm, builder: (column) => column);

  GeneratedColumn<double> get baseCoefficient => $composableBuilder(
      column: $table.baseCoefficient, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PricingTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PricingTableTable,
    PricingTableData,
    $$PricingTableTableFilterComposer,
    $$PricingTableTableOrderingComposer,
    $$PricingTableTableAnnotationComposer,
    $$PricingTableTableCreateCompanionBuilder,
    $$PricingTableTableUpdateCompanionBuilder,
    (
      PricingTableData,
      BaseReferences<_$AppDatabase, $PricingTableTable, PricingTableData>
    ),
    PricingTableData,
    PrefetchHooks Function()> {
  $$PricingTableTableTableManager(_$AppDatabase db, $PricingTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PricingTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PricingTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PricingTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<double> receivingFee = const Value.absent(),
            Value<double> deliveryFee = const Value.absent(),
            Value<double> pricePerKg = const Value.absent(),
            Value<double> pricePerKm = const Value.absent(),
            Value<double> baseCoefficient = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              PricingTableCompanion(
            id: id,
            serverId: serverId,
            receivingFee: receivingFee,
            deliveryFee: deliveryFee,
            pricePerKg: pricePerKg,
            pricePerKm: pricePerKm,
            baseCoefficient: baseCoefficient,
            name: name,
            isActive: isActive,
            isDefault: isDefault,
            version: version,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<double> receivingFee = const Value.absent(),
            Value<double> deliveryFee = const Value.absent(),
            Value<double> pricePerKg = const Value.absent(),
            Value<double> pricePerKm = const Value.absent(),
            Value<double> baseCoefficient = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              PricingTableCompanion.insert(
            id: id,
            serverId: serverId,
            receivingFee: receivingFee,
            deliveryFee: deliveryFee,
            pricePerKg: pricePerKg,
            pricePerKm: pricePerKm,
            baseCoefficient: baseCoefficient,
            name: name,
            isActive: isActive,
            isDefault: isDefault,
            version: version,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PricingTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PricingTableTable,
    PricingTableData,
    $$PricingTableTableFilterComposer,
    $$PricingTableTableOrderingComposer,
    $$PricingTableTableAnnotationComposer,
    $$PricingTableTableCreateCompanionBuilder,
    $$PricingTableTableUpdateCompanionBuilder,
    (
      PricingTableData,
      BaseReferences<_$AppDatabase, $PricingTableTable, PricingTableData>
    ),
    PricingTableData,
    PrefetchHooks Function()>;
typedef $$SettingsTableTableCreateCompanionBuilder = SettingsTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  Value<double> fuelConsumption,
  Value<double> fuelPrice,
  Value<double> repairCost,
  Value<double> additionalCosts,
  Value<String> name,
  Value<bool> isActive,
  Value<bool> isDefault,
  Value<int> version,
  Value<bool> isSynced,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
});
typedef $$SettingsTableTableUpdateCompanionBuilder = SettingsTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  Value<double> fuelConsumption,
  Value<double> fuelPrice,
  Value<double> repairCost,
  Value<double> additionalCosts,
  Value<String> name,
  Value<bool> isActive,
  Value<bool> isDefault,
  Value<int> version,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
});

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fuelConsumption => $composableBuilder(
      column: $table.fuelConsumption,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fuelPrice => $composableBuilder(
      column: $table.fuelPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get repairCost => $composableBuilder(
      column: $table.repairCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get additionalCosts => $composableBuilder(
      column: $table.additionalCosts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fuelConsumption => $composableBuilder(
      column: $table.fuelConsumption,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fuelPrice => $composableBuilder(
      column: $table.fuelPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get repairCost => $composableBuilder(
      column: $table.repairCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get additionalCosts => $composableBuilder(
      column: $table.additionalCosts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<double> get fuelConsumption => $composableBuilder(
      column: $table.fuelConsumption, builder: (column) => column);

  GeneratedColumn<double> get fuelPrice =>
      $composableBuilder(column: $table.fuelPrice, builder: (column) => column);

  GeneratedColumn<double> get repairCost => $composableBuilder(
      column: $table.repairCost, builder: (column) => column);

  GeneratedColumn<double> get additionalCosts => $composableBuilder(
      column: $table.additionalCosts, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsTableData,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsTableData,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>
    ),
    SettingsTableData,
    PrefetchHooks Function()> {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<double> fuelConsumption = const Value.absent(),
            Value<double> fuelPrice = const Value.absent(),
            Value<double> repairCost = const Value.absent(),
            Value<double> additionalCosts = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              SettingsTableCompanion(
            id: id,
            serverId: serverId,
            fuelConsumption: fuelConsumption,
            fuelPrice: fuelPrice,
            repairCost: repairCost,
            additionalCosts: additionalCosts,
            name: name,
            isActive: isActive,
            isDefault: isDefault,
            version: version,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<double> fuelConsumption = const Value.absent(),
            Value<double> fuelPrice = const Value.absent(),
            Value<double> repairCost = const Value.absent(),
            Value<double> additionalCosts = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              SettingsTableCompanion.insert(
            id: id,
            serverId: serverId,
            fuelConsumption: fuelConsumption,
            fuelPrice: fuelPrice,
            repairCost: repairCost,
            additionalCosts: additionalCosts,
            name: name,
            isActive: isActive,
            isDefault: isDefault,
            version: version,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsTableData,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsTableData,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>
    ),
    SettingsTableData,
    PrefetchHooks Function()>;
typedef $$X5SettingsTableTableCreateCompanionBuilder = X5SettingsTableCompanion
    Function({
  Value<int> id,
  Value<double> pickupPrice,
  Value<double> deliveryPrice,
  Value<double> perKmPrice,
  Value<double> perKgPrice,
  Value<bool> isDefault,
  Value<bool> isActive,
  Value<bool> isSynced,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
});
typedef $$X5SettingsTableTableUpdateCompanionBuilder = X5SettingsTableCompanion
    Function({
  Value<int> id,
  Value<double> pickupPrice,
  Value<double> deliveryPrice,
  Value<double> perKmPrice,
  Value<double> perKgPrice,
  Value<bool> isDefault,
  Value<bool> isActive,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
});

class $$X5SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $X5SettingsTableTable> {
  $$X5SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pickupPrice => $composableBuilder(
      column: $table.pickupPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get deliveryPrice => $composableBuilder(
      column: $table.deliveryPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get perKmPrice => $composableBuilder(
      column: $table.perKmPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get perKgPrice => $composableBuilder(
      column: $table.perKgPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$X5SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $X5SettingsTableTable> {
  $$X5SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pickupPrice => $composableBuilder(
      column: $table.pickupPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get deliveryPrice => $composableBuilder(
      column: $table.deliveryPrice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get perKmPrice => $composableBuilder(
      column: $table.perKmPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get perKgPrice => $composableBuilder(
      column: $table.perKgPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$X5SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $X5SettingsTableTable> {
  $$X5SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get pickupPrice => $composableBuilder(
      column: $table.pickupPrice, builder: (column) => column);

  GeneratedColumn<double> get deliveryPrice => $composableBuilder(
      column: $table.deliveryPrice, builder: (column) => column);

  GeneratedColumn<double> get perKmPrice => $composableBuilder(
      column: $table.perKmPrice, builder: (column) => column);

  GeneratedColumn<double> get perKgPrice => $composableBuilder(
      column: $table.perKgPrice, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$X5SettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $X5SettingsTableTable,
    X5SettingsTableData,
    $$X5SettingsTableTableFilterComposer,
    $$X5SettingsTableTableOrderingComposer,
    $$X5SettingsTableTableAnnotationComposer,
    $$X5SettingsTableTableCreateCompanionBuilder,
    $$X5SettingsTableTableUpdateCompanionBuilder,
    (
      X5SettingsTableData,
      BaseReferences<_$AppDatabase, $X5SettingsTableTable, X5SettingsTableData>
    ),
    X5SettingsTableData,
    PrefetchHooks Function()> {
  $$X5SettingsTableTableTableManager(
      _$AppDatabase db, $X5SettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$X5SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$X5SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$X5SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> pickupPrice = const Value.absent(),
            Value<double> deliveryPrice = const Value.absent(),
            Value<double> perKmPrice = const Value.absent(),
            Value<double> perKgPrice = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              X5SettingsTableCompanion(
            id: id,
            pickupPrice: pickupPrice,
            deliveryPrice: deliveryPrice,
            perKmPrice: perKmPrice,
            perKgPrice: perKgPrice,
            isDefault: isDefault,
            isActive: isActive,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> pickupPrice = const Value.absent(),
            Value<double> deliveryPrice = const Value.absent(),
            Value<double> perKmPrice = const Value.absent(),
            Value<double> perKgPrice = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              X5SettingsTableCompanion.insert(
            id: id,
            pickupPrice: pickupPrice,
            deliveryPrice: deliveryPrice,
            perKmPrice: perKmPrice,
            perKgPrice: perKgPrice,
            isDefault: isDefault,
            isActive: isActive,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$X5SettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $X5SettingsTableTable,
    X5SettingsTableData,
    $$X5SettingsTableTableFilterComposer,
    $$X5SettingsTableTableOrderingComposer,
    $$X5SettingsTableTableAnnotationComposer,
    $$X5SettingsTableTableCreateCompanionBuilder,
    $$X5SettingsTableTableUpdateCompanionBuilder,
    (
      X5SettingsTableData,
      BaseReferences<_$AppDatabase, $X5SettingsTableTable, X5SettingsTableData>
    ),
    X5SettingsTableData,
    PrefetchHooks Function()>;
typedef $$ShiftTableTableCreateCompanionBuilder = ShiftTableCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  required String startTime,
  Value<String?> endTime,
  Value<int> durationSeconds,
  Value<double> totalPaidDistance,
  Value<double> totalIdleDistance,
  Value<int> ordersCount,
  Value<double> totalIncome,
  Value<double> totalExpenses,
  Value<double> netProfit,
  Value<String> status,
  Value<bool> isSynced,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
});
typedef $$ShiftTableTableUpdateCompanionBuilder = ShiftTableCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<String> startTime,
  Value<String?> endTime,
  Value<int> durationSeconds,
  Value<double> totalPaidDistance,
  Value<double> totalIdleDistance,
  Value<int> ordersCount,
  Value<double> totalIncome,
  Value<double> totalExpenses,
  Value<double> netProfit,
  Value<String> status,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
});

class $$ShiftTableTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftTableTable> {
  $$ShiftTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalPaidDistance => $composableBuilder(
      column: $table.totalPaidDistance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalIdleDistance => $composableBuilder(
      column: $table.totalIdleDistance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ordersCount => $composableBuilder(
      column: $table.ordersCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalIncome => $composableBuilder(
      column: $table.totalIncome, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalExpenses => $composableBuilder(
      column: $table.totalExpenses, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get netProfit => $composableBuilder(
      column: $table.netProfit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ShiftTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftTableTable> {
  $$ShiftTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalPaidDistance => $composableBuilder(
      column: $table.totalPaidDistance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalIdleDistance => $composableBuilder(
      column: $table.totalIdleDistance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ordersCount => $composableBuilder(
      column: $table.ordersCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalIncome => $composableBuilder(
      column: $table.totalIncome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalExpenses => $composableBuilder(
      column: $table.totalExpenses,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get netProfit => $composableBuilder(
      column: $table.netProfit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ShiftTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftTableTable> {
  $$ShiftTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<double> get totalPaidDistance => $composableBuilder(
      column: $table.totalPaidDistance, builder: (column) => column);

  GeneratedColumn<double> get totalIdleDistance => $composableBuilder(
      column: $table.totalIdleDistance, builder: (column) => column);

  GeneratedColumn<int> get ordersCount => $composableBuilder(
      column: $table.ordersCount, builder: (column) => column);

  GeneratedColumn<double> get totalIncome => $composableBuilder(
      column: $table.totalIncome, builder: (column) => column);

  GeneratedColumn<double> get totalExpenses => $composableBuilder(
      column: $table.totalExpenses, builder: (column) => column);

  GeneratedColumn<double> get netProfit =>
      $composableBuilder(column: $table.netProfit, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ShiftTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShiftTableTable,
    ShiftTableData,
    $$ShiftTableTableFilterComposer,
    $$ShiftTableTableOrderingComposer,
    $$ShiftTableTableAnnotationComposer,
    $$ShiftTableTableCreateCompanionBuilder,
    $$ShiftTableTableUpdateCompanionBuilder,
    (
      ShiftTableData,
      BaseReferences<_$AppDatabase, $ShiftTableTable, ShiftTableData>
    ),
    ShiftTableData,
    PrefetchHooks Function()> {
  $$ShiftTableTableTableManager(_$AppDatabase db, $ShiftTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<String> startTime = const Value.absent(),
            Value<String?> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double> totalPaidDistance = const Value.absent(),
            Value<double> totalIdleDistance = const Value.absent(),
            Value<int> ordersCount = const Value.absent(),
            Value<double> totalIncome = const Value.absent(),
            Value<double> totalExpenses = const Value.absent(),
            Value<double> netProfit = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              ShiftTableCompanion(
            id: id,
            serverId: serverId,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            totalPaidDistance: totalPaidDistance,
            totalIdleDistance: totalIdleDistance,
            ordersCount: ordersCount,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netProfit: netProfit,
            status: status,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            required String startTime,
            Value<String?> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double> totalPaidDistance = const Value.absent(),
            Value<double> totalIdleDistance = const Value.absent(),
            Value<int> ordersCount = const Value.absent(),
            Value<double> totalIncome = const Value.absent(),
            Value<double> totalExpenses = const Value.absent(),
            Value<double> netProfit = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              ShiftTableCompanion.insert(
            id: id,
            serverId: serverId,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            totalPaidDistance: totalPaidDistance,
            totalIdleDistance: totalIdleDistance,
            ordersCount: ordersCount,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netProfit: netProfit,
            status: status,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShiftTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShiftTableTable,
    ShiftTableData,
    $$ShiftTableTableFilterComposer,
    $$ShiftTableTableOrderingComposer,
    $$ShiftTableTableAnnotationComposer,
    $$ShiftTableTableCreateCompanionBuilder,
    $$ShiftTableTableUpdateCompanionBuilder,
    (
      ShiftTableData,
      BaseReferences<_$AppDatabase, $ShiftTableTable, ShiftTableData>
    ),
    ShiftTableData,
    PrefetchHooks Function()>;
typedef $$OrderTableTableCreateCompanionBuilder = OrderTableCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<int?> shiftId,
  Value<int?> deliveryNumber,
  Value<double?> coefficient,
  Value<String?> serviceName,
  Value<String> status,
  Value<bool> isSynced,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
});
typedef $$OrderTableTableUpdateCompanionBuilder = OrderTableCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<int?> shiftId,
  Value<int?> deliveryNumber,
  Value<double?> coefficient,
  Value<String?> serviceName,
  Value<String> status,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
});

class $$OrderTableTableFilterComposer
    extends Composer<_$AppDatabase, $OrderTableTable> {
  $$OrderTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shiftId => $composableBuilder(
      column: $table.shiftId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deliveryNumber => $composableBuilder(
      column: $table.deliveryNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get coefficient => $composableBuilder(
      column: $table.coefficient, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serviceName => $composableBuilder(
      column: $table.serviceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OrderTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderTableTable> {
  $$OrderTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shiftId => $composableBuilder(
      column: $table.shiftId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deliveryNumber => $composableBuilder(
      column: $table.deliveryNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get coefficient => $composableBuilder(
      column: $table.coefficient, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serviceName => $composableBuilder(
      column: $table.serviceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OrderTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderTableTable> {
  $$OrderTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<int> get deliveryNumber => $composableBuilder(
      column: $table.deliveryNumber, builder: (column) => column);

  GeneratedColumn<double> get coefficient => $composableBuilder(
      column: $table.coefficient, builder: (column) => column);

  GeneratedColumn<String> get serviceName => $composableBuilder(
      column: $table.serviceName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OrderTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrderTableTable,
    OrderTableData,
    $$OrderTableTableFilterComposer,
    $$OrderTableTableOrderingComposer,
    $$OrderTableTableAnnotationComposer,
    $$OrderTableTableCreateCompanionBuilder,
    $$OrderTableTableUpdateCompanionBuilder,
    (
      OrderTableData,
      BaseReferences<_$AppDatabase, $OrderTableTable, OrderTableData>
    ),
    OrderTableData,
    PrefetchHooks Function()> {
  $$OrderTableTableTableManager(_$AppDatabase db, $OrderTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<int?> shiftId = const Value.absent(),
            Value<int?> deliveryNumber = const Value.absent(),
            Value<double?> coefficient = const Value.absent(),
            Value<String?> serviceName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              OrderTableCompanion(
            id: id,
            serverId: serverId,
            shiftId: shiftId,
            deliveryNumber: deliveryNumber,
            coefficient: coefficient,
            serviceName: serviceName,
            status: status,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<int?> shiftId = const Value.absent(),
            Value<int?> deliveryNumber = const Value.absent(),
            Value<double?> coefficient = const Value.absent(),
            Value<String?> serviceName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              OrderTableCompanion.insert(
            id: id,
            serverId: serverId,
            shiftId: shiftId,
            deliveryNumber: deliveryNumber,
            coefficient: coefficient,
            serviceName: serviceName,
            status: status,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OrderTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrderTableTable,
    OrderTableData,
    $$OrderTableTableFilterComposer,
    $$OrderTableTableOrderingComposer,
    $$OrderTableTableAnnotationComposer,
    $$OrderTableTableCreateCompanionBuilder,
    $$OrderTableTableUpdateCompanionBuilder,
    (
      OrderTableData,
      BaseReferences<_$AppDatabase, $OrderTableTable, OrderTableData>
    ),
    OrderTableData,
    PrefetchHooks Function()>;
typedef $$DeliveryTableTableCreateCompanionBuilder = DeliveryTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  Value<int?> orderId,
  required int number,
  required String clientAddress,
  required String apartment,
  required double weight,
  Value<int> timeToShop,
  Value<double> distanceToShop,
  Value<int> timeReceiving,
  Value<int> timeToClient,
  Value<double> distanceToClient,
  Value<int> timeDelivery,
  Value<String> status,
  Value<bool> isSynced,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
});
typedef $$DeliveryTableTableUpdateCompanionBuilder = DeliveryTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  Value<int?> orderId,
  Value<int> number,
  Value<String> clientAddress,
  Value<String> apartment,
  Value<double> weight,
  Value<int> timeToShop,
  Value<double> distanceToShop,
  Value<int> timeReceiving,
  Value<int> timeToClient,
  Value<double> distanceToClient,
  Value<int> timeDelivery,
  Value<String> status,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
});

class $$DeliveryTableTableFilterComposer
    extends Composer<_$AppDatabase, $DeliveryTableTable> {
  $$DeliveryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientAddress => $composableBuilder(
      column: $table.clientAddress, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get apartment => $composableBuilder(
      column: $table.apartment, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeToShop => $composableBuilder(
      column: $table.timeToShop, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceToShop => $composableBuilder(
      column: $table.distanceToShop,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeReceiving => $composableBuilder(
      column: $table.timeReceiving, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeToClient => $composableBuilder(
      column: $table.timeToClient, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceToClient => $composableBuilder(
      column: $table.distanceToClient,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeDelivery => $composableBuilder(
      column: $table.timeDelivery, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DeliveryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DeliveryTableTable> {
  $$DeliveryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientAddress => $composableBuilder(
      column: $table.clientAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apartment => $composableBuilder(
      column: $table.apartment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeToShop => $composableBuilder(
      column: $table.timeToShop, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceToShop => $composableBuilder(
      column: $table.distanceToShop,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeReceiving => $composableBuilder(
      column: $table.timeReceiving,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeToClient => $composableBuilder(
      column: $table.timeToClient,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceToClient => $composableBuilder(
      column: $table.distanceToClient,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeDelivery => $composableBuilder(
      column: $table.timeDelivery,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DeliveryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeliveryTableTable> {
  $$DeliveryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get clientAddress => $composableBuilder(
      column: $table.clientAddress, builder: (column) => column);

  GeneratedColumn<String> get apartment =>
      $composableBuilder(column: $table.apartment, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get timeToShop => $composableBuilder(
      column: $table.timeToShop, builder: (column) => column);

  GeneratedColumn<double> get distanceToShop => $composableBuilder(
      column: $table.distanceToShop, builder: (column) => column);

  GeneratedColumn<int> get timeReceiving => $composableBuilder(
      column: $table.timeReceiving, builder: (column) => column);

  GeneratedColumn<int> get timeToClient => $composableBuilder(
      column: $table.timeToClient, builder: (column) => column);

  GeneratedColumn<double> get distanceToClient => $composableBuilder(
      column: $table.distanceToClient, builder: (column) => column);

  GeneratedColumn<int> get timeDelivery => $composableBuilder(
      column: $table.timeDelivery, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DeliveryTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeliveryTableTable,
    DeliveryTableData,
    $$DeliveryTableTableFilterComposer,
    $$DeliveryTableTableOrderingComposer,
    $$DeliveryTableTableAnnotationComposer,
    $$DeliveryTableTableCreateCompanionBuilder,
    $$DeliveryTableTableUpdateCompanionBuilder,
    (
      DeliveryTableData,
      BaseReferences<_$AppDatabase, $DeliveryTableTable, DeliveryTableData>
    ),
    DeliveryTableData,
    PrefetchHooks Function()> {
  $$DeliveryTableTableTableManager(_$AppDatabase db, $DeliveryTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeliveryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeliveryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeliveryTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<int?> orderId = const Value.absent(),
            Value<int> number = const Value.absent(),
            Value<String> clientAddress = const Value.absent(),
            Value<String> apartment = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<int> timeToShop = const Value.absent(),
            Value<double> distanceToShop = const Value.absent(),
            Value<int> timeReceiving = const Value.absent(),
            Value<int> timeToClient = const Value.absent(),
            Value<double> distanceToClient = const Value.absent(),
            Value<int> timeDelivery = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              DeliveryTableCompanion(
            id: id,
            serverId: serverId,
            orderId: orderId,
            number: number,
            clientAddress: clientAddress,
            apartment: apartment,
            weight: weight,
            timeToShop: timeToShop,
            distanceToShop: distanceToShop,
            timeReceiving: timeReceiving,
            timeToClient: timeToClient,
            distanceToClient: distanceToClient,
            timeDelivery: timeDelivery,
            status: status,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<int?> orderId = const Value.absent(),
            required int number,
            required String clientAddress,
            required String apartment,
            required double weight,
            Value<int> timeToShop = const Value.absent(),
            Value<double> distanceToShop = const Value.absent(),
            Value<int> timeReceiving = const Value.absent(),
            Value<int> timeToClient = const Value.absent(),
            Value<double> distanceToClient = const Value.absent(),
            Value<int> timeDelivery = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              DeliveryTableCompanion.insert(
            id: id,
            serverId: serverId,
            orderId: orderId,
            number: number,
            clientAddress: clientAddress,
            apartment: apartment,
            weight: weight,
            timeToShop: timeToShop,
            distanceToShop: distanceToShop,
            timeReceiving: timeReceiving,
            timeToClient: timeToClient,
            distanceToClient: distanceToClient,
            timeDelivery: timeDelivery,
            status: status,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DeliveryTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DeliveryTableTable,
    DeliveryTableData,
    $$DeliveryTableTableFilterComposer,
    $$DeliveryTableTableOrderingComposer,
    $$DeliveryTableTableAnnotationComposer,
    $$DeliveryTableTableCreateCompanionBuilder,
    $$DeliveryTableTableUpdateCompanionBuilder,
    (
      DeliveryTableData,
      BaseReferences<_$AppDatabase, $DeliveryTableTable, DeliveryTableData>
    ),
    DeliveryTableData,
    PrefetchHooks Function()>;
typedef $$GpsPointTableTableCreateCompanionBuilder = GpsPointTableCompanion
    Function({
  Value<int> id,
  Value<int?> deliveryId,
  required int segmentIndex,
  required double latitude,
  required double longitude,
  required double accuracy,
  Value<double?> speed,
  required int timestamp,
  Value<bool> isSynced,
  required DateTime createdAt,
});
typedef $$GpsPointTableTableUpdateCompanionBuilder = GpsPointTableCompanion
    Function({
  Value<int> id,
  Value<int?> deliveryId,
  Value<int> segmentIndex,
  Value<double> latitude,
  Value<double> longitude,
  Value<double> accuracy,
  Value<double?> speed,
  Value<int> timestamp,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
});

class $$GpsPointTableTableFilterComposer
    extends Composer<_$AppDatabase, $GpsPointTableTable> {
  $$GpsPointTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deliveryId => $composableBuilder(
      column: $table.deliveryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get segmentIndex => $composableBuilder(
      column: $table.segmentIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$GpsPointTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GpsPointTableTable> {
  $$GpsPointTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deliveryId => $composableBuilder(
      column: $table.deliveryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get segmentIndex => $composableBuilder(
      column: $table.segmentIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$GpsPointTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GpsPointTableTable> {
  $$GpsPointTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get deliveryId => $composableBuilder(
      column: $table.deliveryId, builder: (column) => column);

  GeneratedColumn<int> get segmentIndex => $composableBuilder(
      column: $table.segmentIndex, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GpsPointTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GpsPointTableTable,
    GpsPointTableData,
    $$GpsPointTableTableFilterComposer,
    $$GpsPointTableTableOrderingComposer,
    $$GpsPointTableTableAnnotationComposer,
    $$GpsPointTableTableCreateCompanionBuilder,
    $$GpsPointTableTableUpdateCompanionBuilder,
    (
      GpsPointTableData,
      BaseReferences<_$AppDatabase, $GpsPointTableTable, GpsPointTableData>
    ),
    GpsPointTableData,
    PrefetchHooks Function()> {
  $$GpsPointTableTableTableManager(_$AppDatabase db, $GpsPointTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GpsPointTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GpsPointTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GpsPointTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> deliveryId = const Value.absent(),
            Value<int> segmentIndex = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<double> accuracy = const Value.absent(),
            Value<double?> speed = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GpsPointTableCompanion(
            id: id,
            deliveryId: deliveryId,
            segmentIndex: segmentIndex,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            speed: speed,
            timestamp: timestamp,
            isSynced: isSynced,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> deliveryId = const Value.absent(),
            required int segmentIndex,
            required double latitude,
            required double longitude,
            required double accuracy,
            Value<double?> speed = const Value.absent(),
            required int timestamp,
            Value<bool> isSynced = const Value.absent(),
            required DateTime createdAt,
          }) =>
              GpsPointTableCompanion.insert(
            id: id,
            deliveryId: deliveryId,
            segmentIndex: segmentIndex,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            speed: speed,
            timestamp: timestamp,
            isSynced: isSynced,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GpsPointTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GpsPointTableTable,
    GpsPointTableData,
    $$GpsPointTableTableFilterComposer,
    $$GpsPointTableTableOrderingComposer,
    $$GpsPointTableTableAnnotationComposer,
    $$GpsPointTableTableCreateCompanionBuilder,
    $$GpsPointTableTableUpdateCompanionBuilder,
    (
      GpsPointTableData,
      BaseReferences<_$AppDatabase, $GpsPointTableTable, GpsPointTableData>
    ),
    GpsPointTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PricingTableTableTableManager get pricingTable =>
      $$PricingTableTableTableManager(_db, _db.pricingTable);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
  $$X5SettingsTableTableTableManager get x5SettingsTable =>
      $$X5SettingsTableTableTableManager(_db, _db.x5SettingsTable);
  $$ShiftTableTableTableManager get shiftTable =>
      $$ShiftTableTableTableManager(_db, _db.shiftTable);
  $$OrderTableTableTableManager get orderTable =>
      $$OrderTableTableTableManager(_db, _db.orderTable);
  $$DeliveryTableTableTableManager get deliveryTable =>
      $$DeliveryTableTableTableManager(_db, _db.deliveryTable);
  $$GpsPointTableTableTableManager get gpsPointTable =>
      $$GpsPointTableTableTableManager(_db, _db.gpsPointTable);
}
