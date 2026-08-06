import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/pricing.dart';
import 'package:delivery_app/logger.dart';

class PricingDao {
  final AppDatabase db;

  PricingDao(this.db);

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

  Future<bool> updatePricing(int id, PricingTableCompanion pricing) async {
    try {
      final count = await (db.update(db.pricingTable)
        ..where((t) => t.id.equals(id))).write(pricing);
      
      if (count > 0) {
        logMessage('🔄 Тариф $id обновлён (update)', category: 'DATABASE');
        return true;
      } else {
        logMessage('⚠️ Тариф $id не найден для обновления', category: 'DATABASE');
        return false;
      }
    } catch (e) {
      logMessage('❌ Ошибка обновления тарифа $id: $e', category: 'DATABASE', level: LogLevel.error);
      return false;
    }
  }
}