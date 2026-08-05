import 'package:drift/drift.dart';

class ShiftTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  
  TextColumn get startTime => text()();
  TextColumn? get endTime => text().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  
  RealColumn get totalPaidDistance => real().withDefault(const Constant(0.0))();
  RealColumn get totalIdleDistance => real().withDefault(const Constant(0.0))();
  
  IntColumn get ordersCount => integer().withDefault(const Constant(0))();
  RealColumn get totalIncome => real().withDefault(const Constant(0.0))();
  RealColumn get totalExpenses => real().withDefault(const Constant(0.0))();
  RealColumn get netProfit => real().withDefault(const Constant(0.0))();
  
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn? get updatedAt => dateTime().nullable()();
}