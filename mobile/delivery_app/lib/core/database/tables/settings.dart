import 'package:drift/drift.dart';

class SettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  
  RealColumn get fuelConsumption => real().withDefault(const Constant(10.0))();
  RealColumn get fuelPrice => real().withDefault(const Constant(50.0))();
  RealColumn get repairCost => real().withDefault(const Constant(2.0))();
  RealColumn get additionalCosts => real().withDefault(const Constant(0.0))();
  
  TextColumn get name => text().withDefault(const Constant('Стандартные'))();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn? get updatedAt => dateTime().nullable()();

}