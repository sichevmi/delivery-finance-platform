import 'package:drift/drift.dart';

class PricingTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  
  RealColumn get receivingFee => real().withDefault(const Constant(0.0))();
  RealColumn get deliveryFee => real().withDefault(const Constant(0.0))();
  RealColumn get pricePerKg => real().withDefault(const Constant(0.0))();
  RealColumn get pricePerKm => real().withDefault(const Constant(0.0))();
  RealColumn get baseCoefficient => real().withDefault(const Constant(1.0))();
  
  TextColumn get name => text().withDefault(const Constant('Стандартный'))();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn? get updatedAt => dateTime().nullable()();


}