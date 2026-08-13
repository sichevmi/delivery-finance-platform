import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/shifts.dart';
import 'package:delivery_app/logger.dart';

class ShiftDao {
  final AppDatabase db;

  ShiftDao(this.db);

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
      logMessage('💾 Смена сохранена, id=$id', category: 'DATABASE');
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

  Future<ShiftTableData?> getShiftById(int id) async {
    try {
      return await (db.select(db.shiftTable)
        ..where((t) => t.id.equals(id))
      ).getSingleOrNull();
    } catch (e) {
      logMessage('❌ Ошибка получения смены $id: $e', category: 'DATABASE', level: LogLevel.error);
      return null;
    }
  }

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
      }
      return false;
    } catch (e) {
      logMessage('❌ Ошибка обновления смены $id: $e', category: 'DATABASE', level: LogLevel.error);
      return false;
    }
  }

  // ===== МЕТОДЫ ДЛЯ СИНХРОНИЗАЦИИ (ОТПРАВКА) =====

  Future<List<ShiftTableData>> getUnsyncedShifts() async {
    try {
      return await (db.select(db.shiftTable)
        ..where((t) => t.isSynced.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ).get();
    } catch (e) {
      logMessage('❌ Ошибка получения несинхронизированных смен: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  Future<void> markAsSynced(int localId, int serverId) async {
    try {
      await (db.update(db.shiftTable)
        ..where((t) => t.id.equals(localId))
      ).write(
        ShiftTableCompanion(
          serverId: Value(serverId),
          isSynced: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
      logMessage('✅ Смена $localId синхронизирована (serverId=$serverId)', category: 'DATABASE');
    } catch (e) {
      logMessage('❌ Ошибка отметки смены $localId: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }

  // ===== МЕТОДЫ ДЛЯ ЗАГРУЗКИ С СЕРВЕРА =====

  /// Удаляет смены, которые есть в списке serverId
  Future<void> deleteShiftsByServerIds(List<int> serverIds) async {
    if (serverIds.isEmpty) return;
    try {
      final count = await (db.delete(db.shiftTable)
        ..where((t) => t.serverId.isIn(serverIds))
      ).go();
      logMessage('🗑️ Удалены смены с serverId: $serverIds (${count} шт.)', category: 'DATABASE');
    } catch (e) {
      logMessage('❌ Ошибка удаления смен: $e', category: 'DATABASE', level: LogLevel.error);
    }
  }

  /// Удаляет все смены (для полной очистки)
  Future<void> deleteAllShifts() async {
    try {
      await db.delete(db.shiftTable).go();
      logMessage('🗑️ Удалены все смены', category: 'DATABASE');
    } catch (e) {
      logMessage('❌ Ошибка удаления смен: $e', category: 'DATABASE', level: LogLevel.error);
    }
  }

  Future<int> insertShiftFromServer(Map<String, dynamic> data) async {
    try {
      // Проверяем, есть ли уже такая смена
      final existing = await (db.select(db.shiftTable)
        ..where((t) => t.serverId.equals(data['id']))
      ).getSingleOrNull();
      
      if (existing != null) {
        // Обновляем существующую
        await (db.update(db.shiftTable)
          ..where((t) => t.id.equals(existing.id))
        ).write(
          ShiftTableCompanion(
            startTime: Value(data['startTime'] ?? ''),
            endTime: Value(data['endTime']),
            durationSeconds: Value(data['durationSeconds'] ?? 0),
            totalPaidDistance: Value(data['totalPaidDistance'] ?? 0.0),
            totalIdleDistance: Value(data['totalIdleDistance'] ?? 0.0),
            totalOrderTimeSeconds: Value(data['totalOrderTimeSeconds'] ?? 0),
            ordersCount: Value(data['ordersCount'] ?? 0),
            totalIncome: Value(data['totalIncome'] ?? 0.0),
            totalExpenses: Value(data['totalExpenses'] ?? 0.0),
            netProfit: Value(data['netProfit'] ?? 0.0),
            status: Value(data['status'] ?? 'completed'),
            isSynced: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
        logMessage('🔄 Смена ${data['id']} обновлена с сервера', category: 'DATABASE');
        return existing.id;
      }
      
      // Создаём новую
      final companion = ShiftTableCompanion(
        serverId: Value(data['id']),
        startTime: Value(data['startTime'] ?? ''),
        endTime: Value(data['endTime']),
        durationSeconds: Value(data['durationSeconds'] ?? 0),
        totalPaidDistance: Value(data['totalPaidDistance'] ?? 0.0),
        totalIdleDistance: Value(data['totalIdleDistance'] ?? 0.0),
        totalOrderTimeSeconds: Value(data['totalOrderTimeSeconds'] ?? 0),
        ordersCount: Value(data['ordersCount'] ?? 0),
        totalIncome: Value(data['totalIncome'] ?? 0.0),
        totalExpenses: Value(data['totalExpenses'] ?? 0.0),
        netProfit: Value(data['netProfit'] ?? 0.0),
        status: Value(data['status'] ?? 'completed'),
        isSynced: const Value(true),
        createdAt: data['createdAt'] != null 
            ? Value(DateTime.parse(data['createdAt'])) 
            : Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      final id = await db.into(db.shiftTable).insert(companion);
      logMessage('💾 Смена ${data['id']} сохранена с сервера', category: 'DATABASE');
      return id;
    } catch (e) {
      logMessage('❌ Ошибка сохранения смены с сервера: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }
}