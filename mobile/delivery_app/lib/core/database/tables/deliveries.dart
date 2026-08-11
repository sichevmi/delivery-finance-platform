import 'package:drift/drift.dart';

class DeliveryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  
  // Связь с заказом
  IntColumn get orderId => integer().nullable()(); // внешний ключ
  
  // Данные доставки
  IntColumn get number => integer()();
  TextColumn get clientAddress => text()();
  TextColumn get apartment => text()();
  RealColumn get weight => real()();
  
  // Времена и расстояния по сегментам
  IntColumn get timeToShop => integer().withDefault(const Constant(0))();
  RealColumn get distanceToShop => real().withDefault(const Constant(0.0))();
  IntColumn get timeReceiving => integer().withDefault(const Constant(0))();
  IntColumn get timeToClient => integer().withDefault(const Constant(0))();
  RealColumn get distanceToClient => real().withDefault(const Constant(0.0))();
  IntColumn get timeDelivery => integer().withDefault(const Constant(0))();
  
  // Статус
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn? get updatedAt => dateTime().nullable()();
}