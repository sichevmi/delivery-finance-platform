import 'package:drift/drift.dart';

class GpsPointTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deliveryId => integer().nullable()();
  IntColumn get segmentIndex => integer()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real()();
  RealColumn get speed => real().nullable()();
  IntColumn get timestamp => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}