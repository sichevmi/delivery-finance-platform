import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/pricing.dart';
import 'package:delivery_app/logger.dart';

class PricingDao {
  final AppDatabase db;

  PricingDao(this.db);

  // Вставка новой записи
  Future<int> insertPricing(PricingTableCompanion pricing) async {
    try {
      final id = await db.into(db.pricingTable).insert(pricing);
      logMessage('💾 Тариф сохранён, id=$id', category: 'DATABASE');
      return id;
    } catch (e) {
      logMessage('❌ Ошибка сохранения тарифа: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }

  // Получение активного тарифа
  Future<PricingTableData?> getActivePricing() async {
    try {
      return await (db.select(db.pricingTable)
        ..where((t) => t.isDefault.equals(true))
        ..where((t) => t.isActive.equals(true))
        ..limit(1)).getSingleOrNull();
    } catch (e) {
      logMessage('❌ Ошибка получения тарифа: $e', category: 'DATABASE', level: LogLevel.error);
      return null;
    }
  }

  // Получение всех тарифов
  Future<List<PricingTableData>> getAllPricings() async {
    try {
      return await (db.select(db.pricingTable)
        ..orderBy([
          (t) => OrderingTerm.desc(t.isDefault),
          (t) => OrderingTerm.desc(t.id)
        ])).get();
    } catch (e) {
      logMessage('❌ Ошибка получения тарифов: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  // Обновление тарифа через delete + insert
  Future<bool> updatePricing(int id, PricingTableCompanion pricing) async {
    try {
      // Удаляем старую запись
      await (db.delete(db.pricingTable)..where((t) => t.id.equals(id))).go();
      
      // Вставляем новую с тем же id
      await db.into(db.pricingTable).insert(pricing);
      
      logMessage('🔄 Тариф $id обновлён (delete+insert)', category: 'DATABASE');
      return true;
    } catch (e) {
      logMessage('❌ Ошибка обновления тарифа $id: $e', category: 'DATABASE', level: LogLevel.error);
      return false;
    }
  }
}