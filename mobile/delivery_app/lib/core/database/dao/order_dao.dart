// lib/core/database/dao/order_dao.dart
import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/orders.dart';
import 'package:delivery_app/logger.dart';

class OrderDao {
  final AppDatabase db;

  OrderDao(this.db);

  // Сохранить заказ
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
      logMessage('💾 Заказ сохранён в БД, id=$id', category: 'DATABASE');
      return id;
    } catch (e) {
      logMessage('❌ Ошибка сохранения заказа: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }

  // Получить заказ по ID
  Future<OrderTableData?> getOrderById(int id) async {
    try {
      return await (db.select(db.orderTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    } catch (e) {
      logMessage('❌ Ошибка получения заказа: $e', category: 'DATABASE', level: LogLevel.error);
      return null;
    }
  }

  // Получить все заказы за день
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

  // Получить заказы по смене
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

  // Обновить заказ
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

  // Отметить как синхронизированный
  Future<void> markAsSynced(int id, int serverId) async {
    await (db.update(db.orderTable)
      ..where((t) => t.id.equals(id))).write(
        OrderTableCompanion(
          isSynced: const Value(true),
          serverId: Value(serverId),
          status: const Value('synced'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    logMessage('✅ Заказ $id синхронизирован (serverId=$serverId)', category: 'DATABASE');
  }
}