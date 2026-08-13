import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/orders.dart';
import 'package:delivery_app/logger.dart';

class OrderDao {
  final AppDatabase db;

  OrderDao(this.db);

  Future<int> insertOrder({
    required String serviceName,
    required double coefficient,
    required int deliveryNumber,
    required double totalPaidDistance,
    required double totalIncome,
    required double totalExpenses,
    required double netProfit,
    required int totalTimeSeconds,
    int? shiftId,
    String status = 'active',
  }) async {
    try {
      final companion = OrderTableCompanion(
        serviceName: Value(serviceName),
        coefficient: Value(coefficient),
        deliveryNumber: Value(deliveryNumber),
        totalPaidDistance: Value(totalPaidDistance),
        totalIncome: Value(totalIncome),
        totalExpenses: Value(totalExpenses),
        netProfit: Value(netProfit),
        totalTimeSeconds: Value(totalTimeSeconds),
        shiftId: Value(shiftId),
        status: Value(status),
        isSynced: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      final id = await db.into(db.orderTable).insert(companion);
      logMessage('💾 Заказ сохранён, id=$id', category: 'DATABASE');
      return id;
    } catch (e) {
      logMessage('❌ Ошибка сохранения заказа: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }

  Future<OrderTableData?> getOrderById(int id) async {
    try {
      return await (db.select(db.orderTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    } catch (e) {
      logMessage('❌ Ошибка получения заказа: $e', category: 'DATABASE', level: LogLevel.error);
      return null;
    }
  }

  Future<List<OrderTableData>> getOrdersForDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      return await (db.select(db.orderTable)
        ..where((t) => t.createdAt.isBetweenValues(start, end))
        ..orderBy([(t) => OrderingTerm.desc(t.id)])
      ).get();
    } catch (e) {
      logMessage('❌ Ошибка получения заказов за дату: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  Future<List<OrderTableData>> getOrdersByShift(int shiftId) async {
    try {
      return await (db.select(db.orderTable)
        ..where((t) => t.shiftId.equals(shiftId))
        ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ).get();
    } catch (e) {
      logMessage('❌ Ошибка получения заказов по смене: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  Future<List<OrderTableData>> getAllOrders() async {
    try {
      return await (db.select(db.orderTable)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ).get();
    } catch (e) {
      logMessage('❌ Ошибка получения всех заказов: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  Future<bool> updateOrder(int id, OrderTableCompanion order) async {
    try {
      final count = await (db.update(db.orderTable)
        ..where((t) => t.id.equals(id))).write(order);
      return count > 0;
    } catch (e) {
      logMessage('❌ Ошибка обновления заказа $id: $e', category: 'DATABASE', level: LogLevel.error);
      return false;
    }
  }

  // ===== МЕТОДЫ ДЛЯ СИНХРОНИЗАЦИИ (ОТПРАВКА) =====

  Future<List<OrderTableData>> getUnsyncedOrders() async {
    try {
      return await (db.select(db.orderTable)
        ..where((t) => t.isSynced.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ).get();
    } catch (e) {
      logMessage('❌ Ошибка получения несинхронизированных заказов: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  Future<void> markAsSynced(int localId, int serverId) async {
    try {
      await (db.update(db.orderTable)
        ..where((t) => t.id.equals(localId))
      ).write(
        OrderTableCompanion(
          serverId: Value(serverId),
          isSynced: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
      logMessage('✅ Заказ $localId синхронизирован (serverId=$serverId)', category: 'DATABASE');
    } catch (e) {
      logMessage('❌ Ошибка отметки заказа $localId: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }

  // ===== МЕТОДЫ ДЛЯ ЗАГРУЗКИ С СЕРВЕРА =====

  Future<void> deleteOrdersForDate(DateTime start, DateTime end) async {
    try {
      await (db.delete(db.orderTable)
        ..where((t) => t.createdAt.isBetweenValues(start, end))
      ).go();
      logMessage('🗑️ Удалены заказы за период', category: 'DATABASE');
    } catch (e) {
      logMessage('❌ Ошибка удаления заказов за дату: $e', category: 'DATABASE', level: LogLevel.error);
    }
  }

  Future<int> insertOrderFromServer(Map<String, dynamic> data) async {
    try {
      final companion = OrderTableCompanion(
        serverId: Value(data['id']),
        shiftId: Value(data['shiftId']),
        serviceName: Value(data['serviceName'] ?? 'Заказ'),
        coefficient: Value(data['coefficient'] ?? 1.0),
        deliveryNumber: Value(data['deliveryNumber'] ?? 1),
        totalPaidDistance: Value(data['totalPaidDistance'] ?? 0.0),
        totalIncome: Value(data['totalIncome'] ?? 0.0),
        totalExpenses: Value(data['totalExpenses'] ?? 0.0),
        netProfit: Value(data['netProfit'] ?? 0.0),
        totalTimeSeconds: Value(data['totalTimeSeconds'] ?? 0),
        status: Value(data['status'] ?? 'completed'),
        isSynced: const Value(true),
        createdAt: data['createdAt'] != null 
            ? Value(DateTime.parse(data['createdAt'])) 
            : Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      final id = await db.into(db.orderTable).insert(companion);
      logMessage('💾 Заказ с сервера сохранён, id=$id', category: 'DATABASE');
      return id;
    } catch (e) {
      logMessage('❌ Ошибка сохранения заказа с сервера: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }
}