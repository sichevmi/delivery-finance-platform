import 'package:drift/drift.dart';

class OrderTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()(); // ID на сервере
  
  // Связь со сменой
  IntColumn get shiftId => integer().nullable()(); // внешний ключ
  
  // Данные заказа
  TextColumn get serviceName => text()();
  RealColumn get coefficient => real().withDefault(const Constant(1.0))();
  IntColumn get deliveryNumber => integer().withDefault(const Constant(1))();
  
  // Итоги
  RealColumn get totalPaidDistance => real().withDefault(const Constant(0.0))();
  RealColumn get totalIncome => real().withDefault(const Constant(0.0))();
  RealColumn get totalExpenses => real().withDefault(const Constant(0.0))();
  RealColumn get netProfit => real().withDefault(const Constant(0.0))();
  IntColumn get totalTimeSeconds => integer().withDefault(const Constant(0))();
  
  // Статус
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, completed, synced
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn? get updatedAt => dateTime().nullable()();
}