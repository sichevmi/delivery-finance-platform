// lib/core/database/dao/delivery_dao.dart
import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/deliveries.dart';
import 'package:delivery_app/logger.dart';

class DeliveryDao {
  final AppDatabase db;

  DeliveryDao(this.db);

  // Сохранить доставку
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
      logMessage('💾 Доставка сохранена в БД, id=$id', category: 'DATABASE');
      return id;
    } catch (e) {
      logMessage('❌ Ошибка сохранения доставки: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }

  // Получить доставки по заказу
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

  // Обновить доставку
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
}