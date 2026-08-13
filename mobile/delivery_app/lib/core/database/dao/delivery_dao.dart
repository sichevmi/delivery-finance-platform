import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/deliveries.dart';
import 'package:delivery_app/logger.dart';

class DeliveryDao {
  final AppDatabase db;

  DeliveryDao(this.db);

  Future<int> insertDelivery({
    required int number,
    required String clientAddress,
    required String apartment,
    required double weight,
    required int timeToShop,
    required double distanceToShop,
    required int timeReceiving,
    required int timeToClient,
    required double distanceToClient,
    required int timeDelivery,
    int? orderId,
    String status = 'active',
  }) async {
    try {
      final companion = DeliveryTableCompanion(
        number: Value(number),
        clientAddress: Value(clientAddress),
        apartment: Value(apartment),
        weight: Value(weight),
        timeToShop: Value(timeToShop),
        distanceToShop: Value(distanceToShop),
        timeReceiving: Value(timeReceiving),
        timeToClient: Value(timeToClient),
        distanceToClient: Value(distanceToClient),
        timeDelivery: Value(timeDelivery),
        orderId: Value(orderId),
        status: Value(status),
        isSynced: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      final id = await db.into(db.deliveryTable).insert(companion);
      logMessage('💾 Доставка сохранена, id=$id', category: 'DATABASE');
      return id;
    } catch (e) {
      logMessage('❌ Ошибка сохранения доставки: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }

  Future<List<DeliveryTableData>> getDeliveriesByOrder(int orderId) async {
    try {
      return await (db.select(db.deliveryTable)
        ..where((t) => t.orderId.equals(orderId))
        ..orderBy([(t) => OrderingTerm.asc(t.number)])
      ).get();
    } catch (e) {
      logMessage('❌ Ошибка получения доставок: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  Future<DeliveryTableData?> getDeliveryById(int id) async {
    try {
      return await (db.select(db.deliveryTable)
        ..where((t) => t.id.equals(id))
      ).getSingleOrNull();
    } catch (e) {
      logMessage('❌ Ошибка получения доставки $id: $e', category: 'DATABASE', level: LogLevel.error);
      return null;
    }
  }

  Future<List<DeliveryTableData>> getDeliveriesByStatus(String status) async {
    try {
      return await (db.select(db.deliveryTable)
        ..where((t) => t.status.equals(status))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ).get();
    } catch (e) {
      logMessage('❌ Ошибка получения доставок по статусу: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  Future<bool> updateDelivery(int id, DeliveryTableCompanion delivery) async {
    try {
      final count = await (db.update(db.deliveryTable)
        ..where((t) => t.id.equals(id))).write(delivery);
      return count > 0;
    } catch (e) {
      logMessage('❌ Ошибка обновления доставки $id: $e', category: 'DATABASE', level: LogLevel.error);
      return false;
    }
  }

  Future<bool> deleteDelivery(int id) async {
    try {
      final count = await (db.delete(db.deliveryTable)
        ..where((t) => t.id.equals(id))
      ).go();
      return count > 0;
    } catch (e) {
      logMessage('❌ Ошибка удаления доставки $id: $e', category: 'DATABASE', level: LogLevel.error);
      return false;
    }
  }

  // ===== МЕТОДЫ ДЛЯ СИНХРОНИЗАЦИИ =====

  Future<List<DeliveryTableData>> getUnsyncedDeliveries() async {
    try {
      return await (db.select(db.deliveryTable)
        ..where((t) => t.isSynced.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ).get();
    } catch (e) {
      logMessage('❌ Ошибка получения несинхронизированных доставок: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  Future<void> markAsSynced(int localId, int serverId) async {
    try {
      await (db.update(db.deliveryTable)
        ..where((t) => t.id.equals(localId))
      ).write(
        DeliveryTableCompanion(
          serverId: Value(serverId),
          isSynced: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
      logMessage('✅ Доставка $localId синхронизирована', category: 'DATABASE');
    } catch (e) {
      logMessage('❌ Ошибка отметки доставки $localId: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }
}