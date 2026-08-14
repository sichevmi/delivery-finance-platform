import 'package:drift/drift.dart';

class X5SettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // Параметры X5
  RealColumn get pickupPrice => real().withDefault(const Constant(250.0))();
  RealColumn get deliveryPrice => real().withDefault(const Constant(150.0))();
  RealColumn get perKmPrice => real().withDefault(const Constant(25.0))();
  RealColumn get perKgPrice => real().withDefault(const Constant(10.0))();
  
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn? get updatedAt => dateTime().nullable()();

  
}