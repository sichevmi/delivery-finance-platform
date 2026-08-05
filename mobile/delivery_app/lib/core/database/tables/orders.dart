import 'package:drift/drift.dart';

class OrderTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  IntColumn get shiftId => integer().nullable()();
  IntColumn get deliveryNumber => integer().nullable()();
  RealColumn get coefficient => real().nullable()();
  TextColumn get serviceName => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn? get updatedAt => dateTime().nullable()();
}