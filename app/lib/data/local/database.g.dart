// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meshSizeMeta = const VerificationMeta(
    'meshSize',
  );
  @override
  late final GeneratedColumn<String> meshSize = GeneratedColumn<String>(
    'mesh_size',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    meshSize,
    category,
    sortOrder,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mesh_size')) {
      context.handle(
        _meshSizeMeta,
        meshSize.isAcceptableOrUnknown(data['mesh_size']!, _meshSizeMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      meshSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mesh_size'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String code;
  final String name;
  final String? meshSize;
  final String category;
  final int sortOrder;
  final bool isActive;
  const Product({
    required this.id,
    required this.code,
    required this.name,
    this.meshSize,
    required this.category,
    required this.sortOrder,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || meshSize != null) {
      map['mesh_size'] = Variable<String>(meshSize);
    }
    map['category'] = Variable<String>(category);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      meshSize: meshSize == null && nullToAbsent
          ? const Value.absent()
          : Value(meshSize),
      category: Value(category),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      meshSize: serializer.fromJson<String?>(json['meshSize']),
      category: serializer.fromJson<String>(json['category']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'meshSize': serializer.toJson<String?>(meshSize),
      'category': serializer.toJson<String>(category),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Product copyWith({
    int? id,
    String? code,
    String? name,
    Value<String?> meshSize = const Value.absent(),
    String? category,
    int? sortOrder,
    bool? isActive,
  }) => Product(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    meshSize: meshSize.present ? meshSize.value : this.meshSize,
    category: category ?? this.category,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      meshSize: data.meshSize.present ? data.meshSize.value : this.meshSize,
      category: data.category.present ? data.category.value : this.category,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('meshSize: $meshSize, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, name, meshSize, category, sortOrder, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.meshSize == this.meshSize &&
          other.category == this.category &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String?> meshSize;
  final Value<String> category;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.meshSize = const Value.absent(),
    this.category = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    this.meshSize = const Value.absent(),
    required String category,
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : code = Value(code),
       name = Value(name),
       category = Value(category);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? meshSize,
    Expression<String>? category,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (meshSize != null) 'mesh_size': meshSize,
      if (category != null) 'category': category,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String?>? meshSize,
    Value<String>? category,
    Value<int>? sortOrder,
    Value<bool>? isActive,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      meshSize: meshSize ?? this.meshSize,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (meshSize.present) {
      map['mesh_size'] = Variable<String>(meshSize.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('meshSize: $meshSize, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $LocationsTable extends Locations
    with TableInfo<$LocationsTable, Location> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Asia/Jakarta'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    type,
    address,
    timezone,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Location> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Location map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Location(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $LocationsTable createAlias(String alias) {
    return $LocationsTable(attachedDatabase, alias);
  }
}

class Location extends DataClass implements Insertable<Location> {
  final int id;
  final String code;
  final String name;
  final String type;
  final String? address;
  final String timezone;
  final bool isActive;
  const Location({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.address,
    required this.timezone,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['timezone'] = Variable<String>(timezone);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  LocationsCompanion toCompanion(bool nullToAbsent) {
    return LocationsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      type: Value(type),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      timezone: Value(timezone),
      isActive: Value(isActive),
    );
  }

  factory Location.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Location(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      address: serializer.fromJson<String?>(json['address']),
      timezone: serializer.fromJson<String>(json['timezone']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'address': serializer.toJson<String?>(address),
      'timezone': serializer.toJson<String>(timezone),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Location copyWith({
    int? id,
    String? code,
    String? name,
    String? type,
    Value<String?> address = const Value.absent(),
    String? timezone,
    bool? isActive,
  }) => Location(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    type: type ?? this.type,
    address: address.present ? address.value : this.address,
    timezone: timezone ?? this.timezone,
    isActive: isActive ?? this.isActive,
  );
  Location copyWithCompanion(LocationsCompanion data) {
    return Location(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      address: data.address.present ? data.address.value : this.address,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Location(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('address: $address, ')
          ..write('timezone: $timezone, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, name, type, address, timezone, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Location &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.type == this.type &&
          other.address == this.address &&
          other.timezone == this.timezone &&
          other.isActive == this.isActive);
}

class LocationsCompanion extends UpdateCompanion<Location> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> address;
  final Value<String> timezone;
  final Value<bool> isActive;
  const LocationsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.address = const Value.absent(),
    this.timezone = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  LocationsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    required String type,
    this.address = const Value.absent(),
    this.timezone = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : code = Value(code),
       name = Value(name),
       type = Value(type);
  static Insertable<Location> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? address,
    Expression<String>? timezone,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (address != null) 'address': address,
      if (timezone != null) 'timezone': timezone,
      if (isActive != null) 'is_active': isActive,
    });
  }

  LocationsCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? address,
    Value<String>? timezone,
    Value<bool>? isActive,
  }) {
    return LocationsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      timezone: timezone ?? this.timezone,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('address: $address, ')
          ..write('timezone: $timezone, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $PackagingUnitsTable extends PackagingUnits
    with TableInfo<$PackagingUnitsTable, PackagingUnit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackagingUnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tonPerUnitMeta = const VerificationMeta(
    'tonPerUnit',
  );
  @override
  late final GeneratedColumn<String> tonPerUnit = GeneratedColumn<String>(
    'ton_per_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBulkMeta = const VerificationMeta('isBulk');
  @override
  late final GeneratedColumn<bool> isBulk = GeneratedColumn<bool>(
    'is_bulk',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bulk" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    tonPerUnit,
    isBulk,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'packaging_units';
  @override
  VerificationContext validateIntegrity(
    Insertable<PackagingUnit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ton_per_unit')) {
      context.handle(
        _tonPerUnitMeta,
        tonPerUnit.isAcceptableOrUnknown(
          data['ton_per_unit']!,
          _tonPerUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tonPerUnitMeta);
    }
    if (data.containsKey('is_bulk')) {
      context.handle(
        _isBulkMeta,
        isBulk.isAcceptableOrUnknown(data['is_bulk']!, _isBulkMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PackagingUnit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackagingUnit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      tonPerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ton_per_unit'],
      )!,
      isBulk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bulk'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $PackagingUnitsTable createAlias(String alias) {
    return $PackagingUnitsTable(attachedDatabase, alias);
  }
}

class PackagingUnit extends DataClass implements Insertable<PackagingUnit> {
  final int id;
  final String name;
  final String tonPerUnit;
  final bool isBulk;
  final bool isActive;
  const PackagingUnit({
    required this.id,
    required this.name,
    required this.tonPerUnit,
    required this.isBulk,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['ton_per_unit'] = Variable<String>(tonPerUnit);
    map['is_bulk'] = Variable<bool>(isBulk);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  PackagingUnitsCompanion toCompanion(bool nullToAbsent) {
    return PackagingUnitsCompanion(
      id: Value(id),
      name: Value(name),
      tonPerUnit: Value(tonPerUnit),
      isBulk: Value(isBulk),
      isActive: Value(isActive),
    );
  }

  factory PackagingUnit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackagingUnit(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      tonPerUnit: serializer.fromJson<String>(json['tonPerUnit']),
      isBulk: serializer.fromJson<bool>(json['isBulk']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'tonPerUnit': serializer.toJson<String>(tonPerUnit),
      'isBulk': serializer.toJson<bool>(isBulk),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  PackagingUnit copyWith({
    int? id,
    String? name,
    String? tonPerUnit,
    bool? isBulk,
    bool? isActive,
  }) => PackagingUnit(
    id: id ?? this.id,
    name: name ?? this.name,
    tonPerUnit: tonPerUnit ?? this.tonPerUnit,
    isBulk: isBulk ?? this.isBulk,
    isActive: isActive ?? this.isActive,
  );
  PackagingUnit copyWithCompanion(PackagingUnitsCompanion data) {
    return PackagingUnit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      tonPerUnit: data.tonPerUnit.present
          ? data.tonPerUnit.value
          : this.tonPerUnit,
      isBulk: data.isBulk.present ? data.isBulk.value : this.isBulk,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackagingUnit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tonPerUnit: $tonPerUnit, ')
          ..write('isBulk: $isBulk, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, tonPerUnit, isBulk, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackagingUnit &&
          other.id == this.id &&
          other.name == this.name &&
          other.tonPerUnit == this.tonPerUnit &&
          other.isBulk == this.isBulk &&
          other.isActive == this.isActive);
}

class PackagingUnitsCompanion extends UpdateCompanion<PackagingUnit> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> tonPerUnit;
  final Value<bool> isBulk;
  final Value<bool> isActive;
  const PackagingUnitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.tonPerUnit = const Value.absent(),
    this.isBulk = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  PackagingUnitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String tonPerUnit,
    this.isBulk = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : name = Value(name),
       tonPerUnit = Value(tonPerUnit);
  static Insertable<PackagingUnit> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? tonPerUnit,
    Expression<bool>? isBulk,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (tonPerUnit != null) 'ton_per_unit': tonPerUnit,
      if (isBulk != null) 'is_bulk': isBulk,
      if (isActive != null) 'is_active': isActive,
    });
  }

  PackagingUnitsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? tonPerUnit,
    Value<bool>? isBulk,
    Value<bool>? isActive,
  }) {
    return PackagingUnitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      tonPerUnit: tonPerUnit ?? this.tonPerUnit,
      isBulk: isBulk ?? this.isBulk,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (tonPerUnit.present) {
      map['ton_per_unit'] = Variable<String>(tonPerUnit.value);
    }
    if (isBulk.present) {
      map['is_bulk'] = Variable<bool>(isBulk.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackagingUnitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tonPerUnit: $tonPerUnit, ')
          ..write('isBulk: $isBulk, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $PartnersTable extends Partners with TableInfo<$PartnersTable, Partner> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartnersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    name,
    phone,
    address,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'partners';
  @override
  VerificationContext validateIntegrity(
    Insertable<Partner> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Partner map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Partner(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $PartnersTable createAlias(String alias) {
    return $PartnersTable(attachedDatabase, alias);
  }
}

class Partner extends DataClass implements Insertable<Partner> {
  final int id;
  final String type;
  final String name;
  final String? phone;
  final String? address;
  final bool isActive;
  const Partner({
    required this.id,
    required this.type,
    required this.name,
    this.phone,
    this.address,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  PartnersCompanion toCompanion(bool nullToAbsent) {
    return PartnersCompanion(
      id: Value(id),
      type: Value(type),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      isActive: Value(isActive),
    );
  }

  factory Partner.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Partner(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Partner copyWith({
    int? id,
    String? type,
    String? name,
    Value<String?> phone = const Value.absent(),
    Value<String?> address = const Value.absent(),
    bool? isActive,
  }) => Partner(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    address: address.present ? address.value : this.address,
    isActive: isActive ?? this.isActive,
  );
  Partner copyWithCompanion(PartnersCompanion data) {
    return Partner(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Partner(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, name, phone, address, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Partner &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.isActive == this.isActive);
}

class PartnersCompanion extends UpdateCompanion<Partner> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<bool> isActive;
  const PartnersCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  PartnersCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String name,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : type = Value(type),
       name = Value(name);
  static Insertable<Partner> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (isActive != null) 'is_active': isActive,
    });
  }

  PartnersCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? name,
    Value<String?>? phone,
    Value<String?>? address,
    Value<bool>? isActive,
  }) {
    return PartnersCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartnersCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $VehiclesTable extends Vehicles with TableInfo<$VehiclesTable, Vehicle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plateNumberMeta = const VerificationMeta(
    'plateNumber',
  );
  @override
  late final GeneratedColumn<String> plateNumber = GeneratedColumn<String>(
    'plate_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultDriverMeta = const VerificationMeta(
    'defaultDriver',
  );
  @override
  late final GeneratedColumn<String> defaultDriver = GeneratedColumn<String>(
    'default_driver',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _standardTareTonMeta = const VerificationMeta(
    'standardTareTon',
  );
  @override
  late final GeneratedColumn<String> standardTareTon = GeneratedColumn<String>(
    'standard_tare_ton',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plateNumber,
    defaultDriver,
    standardTareTon,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vehicle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plate_number')) {
      context.handle(
        _plateNumberMeta,
        plateNumber.isAcceptableOrUnknown(
          data['plate_number']!,
          _plateNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plateNumberMeta);
    }
    if (data.containsKey('default_driver')) {
      context.handle(
        _defaultDriverMeta,
        defaultDriver.isAcceptableOrUnknown(
          data['default_driver']!,
          _defaultDriverMeta,
        ),
      );
    }
    if (data.containsKey('standard_tare_ton')) {
      context.handle(
        _standardTareTonMeta,
        standardTareTon.isAcceptableOrUnknown(
          data['standard_tare_ton']!,
          _standardTareTonMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vehicle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vehicle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      plateNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plate_number'],
      )!,
      defaultDriver: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_driver'],
      ),
      standardTareTon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}standard_tare_ton'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }
}

class Vehicle extends DataClass implements Insertable<Vehicle> {
  final int id;
  final String plateNumber;
  final String? defaultDriver;
  final String? standardTareTon;
  final bool isActive;
  const Vehicle({
    required this.id,
    required this.plateNumber,
    this.defaultDriver,
    this.standardTareTon,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plate_number'] = Variable<String>(plateNumber);
    if (!nullToAbsent || defaultDriver != null) {
      map['default_driver'] = Variable<String>(defaultDriver);
    }
    if (!nullToAbsent || standardTareTon != null) {
      map['standard_tare_ton'] = Variable<String>(standardTareTon);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      id: Value(id),
      plateNumber: Value(plateNumber),
      defaultDriver: defaultDriver == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultDriver),
      standardTareTon: standardTareTon == null && nullToAbsent
          ? const Value.absent()
          : Value(standardTareTon),
      isActive: Value(isActive),
    );
  }

  factory Vehicle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vehicle(
      id: serializer.fromJson<int>(json['id']),
      plateNumber: serializer.fromJson<String>(json['plateNumber']),
      defaultDriver: serializer.fromJson<String?>(json['defaultDriver']),
      standardTareTon: serializer.fromJson<String?>(json['standardTareTon']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plateNumber': serializer.toJson<String>(plateNumber),
      'defaultDriver': serializer.toJson<String?>(defaultDriver),
      'standardTareTon': serializer.toJson<String?>(standardTareTon),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Vehicle copyWith({
    int? id,
    String? plateNumber,
    Value<String?> defaultDriver = const Value.absent(),
    Value<String?> standardTareTon = const Value.absent(),
    bool? isActive,
  }) => Vehicle(
    id: id ?? this.id,
    plateNumber: plateNumber ?? this.plateNumber,
    defaultDriver: defaultDriver.present
        ? defaultDriver.value
        : this.defaultDriver,
    standardTareTon: standardTareTon.present
        ? standardTareTon.value
        : this.standardTareTon,
    isActive: isActive ?? this.isActive,
  );
  Vehicle copyWithCompanion(VehiclesCompanion data) {
    return Vehicle(
      id: data.id.present ? data.id.value : this.id,
      plateNumber: data.plateNumber.present
          ? data.plateNumber.value
          : this.plateNumber,
      defaultDriver: data.defaultDriver.present
          ? data.defaultDriver.value
          : this.defaultDriver,
      standardTareTon: data.standardTareTon.present
          ? data.standardTareTon.value
          : this.standardTareTon,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vehicle(')
          ..write('id: $id, ')
          ..write('plateNumber: $plateNumber, ')
          ..write('defaultDriver: $defaultDriver, ')
          ..write('standardTareTon: $standardTareTon, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, plateNumber, defaultDriver, standardTareTon, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vehicle &&
          other.id == this.id &&
          other.plateNumber == this.plateNumber &&
          other.defaultDriver == this.defaultDriver &&
          other.standardTareTon == this.standardTareTon &&
          other.isActive == this.isActive);
}

class VehiclesCompanion extends UpdateCompanion<Vehicle> {
  final Value<int> id;
  final Value<String> plateNumber;
  final Value<String?> defaultDriver;
  final Value<String?> standardTareTon;
  final Value<bool> isActive;
  const VehiclesCompanion({
    this.id = const Value.absent(),
    this.plateNumber = const Value.absent(),
    this.defaultDriver = const Value.absent(),
    this.standardTareTon = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  VehiclesCompanion.insert({
    this.id = const Value.absent(),
    required String plateNumber,
    this.defaultDriver = const Value.absent(),
    this.standardTareTon = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : plateNumber = Value(plateNumber);
  static Insertable<Vehicle> custom({
    Expression<int>? id,
    Expression<String>? plateNumber,
    Expression<String>? defaultDriver,
    Expression<String>? standardTareTon,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plateNumber != null) 'plate_number': plateNumber,
      if (defaultDriver != null) 'default_driver': defaultDriver,
      if (standardTareTon != null) 'standard_tare_ton': standardTareTon,
      if (isActive != null) 'is_active': isActive,
    });
  }

  VehiclesCompanion copyWith({
    Value<int>? id,
    Value<String>? plateNumber,
    Value<String?>? defaultDriver,
    Value<String?>? standardTareTon,
    Value<bool>? isActive,
  }) {
    return VehiclesCompanion(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      defaultDriver: defaultDriver ?? this.defaultDriver,
      standardTareTon: standardTareTon ?? this.standardTareTon,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plateNumber.present) {
      map['plate_number'] = Variable<String>(plateNumber.value);
    }
    if (defaultDriver.present) {
      map['default_driver'] = Variable<String>(defaultDriver.value);
    }
    if (standardTareTon.present) {
      map['standard_tare_ton'] = Variable<String>(standardTareTon.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('id: $id, ')
          ..write('plateNumber: $plateNumber, ')
          ..write('defaultDriver: $defaultDriver, ')
          ..write('standardTareTon: $standardTareTon, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $MinLevelsTable extends MinLevels
    with TableInfo<$MinLevelsTable, MinLevel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MinLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<int> locationId = GeneratedColumn<int>(
    'location_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minTonMeta = const VerificationMeta('minTon');
  @override
  late final GeneratedColumn<String> minTon = GeneratedColumn<String>(
    'min_ton',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [locationId, productId, minTon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'min_levels';
  @override
  VerificationContext validateIntegrity(
    Insertable<MinLevel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_locationIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('min_ton')) {
      context.handle(
        _minTonMeta,
        minTon.isAcceptableOrUnknown(data['min_ton']!, _minTonMeta),
      );
    } else if (isInserting) {
      context.missing(_minTonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {locationId, productId};
  @override
  MinLevel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MinLevel(
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}location_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      minTon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}min_ton'],
      )!,
    );
  }

  @override
  $MinLevelsTable createAlias(String alias) {
    return $MinLevelsTable(attachedDatabase, alias);
  }
}

class MinLevel extends DataClass implements Insertable<MinLevel> {
  final int locationId;
  final int productId;
  final String minTon;
  const MinLevel({
    required this.locationId,
    required this.productId,
    required this.minTon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['location_id'] = Variable<int>(locationId);
    map['product_id'] = Variable<int>(productId);
    map['min_ton'] = Variable<String>(minTon);
    return map;
  }

  MinLevelsCompanion toCompanion(bool nullToAbsent) {
    return MinLevelsCompanion(
      locationId: Value(locationId),
      productId: Value(productId),
      minTon: Value(minTon),
    );
  }

  factory MinLevel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MinLevel(
      locationId: serializer.fromJson<int>(json['locationId']),
      productId: serializer.fromJson<int>(json['productId']),
      minTon: serializer.fromJson<String>(json['minTon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'locationId': serializer.toJson<int>(locationId),
      'productId': serializer.toJson<int>(productId),
      'minTon': serializer.toJson<String>(minTon),
    };
  }

  MinLevel copyWith({int? locationId, int? productId, String? minTon}) =>
      MinLevel(
        locationId: locationId ?? this.locationId,
        productId: productId ?? this.productId,
        minTon: minTon ?? this.minTon,
      );
  MinLevel copyWithCompanion(MinLevelsCompanion data) {
    return MinLevel(
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      productId: data.productId.present ? data.productId.value : this.productId,
      minTon: data.minTon.present ? data.minTon.value : this.minTon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MinLevel(')
          ..write('locationId: $locationId, ')
          ..write('productId: $productId, ')
          ..write('minTon: $minTon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(locationId, productId, minTon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MinLevel &&
          other.locationId == this.locationId &&
          other.productId == this.productId &&
          other.minTon == this.minTon);
}

class MinLevelsCompanion extends UpdateCompanion<MinLevel> {
  final Value<int> locationId;
  final Value<int> productId;
  final Value<String> minTon;
  final Value<int> rowid;
  const MinLevelsCompanion({
    this.locationId = const Value.absent(),
    this.productId = const Value.absent(),
    this.minTon = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MinLevelsCompanion.insert({
    required int locationId,
    required int productId,
    required String minTon,
    this.rowid = const Value.absent(),
  }) : locationId = Value(locationId),
       productId = Value(productId),
       minTon = Value(minTon);
  static Insertable<MinLevel> custom({
    Expression<int>? locationId,
    Expression<int>? productId,
    Expression<String>? minTon,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (locationId != null) 'location_id': locationId,
      if (productId != null) 'product_id': productId,
      if (minTon != null) 'min_ton': minTon,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MinLevelsCompanion copyWith({
    Value<int>? locationId,
    Value<int>? productId,
    Value<String>? minTon,
    Value<int>? rowid,
  }) {
    return MinLevelsCompanion(
      locationId: locationId ?? this.locationId,
      productId: productId ?? this.productId,
      minTon: minTon ?? this.minTon,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (locationId.present) {
      map['location_id'] = Variable<int>(locationId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (minTon.present) {
      map['min_ton'] = Variable<String>(minTon.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MinLevelsCompanion(')
          ..write('locationId: $locationId, ')
          ..write('productId: $productId, ')
          ..write('minTon: $minTon, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BalancesTable extends Balances with TableInfo<$BalancesTable, Balance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BalancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<int> locationId = GeneratedColumn<int>(
    'location_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyTonMeta = const VerificationMeta('qtyTon');
  @override
  late final GeneratedColumn<String> qtyTon = GeneratedColumn<String>(
    'qty_ton',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inTransitTonMeta = const VerificationMeta(
    'inTransitTon',
  );
  @override
  late final GeneratedColumn<String> inTransitTon = GeneratedColumn<String>(
    'in_transit_ton',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    locationId,
    productId,
    qtyTon,
    inTransitTon,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balances';
  @override
  VerificationContext validateIntegrity(
    Insertable<Balance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_locationIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('qty_ton')) {
      context.handle(
        _qtyTonMeta,
        qtyTon.isAcceptableOrUnknown(data['qty_ton']!, _qtyTonMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyTonMeta);
    }
    if (data.containsKey('in_transit_ton')) {
      context.handle(
        _inTransitTonMeta,
        inTransitTon.isAcceptableOrUnknown(
          data['in_transit_ton']!,
          _inTransitTonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {locationId, productId};
  @override
  Balance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Balance(
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}location_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      qtyTon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qty_ton'],
      )!,
      inTransitTon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_transit_ton'],
      )!,
    );
  }

  @override
  $BalancesTable createAlias(String alias) {
    return $BalancesTable(attachedDatabase, alias);
  }
}

class Balance extends DataClass implements Insertable<Balance> {
  final int locationId;
  final int productId;
  final String qtyTon;
  final String inTransitTon;
  const Balance({
    required this.locationId,
    required this.productId,
    required this.qtyTon,
    required this.inTransitTon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['location_id'] = Variable<int>(locationId);
    map['product_id'] = Variable<int>(productId);
    map['qty_ton'] = Variable<String>(qtyTon);
    map['in_transit_ton'] = Variable<String>(inTransitTon);
    return map;
  }

  BalancesCompanion toCompanion(bool nullToAbsent) {
    return BalancesCompanion(
      locationId: Value(locationId),
      productId: Value(productId),
      qtyTon: Value(qtyTon),
      inTransitTon: Value(inTransitTon),
    );
  }

  factory Balance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Balance(
      locationId: serializer.fromJson<int>(json['locationId']),
      productId: serializer.fromJson<int>(json['productId']),
      qtyTon: serializer.fromJson<String>(json['qtyTon']),
      inTransitTon: serializer.fromJson<String>(json['inTransitTon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'locationId': serializer.toJson<int>(locationId),
      'productId': serializer.toJson<int>(productId),
      'qtyTon': serializer.toJson<String>(qtyTon),
      'inTransitTon': serializer.toJson<String>(inTransitTon),
    };
  }

  Balance copyWith({
    int? locationId,
    int? productId,
    String? qtyTon,
    String? inTransitTon,
  }) => Balance(
    locationId: locationId ?? this.locationId,
    productId: productId ?? this.productId,
    qtyTon: qtyTon ?? this.qtyTon,
    inTransitTon: inTransitTon ?? this.inTransitTon,
  );
  Balance copyWithCompanion(BalancesCompanion data) {
    return Balance(
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      productId: data.productId.present ? data.productId.value : this.productId,
      qtyTon: data.qtyTon.present ? data.qtyTon.value : this.qtyTon,
      inTransitTon: data.inTransitTon.present
          ? data.inTransitTon.value
          : this.inTransitTon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Balance(')
          ..write('locationId: $locationId, ')
          ..write('productId: $productId, ')
          ..write('qtyTon: $qtyTon, ')
          ..write('inTransitTon: $inTransitTon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(locationId, productId, qtyTon, inTransitTon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Balance &&
          other.locationId == this.locationId &&
          other.productId == this.productId &&
          other.qtyTon == this.qtyTon &&
          other.inTransitTon == this.inTransitTon);
}

class BalancesCompanion extends UpdateCompanion<Balance> {
  final Value<int> locationId;
  final Value<int> productId;
  final Value<String> qtyTon;
  final Value<String> inTransitTon;
  final Value<int> rowid;
  const BalancesCompanion({
    this.locationId = const Value.absent(),
    this.productId = const Value.absent(),
    this.qtyTon = const Value.absent(),
    this.inTransitTon = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BalancesCompanion.insert({
    required int locationId,
    required int productId,
    required String qtyTon,
    this.inTransitTon = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : locationId = Value(locationId),
       productId = Value(productId),
       qtyTon = Value(qtyTon);
  static Insertable<Balance> custom({
    Expression<int>? locationId,
    Expression<int>? productId,
    Expression<String>? qtyTon,
    Expression<String>? inTransitTon,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (locationId != null) 'location_id': locationId,
      if (productId != null) 'product_id': productId,
      if (qtyTon != null) 'qty_ton': qtyTon,
      if (inTransitTon != null) 'in_transit_ton': inTransitTon,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BalancesCompanion copyWith({
    Value<int>? locationId,
    Value<int>? productId,
    Value<String>? qtyTon,
    Value<String>? inTransitTon,
    Value<int>? rowid,
  }) {
    return BalancesCompanion(
      locationId: locationId ?? this.locationId,
      productId: productId ?? this.productId,
      qtyTon: qtyTon ?? this.qtyTon,
      inTransitTon: inTransitTon ?? this.inTransitTon,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (locationId.present) {
      map['location_id'] = Variable<int>(locationId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (qtyTon.present) {
      map['qty_ton'] = Variable<String>(qtyTon.value);
    }
    if (inTransitTon.present) {
      map['in_transit_ton'] = Variable<String>(inTransitTon.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BalancesCompanion(')
          ..write('locationId: $locationId, ')
          ..write('productId: $productId, ')
          ..write('qtyTon: $qtyTon, ')
          ..write('inTransitTon: $inTransitTon, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTransactionsTable extends LocalTransactions
    with TableInfo<$LocalTransactionsTable, LocalTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trxTypeMeta = const VerificationMeta(
    'trxType',
  );
  @override
  late final GeneratedColumn<String> trxType = GeneratedColumn<String>(
    'trx_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<int> locationId = GeneratedColumn<int>(
    'location_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tmpDocNoMeta = const VerificationMeta(
    'tmpDocNo',
  );
  @override
  late final GeneratedColumn<String> tmpDocNo = GeneratedColumn<String>(
    'tmp_doc_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _docNoMeta = const VerificationMeta('docNo');
  @override
  late final GeneratedColumn<String> docNo = GeneratedColumn<String>(
    'doc_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverStatusMeta = const VerificationMeta(
    'serverStatus',
  );
  @override
  late final GeneratedColumn<String> serverStatus = GeneratedColumn<String>(
    'server_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverJsonMeta = const VerificationMeta(
    'serverJson',
  );
  @override
  late final GeneratedColumn<String> serverJson = GeneratedColumn<String>(
    'server_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncState.pending),
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _clientCreatedAtMeta = const VerificationMeta(
    'clientCreatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientCreatedAt =
      GeneratedColumn<DateTime>(
        'client_created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _trxAtMeta = const VerificationMeta('trxAt');
  @override
  late final GeneratedColumn<DateTime> trxAt = GeneratedColumn<DateTime>(
    'trx_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUploadedMeta = const VerificationMeta(
    'photoUploaded',
  );
  @override
  late final GeneratedColumn<bool> photoUploaded = GeneratedColumn<bool>(
    'photo_uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("photo_uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unreportedPrintsMeta = const VerificationMeta(
    'unreportedPrints',
  );
  @override
  late final GeneratedColumn<int> unreportedPrints = GeneratedColumn<int>(
    'unreported_prints',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _printCountMeta = const VerificationMeta(
    'printCount',
  );
  @override
  late final GeneratedColumn<int> printCount = GeneratedColumn<int>(
    'print_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<int> createdBy = GeneratedColumn<int>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientUuid,
    payload,
    trxType,
    locationId,
    tmpDocNo,
    docNo,
    serverId,
    serverStatus,
    serverJson,
    syncState,
    errorCode,
    errorMessage,
    attempts,
    clientCreatedAt,
    trxAt,
    syncedAt,
    photoPath,
    photoUploaded,
    unreportedPrints,
    printCount,
    createdBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('trx_type')) {
      context.handle(
        _trxTypeMeta,
        trxType.isAcceptableOrUnknown(data['trx_type']!, _trxTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_trxTypeMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_locationIdMeta);
    }
    if (data.containsKey('tmp_doc_no')) {
      context.handle(
        _tmpDocNoMeta,
        tmpDocNo.isAcceptableOrUnknown(data['tmp_doc_no']!, _tmpDocNoMeta),
      );
    } else if (isInserting) {
      context.missing(_tmpDocNoMeta);
    }
    if (data.containsKey('doc_no')) {
      context.handle(
        _docNoMeta,
        docNo.isAcceptableOrUnknown(data['doc_no']!, _docNoMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('server_status')) {
      context.handle(
        _serverStatusMeta,
        serverStatus.isAcceptableOrUnknown(
          data['server_status']!,
          _serverStatusMeta,
        ),
      );
    }
    if (data.containsKey('server_json')) {
      context.handle(
        _serverJsonMeta,
        serverJson.isAcceptableOrUnknown(data['server_json']!, _serverJsonMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('client_created_at')) {
      context.handle(
        _clientCreatedAtMeta,
        clientCreatedAt.isAcceptableOrUnknown(
          data['client_created_at']!,
          _clientCreatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientCreatedAtMeta);
    }
    if (data.containsKey('trx_at')) {
      context.handle(
        _trxAtMeta,
        trxAt.isAcceptableOrUnknown(data['trx_at']!, _trxAtMeta),
      );
    } else if (isInserting) {
      context.missing(_trxAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('photo_uploaded')) {
      context.handle(
        _photoUploadedMeta,
        photoUploaded.isAcceptableOrUnknown(
          data['photo_uploaded']!,
          _photoUploadedMeta,
        ),
      );
    }
    if (data.containsKey('unreported_prints')) {
      context.handle(
        _unreportedPrintsMeta,
        unreportedPrints.isAcceptableOrUnknown(
          data['unreported_prints']!,
          _unreportedPrintsMeta,
        ),
      );
    }
    if (data.containsKey('print_count')) {
      context.handle(
        _printCountMeta,
        printCount.isAcceptableOrUnknown(data['print_count']!, _printCountMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  LocalTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTransaction(
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      trxType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trx_type'],
      )!,
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}location_id'],
      )!,
      tmpDocNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tmp_doc_no'],
      )!,
      docNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_no'],
      ),
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      serverStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_status'],
      ),
      serverJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_json'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      clientCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_created_at'],
      )!,
      trxAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}trx_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      photoUploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}photo_uploaded'],
      )!,
      unreportedPrints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unreported_prints'],
      )!,
      printCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}print_count'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_by'],
      )!,
    );
  }

  @override
  $LocalTransactionsTable createAlias(String alias) {
    return $LocalTransactionsTable(attachedDatabase, alias);
  }
}

class LocalTransaction extends DataClass
    implements Insertable<LocalTransaction> {
  final String clientUuid;

  /// Body request POST /transactions (JSON) — dikirim apa adanya saat sinkron.
  final String payload;
  final String trxType;
  final int locationId;
  final String tmpDocNo;
  final String? docNo;
  final int? serverId;
  final String? serverStatus;

  /// JSON transaksi dari server setelah sinkron (untuk tampilan & cetak ulang offline).
  final String? serverJson;
  final String syncState;
  final String? errorCode;
  final String? errorMessage;
  final int attempts;
  final DateTime clientCreatedAt;
  final DateTime trxAt;
  final DateTime? syncedAt;
  final String? photoPath;
  final bool photoUploaded;

  /// Jumlah cetak yang belum dilaporkan ke server (POST /print).
  final int unreportedPrints;
  final int printCount;
  final int createdBy;
  const LocalTransaction({
    required this.clientUuid,
    required this.payload,
    required this.trxType,
    required this.locationId,
    required this.tmpDocNo,
    this.docNo,
    this.serverId,
    this.serverStatus,
    this.serverJson,
    required this.syncState,
    this.errorCode,
    this.errorMessage,
    required this.attempts,
    required this.clientCreatedAt,
    required this.trxAt,
    this.syncedAt,
    this.photoPath,
    required this.photoUploaded,
    required this.unreportedPrints,
    required this.printCount,
    required this.createdBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    map['payload'] = Variable<String>(payload);
    map['trx_type'] = Variable<String>(trxType);
    map['location_id'] = Variable<int>(locationId);
    map['tmp_doc_no'] = Variable<String>(tmpDocNo);
    if (!nullToAbsent || docNo != null) {
      map['doc_no'] = Variable<String>(docNo);
    }
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || serverStatus != null) {
      map['server_status'] = Variable<String>(serverStatus);
    }
    if (!nullToAbsent || serverJson != null) {
      map['server_json'] = Variable<String>(serverJson);
    }
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['attempts'] = Variable<int>(attempts);
    map['client_created_at'] = Variable<DateTime>(clientCreatedAt);
    map['trx_at'] = Variable<DateTime>(trxAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['photo_uploaded'] = Variable<bool>(photoUploaded);
    map['unreported_prints'] = Variable<int>(unreportedPrints);
    map['print_count'] = Variable<int>(printCount);
    map['created_by'] = Variable<int>(createdBy);
    return map;
  }

  LocalTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalTransactionsCompanion(
      clientUuid: Value(clientUuid),
      payload: Value(payload),
      trxType: Value(trxType),
      locationId: Value(locationId),
      tmpDocNo: Value(tmpDocNo),
      docNo: docNo == null && nullToAbsent
          ? const Value.absent()
          : Value(docNo),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      serverStatus: serverStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(serverStatus),
      serverJson: serverJson == null && nullToAbsent
          ? const Value.absent()
          : Value(serverJson),
      syncState: Value(syncState),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      attempts: Value(attempts),
      clientCreatedAt: Value(clientCreatedAt),
      trxAt: Value(trxAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      photoUploaded: Value(photoUploaded),
      unreportedPrints: Value(unreportedPrints),
      printCount: Value(printCount),
      createdBy: Value(createdBy),
    );
  }

  factory LocalTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTransaction(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      payload: serializer.fromJson<String>(json['payload']),
      trxType: serializer.fromJson<String>(json['trxType']),
      locationId: serializer.fromJson<int>(json['locationId']),
      tmpDocNo: serializer.fromJson<String>(json['tmpDocNo']),
      docNo: serializer.fromJson<String?>(json['docNo']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      serverStatus: serializer.fromJson<String?>(json['serverStatus']),
      serverJson: serializer.fromJson<String?>(json['serverJson']),
      syncState: serializer.fromJson<String>(json['syncState']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      attempts: serializer.fromJson<int>(json['attempts']),
      clientCreatedAt: serializer.fromJson<DateTime>(json['clientCreatedAt']),
      trxAt: serializer.fromJson<DateTime>(json['trxAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      photoUploaded: serializer.fromJson<bool>(json['photoUploaded']),
      unreportedPrints: serializer.fromJson<int>(json['unreportedPrints']),
      printCount: serializer.fromJson<int>(json['printCount']),
      createdBy: serializer.fromJson<int>(json['createdBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'payload': serializer.toJson<String>(payload),
      'trxType': serializer.toJson<String>(trxType),
      'locationId': serializer.toJson<int>(locationId),
      'tmpDocNo': serializer.toJson<String>(tmpDocNo),
      'docNo': serializer.toJson<String?>(docNo),
      'serverId': serializer.toJson<int?>(serverId),
      'serverStatus': serializer.toJson<String?>(serverStatus),
      'serverJson': serializer.toJson<String?>(serverJson),
      'syncState': serializer.toJson<String>(syncState),
      'errorCode': serializer.toJson<String?>(errorCode),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'attempts': serializer.toJson<int>(attempts),
      'clientCreatedAt': serializer.toJson<DateTime>(clientCreatedAt),
      'trxAt': serializer.toJson<DateTime>(trxAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'photoPath': serializer.toJson<String?>(photoPath),
      'photoUploaded': serializer.toJson<bool>(photoUploaded),
      'unreportedPrints': serializer.toJson<int>(unreportedPrints),
      'printCount': serializer.toJson<int>(printCount),
      'createdBy': serializer.toJson<int>(createdBy),
    };
  }

  LocalTransaction copyWith({
    String? clientUuid,
    String? payload,
    String? trxType,
    int? locationId,
    String? tmpDocNo,
    Value<String?> docNo = const Value.absent(),
    Value<int?> serverId = const Value.absent(),
    Value<String?> serverStatus = const Value.absent(),
    Value<String?> serverJson = const Value.absent(),
    String? syncState,
    Value<String?> errorCode = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    int? attempts,
    DateTime? clientCreatedAt,
    DateTime? trxAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    bool? photoUploaded,
    int? unreportedPrints,
    int? printCount,
    int? createdBy,
  }) => LocalTransaction(
    clientUuid: clientUuid ?? this.clientUuid,
    payload: payload ?? this.payload,
    trxType: trxType ?? this.trxType,
    locationId: locationId ?? this.locationId,
    tmpDocNo: tmpDocNo ?? this.tmpDocNo,
    docNo: docNo.present ? docNo.value : this.docNo,
    serverId: serverId.present ? serverId.value : this.serverId,
    serverStatus: serverStatus.present ? serverStatus.value : this.serverStatus,
    serverJson: serverJson.present ? serverJson.value : this.serverJson,
    syncState: syncState ?? this.syncState,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    attempts: attempts ?? this.attempts,
    clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
    trxAt: trxAt ?? this.trxAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    photoUploaded: photoUploaded ?? this.photoUploaded,
    unreportedPrints: unreportedPrints ?? this.unreportedPrints,
    printCount: printCount ?? this.printCount,
    createdBy: createdBy ?? this.createdBy,
  );
  LocalTransaction copyWithCompanion(LocalTransactionsCompanion data) {
    return LocalTransaction(
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      payload: data.payload.present ? data.payload.value : this.payload,
      trxType: data.trxType.present ? data.trxType.value : this.trxType,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      tmpDocNo: data.tmpDocNo.present ? data.tmpDocNo.value : this.tmpDocNo,
      docNo: data.docNo.present ? data.docNo.value : this.docNo,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      serverStatus: data.serverStatus.present
          ? data.serverStatus.value
          : this.serverStatus,
      serverJson: data.serverJson.present
          ? data.serverJson.value
          : this.serverJson,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      clientCreatedAt: data.clientCreatedAt.present
          ? data.clientCreatedAt.value
          : this.clientCreatedAt,
      trxAt: data.trxAt.present ? data.trxAt.value : this.trxAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoUploaded: data.photoUploaded.present
          ? data.photoUploaded.value
          : this.photoUploaded,
      unreportedPrints: data.unreportedPrints.present
          ? data.unreportedPrints.value
          : this.unreportedPrints,
      printCount: data.printCount.present
          ? data.printCount.value
          : this.printCount,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransaction(')
          ..write('clientUuid: $clientUuid, ')
          ..write('payload: $payload, ')
          ..write('trxType: $trxType, ')
          ..write('locationId: $locationId, ')
          ..write('tmpDocNo: $tmpDocNo, ')
          ..write('docNo: $docNo, ')
          ..write('serverId: $serverId, ')
          ..write('serverStatus: $serverStatus, ')
          ..write('serverJson: $serverJson, ')
          ..write('syncState: $syncState, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('attempts: $attempts, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('trxAt: $trxAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoUploaded: $photoUploaded, ')
          ..write('unreportedPrints: $unreportedPrints, ')
          ..write('printCount: $printCount, ')
          ..write('createdBy: $createdBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    clientUuid,
    payload,
    trxType,
    locationId,
    tmpDocNo,
    docNo,
    serverId,
    serverStatus,
    serverJson,
    syncState,
    errorCode,
    errorMessage,
    attempts,
    clientCreatedAt,
    trxAt,
    syncedAt,
    photoPath,
    photoUploaded,
    unreportedPrints,
    printCount,
    createdBy,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTransaction &&
          other.clientUuid == this.clientUuid &&
          other.payload == this.payload &&
          other.trxType == this.trxType &&
          other.locationId == this.locationId &&
          other.tmpDocNo == this.tmpDocNo &&
          other.docNo == this.docNo &&
          other.serverId == this.serverId &&
          other.serverStatus == this.serverStatus &&
          other.serverJson == this.serverJson &&
          other.syncState == this.syncState &&
          other.errorCode == this.errorCode &&
          other.errorMessage == this.errorMessage &&
          other.attempts == this.attempts &&
          other.clientCreatedAt == this.clientCreatedAt &&
          other.trxAt == this.trxAt &&
          other.syncedAt == this.syncedAt &&
          other.photoPath == this.photoPath &&
          other.photoUploaded == this.photoUploaded &&
          other.unreportedPrints == this.unreportedPrints &&
          other.printCount == this.printCount &&
          other.createdBy == this.createdBy);
}

class LocalTransactionsCompanion extends UpdateCompanion<LocalTransaction> {
  final Value<String> clientUuid;
  final Value<String> payload;
  final Value<String> trxType;
  final Value<int> locationId;
  final Value<String> tmpDocNo;
  final Value<String?> docNo;
  final Value<int?> serverId;
  final Value<String?> serverStatus;
  final Value<String?> serverJson;
  final Value<String> syncState;
  final Value<String?> errorCode;
  final Value<String?> errorMessage;
  final Value<int> attempts;
  final Value<DateTime> clientCreatedAt;
  final Value<DateTime> trxAt;
  final Value<DateTime?> syncedAt;
  final Value<String?> photoPath;
  final Value<bool> photoUploaded;
  final Value<int> unreportedPrints;
  final Value<int> printCount;
  final Value<int> createdBy;
  final Value<int> rowid;
  const LocalTransactionsCompanion({
    this.clientUuid = const Value.absent(),
    this.payload = const Value.absent(),
    this.trxType = const Value.absent(),
    this.locationId = const Value.absent(),
    this.tmpDocNo = const Value.absent(),
    this.docNo = const Value.absent(),
    this.serverId = const Value.absent(),
    this.serverStatus = const Value.absent(),
    this.serverJson = const Value.absent(),
    this.syncState = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.attempts = const Value.absent(),
    this.clientCreatedAt = const Value.absent(),
    this.trxAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoUploaded = const Value.absent(),
    this.unreportedPrints = const Value.absent(),
    this.printCount = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTransactionsCompanion.insert({
    required String clientUuid,
    required String payload,
    required String trxType,
    required int locationId,
    required String tmpDocNo,
    this.docNo = const Value.absent(),
    this.serverId = const Value.absent(),
    this.serverStatus = const Value.absent(),
    this.serverJson = const Value.absent(),
    this.syncState = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.attempts = const Value.absent(),
    required DateTime clientCreatedAt,
    required DateTime trxAt,
    this.syncedAt = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoUploaded = const Value.absent(),
    this.unreportedPrints = const Value.absent(),
    this.printCount = const Value.absent(),
    required int createdBy,
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       payload = Value(payload),
       trxType = Value(trxType),
       locationId = Value(locationId),
       tmpDocNo = Value(tmpDocNo),
       clientCreatedAt = Value(clientCreatedAt),
       trxAt = Value(trxAt),
       createdBy = Value(createdBy);
  static Insertable<LocalTransaction> custom({
    Expression<String>? clientUuid,
    Expression<String>? payload,
    Expression<String>? trxType,
    Expression<int>? locationId,
    Expression<String>? tmpDocNo,
    Expression<String>? docNo,
    Expression<int>? serverId,
    Expression<String>? serverStatus,
    Expression<String>? serverJson,
    Expression<String>? syncState,
    Expression<String>? errorCode,
    Expression<String>? errorMessage,
    Expression<int>? attempts,
    Expression<DateTime>? clientCreatedAt,
    Expression<DateTime>? trxAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? photoPath,
    Expression<bool>? photoUploaded,
    Expression<int>? unreportedPrints,
    Expression<int>? printCount,
    Expression<int>? createdBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (payload != null) 'payload': payload,
      if (trxType != null) 'trx_type': trxType,
      if (locationId != null) 'location_id': locationId,
      if (tmpDocNo != null) 'tmp_doc_no': tmpDocNo,
      if (docNo != null) 'doc_no': docNo,
      if (serverId != null) 'server_id': serverId,
      if (serverStatus != null) 'server_status': serverStatus,
      if (serverJson != null) 'server_json': serverJson,
      if (syncState != null) 'sync_state': syncState,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
      if (attempts != null) 'attempts': attempts,
      if (clientCreatedAt != null) 'client_created_at': clientCreatedAt,
      if (trxAt != null) 'trx_at': trxAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoUploaded != null) 'photo_uploaded': photoUploaded,
      if (unreportedPrints != null) 'unreported_prints': unreportedPrints,
      if (printCount != null) 'print_count': printCount,
      if (createdBy != null) 'created_by': createdBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTransactionsCompanion copyWith({
    Value<String>? clientUuid,
    Value<String>? payload,
    Value<String>? trxType,
    Value<int>? locationId,
    Value<String>? tmpDocNo,
    Value<String?>? docNo,
    Value<int?>? serverId,
    Value<String?>? serverStatus,
    Value<String?>? serverJson,
    Value<String>? syncState,
    Value<String?>? errorCode,
    Value<String?>? errorMessage,
    Value<int>? attempts,
    Value<DateTime>? clientCreatedAt,
    Value<DateTime>? trxAt,
    Value<DateTime?>? syncedAt,
    Value<String?>? photoPath,
    Value<bool>? photoUploaded,
    Value<int>? unreportedPrints,
    Value<int>? printCount,
    Value<int>? createdBy,
    Value<int>? rowid,
  }) {
    return LocalTransactionsCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      payload: payload ?? this.payload,
      trxType: trxType ?? this.trxType,
      locationId: locationId ?? this.locationId,
      tmpDocNo: tmpDocNo ?? this.tmpDocNo,
      docNo: docNo ?? this.docNo,
      serverId: serverId ?? this.serverId,
      serverStatus: serverStatus ?? this.serverStatus,
      serverJson: serverJson ?? this.serverJson,
      syncState: syncState ?? this.syncState,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      attempts: attempts ?? this.attempts,
      clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
      trxAt: trxAt ?? this.trxAt,
      syncedAt: syncedAt ?? this.syncedAt,
      photoPath: photoPath ?? this.photoPath,
      photoUploaded: photoUploaded ?? this.photoUploaded,
      unreportedPrints: unreportedPrints ?? this.unreportedPrints,
      printCount: printCount ?? this.printCount,
      createdBy: createdBy ?? this.createdBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (trxType.present) {
      map['trx_type'] = Variable<String>(trxType.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<int>(locationId.value);
    }
    if (tmpDocNo.present) {
      map['tmp_doc_no'] = Variable<String>(tmpDocNo.value);
    }
    if (docNo.present) {
      map['doc_no'] = Variable<String>(docNo.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (serverStatus.present) {
      map['server_status'] = Variable<String>(serverStatus.value);
    }
    if (serverJson.present) {
      map['server_json'] = Variable<String>(serverJson.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (clientCreatedAt.present) {
      map['client_created_at'] = Variable<DateTime>(clientCreatedAt.value);
    }
    if (trxAt.present) {
      map['trx_at'] = Variable<DateTime>(trxAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoUploaded.present) {
      map['photo_uploaded'] = Variable<bool>(photoUploaded.value);
    }
    if (unreportedPrints.present) {
      map['unreported_prints'] = Variable<int>(unreportedPrints.value);
    }
    if (printCount.present) {
      map['print_count'] = Variable<int>(printCount.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<int>(createdBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransactionsCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('payload: $payload, ')
          ..write('trxType: $trxType, ')
          ..write('locationId: $locationId, ')
          ..write('tmpDocNo: $tmpDocNo, ')
          ..write('docNo: $docNo, ')
          ..write('serverId: $serverId, ')
          ..write('serverStatus: $serverStatus, ')
          ..write('serverJson: $serverJson, ')
          ..write('syncState: $syncState, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('attempts: $attempts, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('trxAt: $trxAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoUploaded: $photoUploaded, ')
          ..write('unreportedPrints: $unreportedPrints, ')
          ..write('printCount: $printCount, ')
          ..write('createdBy: $createdBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  const KeyValue({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValue copyWith({String? key, String? value}) =>
      KeyValue(key: key ?? this.key, value: value ?? this.value);
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValue> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $LocationsTable locations = $LocationsTable(this);
  late final $PackagingUnitsTable packagingUnits = $PackagingUnitsTable(this);
  late final $PartnersTable partners = $PartnersTable(this);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $MinLevelsTable minLevels = $MinLevelsTable(this);
  late final $BalancesTable balances = $BalancesTable(this);
  late final $LocalTransactionsTable localTransactions =
      $LocalTransactionsTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    locations,
    packagingUnits,
    partners,
    vehicles,
    minLevels,
    balances,
    localTransactions,
    keyValues,
  ];
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      required String code,
      required String name,
      Value<String?> meshSize,
      required String category,
      Value<int> sortOrder,
      Value<bool> isActive,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> name,
      Value<String?> meshSize,
      Value<String> category,
      Value<int> sortOrder,
      Value<bool> isActive,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meshSize => $composableBuilder(
    column: $table.meshSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meshSize => $composableBuilder(
    column: $table.meshSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get meshSize =>
      $composableBuilder(column: $table.meshSize, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> meshSize = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                code: code,
                name: name,
                meshSize: meshSize,
                category: category,
                sortOrder: sortOrder,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String name,
                Value<String?> meshSize = const Value.absent(),
                required String category,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                code: code,
                name: name,
                meshSize: meshSize,
                category: category,
                sortOrder: sortOrder,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, Product>(table),
                  BaseReferences<_$AppDatabase, $ProductsTable, Product>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$LocationsTableCreateCompanionBuilder =
    LocationsCompanion Function({
      Value<int> id,
      required String code,
      required String name,
      required String type,
      Value<String?> address,
      Value<String> timezone,
      Value<bool> isActive,
    });
typedef $$LocationsTableUpdateCompanionBuilder =
    LocationsCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> name,
      Value<String> type,
      Value<String?> address,
      Value<String> timezone,
      Value<bool> isActive,
    });

class $$LocationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocationsTable> {
  $$LocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocationsTable> {
  $$LocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocationsTable> {
  $$LocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$LocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocationsTable,
          Location,
          $$LocationsTableFilterComposer,
          $$LocationsTableOrderingComposer,
          $$LocationsTableAnnotationComposer,
          $$LocationsTableCreateCompanionBuilder,
          $$LocationsTableUpdateCompanionBuilder,
          (Location, BaseReferences<_$AppDatabase, $LocationsTable, Location>),
          Location,
          PrefetchHooks Function()
        > {
  $$LocationsTableTableManager(_$AppDatabase db, $LocationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => LocationsCompanion(
                id: id,
                code: code,
                name: name,
                type: type,
                address: address,
                timezone: timezone,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String name,
                required String type,
                Value<String?> address = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => LocationsCompanion.insert(
                id: id,
                code: code,
                name: name,
                type: type,
                address: address,
                timezone: timezone,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocationsTable, Location>(table),
                  BaseReferences<_$AppDatabase, $LocationsTable, Location>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocationsTable,
      Location,
      $$LocationsTableFilterComposer,
      $$LocationsTableOrderingComposer,
      $$LocationsTableAnnotationComposer,
      $$LocationsTableCreateCompanionBuilder,
      $$LocationsTableUpdateCompanionBuilder,
      (Location, BaseReferences<_$AppDatabase, $LocationsTable, Location>),
      Location,
      PrefetchHooks Function()
    >;
typedef $$PackagingUnitsTableCreateCompanionBuilder =
    PackagingUnitsCompanion Function({
      Value<int> id,
      required String name,
      required String tonPerUnit,
      Value<bool> isBulk,
      Value<bool> isActive,
    });
typedef $$PackagingUnitsTableUpdateCompanionBuilder =
    PackagingUnitsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> tonPerUnit,
      Value<bool> isBulk,
      Value<bool> isActive,
    });

class $$PackagingUnitsTableFilterComposer
    extends Composer<_$AppDatabase, $PackagingUnitsTable> {
  $$PackagingUnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tonPerUnit => $composableBuilder(
    column: $table.tonPerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBulk => $composableBuilder(
    column: $table.isBulk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PackagingUnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $PackagingUnitsTable> {
  $$PackagingUnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tonPerUnit => $composableBuilder(
    column: $table.tonPerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBulk => $composableBuilder(
    column: $table.isBulk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PackagingUnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PackagingUnitsTable> {
  $$PackagingUnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get tonPerUnit => $composableBuilder(
    column: $table.tonPerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBulk =>
      $composableBuilder(column: $table.isBulk, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$PackagingUnitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PackagingUnitsTable,
          PackagingUnit,
          $$PackagingUnitsTableFilterComposer,
          $$PackagingUnitsTableOrderingComposer,
          $$PackagingUnitsTableAnnotationComposer,
          $$PackagingUnitsTableCreateCompanionBuilder,
          $$PackagingUnitsTableUpdateCompanionBuilder,
          (
            PackagingUnit,
            BaseReferences<_$AppDatabase, $PackagingUnitsTable, PackagingUnit>,
          ),
          PackagingUnit,
          PrefetchHooks Function()
        > {
  $$PackagingUnitsTableTableManager(
    _$AppDatabase db,
    $PackagingUnitsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackagingUnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackagingUnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackagingUnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> tonPerUnit = const Value.absent(),
                Value<bool> isBulk = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => PackagingUnitsCompanion(
                id: id,
                name: name,
                tonPerUnit: tonPerUnit,
                isBulk: isBulk,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String tonPerUnit,
                Value<bool> isBulk = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => PackagingUnitsCompanion.insert(
                id: id,
                name: name,
                tonPerUnit: tonPerUnit,
                isBulk: isBulk,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PackagingUnitsTable, PackagingUnit>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PackagingUnitsTable,
                    PackagingUnit
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PackagingUnitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PackagingUnitsTable,
      PackagingUnit,
      $$PackagingUnitsTableFilterComposer,
      $$PackagingUnitsTableOrderingComposer,
      $$PackagingUnitsTableAnnotationComposer,
      $$PackagingUnitsTableCreateCompanionBuilder,
      $$PackagingUnitsTableUpdateCompanionBuilder,
      (
        PackagingUnit,
        BaseReferences<_$AppDatabase, $PackagingUnitsTable, PackagingUnit>,
      ),
      PackagingUnit,
      PrefetchHooks Function()
    >;
typedef $$PartnersTableCreateCompanionBuilder =
    PartnersCompanion Function({
      Value<int> id,
      required String type,
      required String name,
      Value<String?> phone,
      Value<String?> address,
      Value<bool> isActive,
    });
typedef $$PartnersTableUpdateCompanionBuilder =
    PartnersCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> name,
      Value<String?> phone,
      Value<String?> address,
      Value<bool> isActive,
    });

class $$PartnersTableFilterComposer
    extends Composer<_$AppDatabase, $PartnersTable> {
  $$PartnersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PartnersTableOrderingComposer
    extends Composer<_$AppDatabase, $PartnersTable> {
  $$PartnersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PartnersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PartnersTable> {
  $$PartnersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$PartnersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PartnersTable,
          Partner,
          $$PartnersTableFilterComposer,
          $$PartnersTableOrderingComposer,
          $$PartnersTableAnnotationComposer,
          $$PartnersTableCreateCompanionBuilder,
          $$PartnersTableUpdateCompanionBuilder,
          (Partner, BaseReferences<_$AppDatabase, $PartnersTable, Partner>),
          Partner,
          PrefetchHooks Function()
        > {
  $$PartnersTableTableManager(_$AppDatabase db, $PartnersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PartnersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PartnersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PartnersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => PartnersCompanion(
                id: id,
                type: type,
                name: name,
                phone: phone,
                address: address,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => PartnersCompanion.insert(
                id: id,
                type: type,
                name: name,
                phone: phone,
                address: address,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PartnersTable, Partner>(table),
                  BaseReferences<_$AppDatabase, $PartnersTable, Partner>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PartnersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PartnersTable,
      Partner,
      $$PartnersTableFilterComposer,
      $$PartnersTableOrderingComposer,
      $$PartnersTableAnnotationComposer,
      $$PartnersTableCreateCompanionBuilder,
      $$PartnersTableUpdateCompanionBuilder,
      (Partner, BaseReferences<_$AppDatabase, $PartnersTable, Partner>),
      Partner,
      PrefetchHooks Function()
    >;
typedef $$VehiclesTableCreateCompanionBuilder =
    VehiclesCompanion Function({
      Value<int> id,
      required String plateNumber,
      Value<String?> defaultDriver,
      Value<String?> standardTareTon,
      Value<bool> isActive,
    });
typedef $$VehiclesTableUpdateCompanionBuilder =
    VehiclesCompanion Function({
      Value<int> id,
      Value<String> plateNumber,
      Value<String?> defaultDriver,
      Value<String?> standardTareTon,
      Value<bool> isActive,
    });

class $$VehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plateNumber => $composableBuilder(
    column: $table.plateNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultDriver => $composableBuilder(
    column: $table.defaultDriver,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get standardTareTon => $composableBuilder(
    column: $table.standardTareTon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plateNumber => $composableBuilder(
    column: $table.plateNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultDriver => $composableBuilder(
    column: $table.defaultDriver,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get standardTareTon => $composableBuilder(
    column: $table.standardTareTon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plateNumber => $composableBuilder(
    column: $table.plateNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultDriver => $composableBuilder(
    column: $table.defaultDriver,
    builder: (column) => column,
  );

  GeneratedColumn<String> get standardTareTon => $composableBuilder(
    column: $table.standardTareTon,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$VehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehiclesTable,
          Vehicle,
          $$VehiclesTableFilterComposer,
          $$VehiclesTableOrderingComposer,
          $$VehiclesTableAnnotationComposer,
          $$VehiclesTableCreateCompanionBuilder,
          $$VehiclesTableUpdateCompanionBuilder,
          (Vehicle, BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle>),
          Vehicle,
          PrefetchHooks Function()
        > {
  $$VehiclesTableTableManager(_$AppDatabase db, $VehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> plateNumber = const Value.absent(),
                Value<String?> defaultDriver = const Value.absent(),
                Value<String?> standardTareTon = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => VehiclesCompanion(
                id: id,
                plateNumber: plateNumber,
                defaultDriver: defaultDriver,
                standardTareTon: standardTareTon,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String plateNumber,
                Value<String?> defaultDriver = const Value.absent(),
                Value<String?> standardTareTon = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => VehiclesCompanion.insert(
                id: id,
                plateNumber: plateNumber,
                defaultDriver: defaultDriver,
                standardTareTon: standardTareTon,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VehiclesTable, Vehicle>(table),
                  BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehiclesTable,
      Vehicle,
      $$VehiclesTableFilterComposer,
      $$VehiclesTableOrderingComposer,
      $$VehiclesTableAnnotationComposer,
      $$VehiclesTableCreateCompanionBuilder,
      $$VehiclesTableUpdateCompanionBuilder,
      (Vehicle, BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle>),
      Vehicle,
      PrefetchHooks Function()
    >;
typedef $$MinLevelsTableCreateCompanionBuilder =
    MinLevelsCompanion Function({
      required int locationId,
      required int productId,
      required String minTon,
      Value<int> rowid,
    });
typedef $$MinLevelsTableUpdateCompanionBuilder =
    MinLevelsCompanion Function({
      Value<int> locationId,
      Value<int> productId,
      Value<String> minTon,
      Value<int> rowid,
    });

class $$MinLevelsTableFilterComposer
    extends Composer<_$AppDatabase, $MinLevelsTable> {
  $$MinLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get minTon => $composableBuilder(
    column: $table.minTon,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MinLevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $MinLevelsTable> {
  $$MinLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get minTon => $composableBuilder(
    column: $table.minTon,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MinLevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MinLevelsTable> {
  $$MinLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get minTon =>
      $composableBuilder(column: $table.minTon, builder: (column) => column);
}

class $$MinLevelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MinLevelsTable,
          MinLevel,
          $$MinLevelsTableFilterComposer,
          $$MinLevelsTableOrderingComposer,
          $$MinLevelsTableAnnotationComposer,
          $$MinLevelsTableCreateCompanionBuilder,
          $$MinLevelsTableUpdateCompanionBuilder,
          (MinLevel, BaseReferences<_$AppDatabase, $MinLevelsTable, MinLevel>),
          MinLevel,
          PrefetchHooks Function()
        > {
  $$MinLevelsTableTableManager(_$AppDatabase db, $MinLevelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MinLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MinLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MinLevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> locationId = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> minTon = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MinLevelsCompanion(
                locationId: locationId,
                productId: productId,
                minTon: minTon,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int locationId,
                required int productId,
                required String minTon,
                Value<int> rowid = const Value.absent(),
              }) => MinLevelsCompanion.insert(
                locationId: locationId,
                productId: productId,
                minTon: minTon,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MinLevelsTable, MinLevel>(table),
                  BaseReferences<_$AppDatabase, $MinLevelsTable, MinLevel>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MinLevelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MinLevelsTable,
      MinLevel,
      $$MinLevelsTableFilterComposer,
      $$MinLevelsTableOrderingComposer,
      $$MinLevelsTableAnnotationComposer,
      $$MinLevelsTableCreateCompanionBuilder,
      $$MinLevelsTableUpdateCompanionBuilder,
      (MinLevel, BaseReferences<_$AppDatabase, $MinLevelsTable, MinLevel>),
      MinLevel,
      PrefetchHooks Function()
    >;
typedef $$BalancesTableCreateCompanionBuilder =
    BalancesCompanion Function({
      required int locationId,
      required int productId,
      required String qtyTon,
      Value<String> inTransitTon,
      Value<int> rowid,
    });
typedef $$BalancesTableUpdateCompanionBuilder =
    BalancesCompanion Function({
      Value<int> locationId,
      Value<int> productId,
      Value<String> qtyTon,
      Value<String> inTransitTon,
      Value<int> rowid,
    });

class $$BalancesTableFilterComposer
    extends Composer<_$AppDatabase, $BalancesTable> {
  $$BalancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qtyTon => $composableBuilder(
    column: $table.qtyTon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inTransitTon => $composableBuilder(
    column: $table.inTransitTon,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BalancesTableOrderingComposer
    extends Composer<_$AppDatabase, $BalancesTable> {
  $$BalancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qtyTon => $composableBuilder(
    column: $table.qtyTon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inTransitTon => $composableBuilder(
    column: $table.inTransitTon,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BalancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BalancesTable> {
  $$BalancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get qtyTon =>
      $composableBuilder(column: $table.qtyTon, builder: (column) => column);

  GeneratedColumn<String> get inTransitTon => $composableBuilder(
    column: $table.inTransitTon,
    builder: (column) => column,
  );
}

class $$BalancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BalancesTable,
          Balance,
          $$BalancesTableFilterComposer,
          $$BalancesTableOrderingComposer,
          $$BalancesTableAnnotationComposer,
          $$BalancesTableCreateCompanionBuilder,
          $$BalancesTableUpdateCompanionBuilder,
          (Balance, BaseReferences<_$AppDatabase, $BalancesTable, Balance>),
          Balance,
          PrefetchHooks Function()
        > {
  $$BalancesTableTableManager(_$AppDatabase db, $BalancesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BalancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BalancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BalancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> locationId = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> qtyTon = const Value.absent(),
                Value<String> inTransitTon = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalancesCompanion(
                locationId: locationId,
                productId: productId,
                qtyTon: qtyTon,
                inTransitTon: inTransitTon,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int locationId,
                required int productId,
                required String qtyTon,
                Value<String> inTransitTon = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalancesCompanion.insert(
                locationId: locationId,
                productId: productId,
                qtyTon: qtyTon,
                inTransitTon: inTransitTon,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BalancesTable, Balance>(table),
                  BaseReferences<_$AppDatabase, $BalancesTable, Balance>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BalancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BalancesTable,
      Balance,
      $$BalancesTableFilterComposer,
      $$BalancesTableOrderingComposer,
      $$BalancesTableAnnotationComposer,
      $$BalancesTableCreateCompanionBuilder,
      $$BalancesTableUpdateCompanionBuilder,
      (Balance, BaseReferences<_$AppDatabase, $BalancesTable, Balance>),
      Balance,
      PrefetchHooks Function()
    >;
typedef $$LocalTransactionsTableCreateCompanionBuilder =
    LocalTransactionsCompanion Function({
      required String clientUuid,
      required String payload,
      required String trxType,
      required int locationId,
      required String tmpDocNo,
      Value<String?> docNo,
      Value<int?> serverId,
      Value<String?> serverStatus,
      Value<String?> serverJson,
      Value<String> syncState,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<int> attempts,
      required DateTime clientCreatedAt,
      required DateTime trxAt,
      Value<DateTime?> syncedAt,
      Value<String?> photoPath,
      Value<bool> photoUploaded,
      Value<int> unreportedPrints,
      Value<int> printCount,
      required int createdBy,
      Value<int> rowid,
    });
typedef $$LocalTransactionsTableUpdateCompanionBuilder =
    LocalTransactionsCompanion Function({
      Value<String> clientUuid,
      Value<String> payload,
      Value<String> trxType,
      Value<int> locationId,
      Value<String> tmpDocNo,
      Value<String?> docNo,
      Value<int?> serverId,
      Value<String?> serverStatus,
      Value<String?> serverJson,
      Value<String> syncState,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<int> attempts,
      Value<DateTime> clientCreatedAt,
      Value<DateTime> trxAt,
      Value<DateTime?> syncedAt,
      Value<String?> photoPath,
      Value<bool> photoUploaded,
      Value<int> unreportedPrints,
      Value<int> printCount,
      Value<int> createdBy,
      Value<int> rowid,
    });

class $$LocalTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trxType => $composableBuilder(
    column: $table.trxType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tmpDocNo => $composableBuilder(
    column: $table.tmpDocNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docNo => $composableBuilder(
    column: $table.docNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get trxAt => $composableBuilder(
    column: $table.trxAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get photoUploaded => $composableBuilder(
    column: $table.photoUploaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreportedPrints => $composableBuilder(
    column: $table.unreportedPrints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get printCount => $composableBuilder(
    column: $table.printCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trxType => $composableBuilder(
    column: $table.trxType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tmpDocNo => $composableBuilder(
    column: $table.tmpDocNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docNo => $composableBuilder(
    column: $table.docNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get trxAt => $composableBuilder(
    column: $table.trxAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get photoUploaded => $composableBuilder(
    column: $table.photoUploaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreportedPrints => $composableBuilder(
    column: $table.unreportedPrints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get printCount => $composableBuilder(
    column: $table.printCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get trxType =>
      $composableBuilder(column: $table.trxType, builder: (column) => column);

  GeneratedColumn<int> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tmpDocNo =>
      $composableBuilder(column: $table.tmpDocNo, builder: (column) => column);

  GeneratedColumn<String> get docNo =>
      $composableBuilder(column: $table.docNo, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get trxAt =>
      $composableBuilder(column: $table.trxAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<bool> get photoUploaded => $composableBuilder(
    column: $table.photoUploaded,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreportedPrints => $composableBuilder(
    column: $table.unreportedPrints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get printCount => $composableBuilder(
    column: $table.printCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);
}

class $$LocalTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTransactionsTable,
          LocalTransaction,
          $$LocalTransactionsTableFilterComposer,
          $$LocalTransactionsTableOrderingComposer,
          $$LocalTransactionsTableAnnotationComposer,
          $$LocalTransactionsTableCreateCompanionBuilder,
          $$LocalTransactionsTableUpdateCompanionBuilder,
          (
            LocalTransaction,
            BaseReferences<
              _$AppDatabase,
              $LocalTransactionsTable,
              LocalTransaction
            >,
          ),
          LocalTransaction,
          PrefetchHooks Function()
        > {
  $$LocalTransactionsTableTableManager(
    _$AppDatabase db,
    $LocalTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> clientUuid = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> trxType = const Value.absent(),
                Value<int> locationId = const Value.absent(),
                Value<String> tmpDocNo = const Value.absent(),
                Value<String?> docNo = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> serverStatus = const Value.absent(),
                Value<String?> serverJson = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> clientCreatedAt = const Value.absent(),
                Value<DateTime> trxAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<bool> photoUploaded = const Value.absent(),
                Value<int> unreportedPrints = const Value.absent(),
                Value<int> printCount = const Value.absent(),
                Value<int> createdBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTransactionsCompanion(
                clientUuid: clientUuid,
                payload: payload,
                trxType: trxType,
                locationId: locationId,
                tmpDocNo: tmpDocNo,
                docNo: docNo,
                serverId: serverId,
                serverStatus: serverStatus,
                serverJson: serverJson,
                syncState: syncState,
                errorCode: errorCode,
                errorMessage: errorMessage,
                attempts: attempts,
                clientCreatedAt: clientCreatedAt,
                trxAt: trxAt,
                syncedAt: syncedAt,
                photoPath: photoPath,
                photoUploaded: photoUploaded,
                unreportedPrints: unreportedPrints,
                printCount: printCount,
                createdBy: createdBy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientUuid,
                required String payload,
                required String trxType,
                required int locationId,
                required String tmpDocNo,
                Value<String?> docNo = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> serverStatus = const Value.absent(),
                Value<String?> serverJson = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required DateTime clientCreatedAt,
                required DateTime trxAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<bool> photoUploaded = const Value.absent(),
                Value<int> unreportedPrints = const Value.absent(),
                Value<int> printCount = const Value.absent(),
                required int createdBy,
                Value<int> rowid = const Value.absent(),
              }) => LocalTransactionsCompanion.insert(
                clientUuid: clientUuid,
                payload: payload,
                trxType: trxType,
                locationId: locationId,
                tmpDocNo: tmpDocNo,
                docNo: docNo,
                serverId: serverId,
                serverStatus: serverStatus,
                serverJson: serverJson,
                syncState: syncState,
                errorCode: errorCode,
                errorMessage: errorMessage,
                attempts: attempts,
                clientCreatedAt: clientCreatedAt,
                trxAt: trxAt,
                syncedAt: syncedAt,
                photoPath: photoPath,
                photoUploaded: photoUploaded,
                unreportedPrints: unreportedPrints,
                printCount: printCount,
                createdBy: createdBy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalTransactionsTable, LocalTransaction>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalTransactionsTable,
                    LocalTransaction
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTransactionsTable,
      LocalTransaction,
      $$LocalTransactionsTableFilterComposer,
      $$LocalTransactionsTableOrderingComposer,
      $$LocalTransactionsTableAnnotationComposer,
      $$LocalTransactionsTableCreateCompanionBuilder,
      $$LocalTransactionsTableUpdateCompanionBuilder,
      (
        LocalTransaction,
        BaseReferences<
          _$AppDatabase,
          $LocalTransactionsTable,
          LocalTransaction
        >,
      ),
      LocalTransaction,
      PrefetchHooks Function()
    >;
typedef $$KeyValuesTableCreateCompanionBuilder =
    KeyValuesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KeyValuesTableUpdateCompanionBuilder =
    KeyValuesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
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
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValue>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$LocationsTableTableManager get locations =>
      $$LocationsTableTableManager(_db, _db.locations);
  $$PackagingUnitsTableTableManager get packagingUnits =>
      $$PackagingUnitsTableTableManager(_db, _db.packagingUnits);
  $$PartnersTableTableManager get partners =>
      $$PartnersTableTableManager(_db, _db.partners);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$MinLevelsTableTableManager get minLevels =>
      $$MinLevelsTableTableManager(_db, _db.minLevels);
  $$BalancesTableTableManager get balances =>
      $$BalancesTableTableManager(_db, _db.balances);
  $$LocalTransactionsTableTableManager get localTransactions =>
      $$LocalTransactionsTableTableManager(_db, _db.localTransactions);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
}
