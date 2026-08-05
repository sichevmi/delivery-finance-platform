import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/shifts.dart';
import 'package:delivery_app/logger.dart';

class ShiftDao {
  final AppDatabase db;

  ShiftDao(this.db);

  Future<int> insertShift(ShiftTableCompanion shift) async {
    try {
      final id = await db.into(db.shiftTable).insert(shift);
      logMessage('💾 Смена сохранена в БД, id=$id', category: 'DATABASE');
      return id;
    } catch (e) {
      logMessage('❌ Ошибка сохранения смены: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }

  Future<ShiftTableData?> getActiveShift() async {
    try {
      return await (db.select(db.shiftTable)
        ..where((t) => t.status.equals('active'))
        ..orderBy([(t) => OrderingTerm.desc(t.id)])
        ..limit(1)).getSingleOrNull();
    } catch (e) {
      logMessage('❌ Ошибка получения активной смены: $e', category: 'DATABASE', level: LogLevel.error);
      return null;
    }
  }

  Future<List<ShiftTableData>> getAllShifts() async {
    try {
      return await (db.select(db.shiftTable)
        ..orderBy([(t) => OrderingTerm.desc(t.id)])).get();
    } catch (e) {
      logMessage('❌ Ошибка получения смен: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  Future<bool> updateShift(int id, ShiftTableCompanion shift) async {
    try {
      await db.update(db.shiftTable).replace(shift);
      return true;
    } catch (e) {
      logMessage('❌ Ошибка обновления смены: $e', category: 'DATABASE', level: LogLevel.error);
      return false;
    }
  }
}