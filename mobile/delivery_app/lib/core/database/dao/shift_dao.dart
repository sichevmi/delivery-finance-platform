import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/shifts.dart';
import 'package:delivery_app/logger.dart';

class ShiftDao {
  final AppDatabase db;

  ShiftDao(this.db);

  // Вставка с простыми параметрами
  Future<int> insertShift({
    required String startTime,
    String? endTime,
    required int durationSeconds,
    required double totalPaidDistance,
    required double totalIdleDistance,
    required int totalOrderTimeSeconds,
    required int ordersCount,
    required double totalIncome,
    required double totalExpenses,
    required double netProfit,
    required String status,
  }) async {
    try {
      final companion = ShiftTableCompanion(
        startTime: Value(startTime),
        endTime: Value(endTime),
        durationSeconds: Value(durationSeconds),
        totalPaidDistance: Value(totalPaidDistance),
        totalIdleDistance: Value(totalIdleDistance),
        totalOrderTimeSeconds: Value(totalOrderTimeSeconds),
        ordersCount: Value(ordersCount),
        totalIncome: Value(totalIncome),
        totalExpenses: Value(totalExpenses),
        netProfit: Value(netProfit),
        status: Value(status),
        isSynced: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      final id = await db.into(db.shiftTable).insert(companion);
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

  // НОВЫЙ МЕТОД: получить смены за указанную дату
  Future<List<ShiftTableData>> getShiftsForDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      return await (db.select(db.shiftTable)
        ..where((t) => t.createdAt.isBetweenValues(start, end))
        ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ).get();
    } catch (e) {
      logMessage('❌ Ошибка получения смен за дату: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  // Обновление с простыми параметрами
  Future<bool> updateShift(
    int id, {
    required String startTime,
    String? endTime,
    required int durationSeconds,
    required double totalPaidDistance,
    required double totalIdleDistance,
    required int totalOrderTimeSeconds,
    required int ordersCount,
    required double totalIncome,
    required double totalExpenses,
    required double netProfit,
    required String status,
  }) async {
    try {
      final companion = ShiftTableCompanion(
        startTime: Value(startTime),
        endTime: Value(endTime),
        durationSeconds: Value(durationSeconds),
        totalPaidDistance: Value(totalPaidDistance),
        totalIdleDistance: Value(totalIdleDistance),
        totalOrderTimeSeconds: Value(totalOrderTimeSeconds),
        ordersCount: Value(ordersCount),
        totalIncome: Value(totalIncome),
        totalExpenses: Value(totalExpenses),
        netProfit: Value(netProfit),
        status: Value(status),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      );
      final count = await (db.update(db.shiftTable)
        ..where((t) => t.id.equals(id))).write(companion);
      
      if (count > 0) {
        logMessage('🔄 Смена $id обновлена', category: 'DATABASE');
        return true;
      } else {
        logMessage('⚠️ Смена $id не найдена для обновления', category: 'DATABASE');
        return false;
      }
    } catch (e) {
      logMessage('❌ Ошибка обновления смены $id: $e', category: 'DATABASE', level: LogLevel.error);
      return false;
    }
  }
}