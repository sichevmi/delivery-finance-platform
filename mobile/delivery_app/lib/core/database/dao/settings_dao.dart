import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/settings.dart';
import 'package:delivery_app/logger.dart';

class SettingsDao {
  final AppDatabase db;

  SettingsDao(this.db);

  Future<int> insertSettings(SettingsTableCompanion settings) async {
    try {
      final id = await db.into(db.settingsTable).insert(settings);
      logMessage('💾 Настройки сохранены, id=$id', category: 'DATABASE');
      return id;
    } catch (e) {
      logMessage('❌ Ошибка сохранения настроек: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }

  Future<SettingsTableData?> getActiveSettings() async {
  try {
    final result = await (db.select(db.settingsTable)
      ..where((t) => t.isDefault.equals(true))
      ..where((t) => t.isActive.equals(true))
      ..limit(1)).getSingleOrNull();
    
    if (result != null) {
      logMessage('📖 Загружены настройки из БД:', category: 'DATABASE');
      logMessage('  id: ${result.id}', category: 'DATABASE');
      logMessage('  fuelConsumption: ${result.fuelConsumption}', category: 'DATABASE');
      logMessage('  fuelPrice: ${result.fuelPrice}', category: 'DATABASE');
      logMessage('  repairCost: ${result.repairCost}', category: 'DATABASE');
      logMessage('  additionalCosts: ${result.additionalCosts}', category: 'DATABASE');
    } else {
      logMessage('⚠️ Настройки не найдены в БД', category: 'DATABASE');
    }
    
    return result;
  } catch (e) {
    logMessage('❌ Ошибка получения настроек: $e', category: 'DATABASE', level: LogLevel.error);
    return null;
  }
}

  Future<List<SettingsTableData>> getAllSettings() async {
    try {
      return await (db.select(db.settingsTable)
        ..orderBy([
          (t) => OrderingTerm.desc(t.isDefault),
          (t) => OrderingTerm.desc(t.id)
        ])).get();
    } catch (e) {
      logMessage('❌ Ошибка получения настроек: $e', category: 'DATABASE', level: LogLevel.error);
      return [];
    }
  }

  // Обновление настроек через update (сохраняя id)
  Future<bool> updateSettings(int id, SettingsTableCompanion settings) async {
  try {
    logMessage('🔍 Обновляем настройки id=$id:', category: 'DATABASE');
    logMessage('  fuelConsumption: ${settings.fuelConsumption.value}', category: 'DATABASE');
    logMessage('  fuelPrice: ${settings.fuelPrice.value}', category: 'DATABASE');
    logMessage('  repairCost: ${settings.repairCost.value}', category: 'DATABASE');
    logMessage('  additionalCosts: ${settings.additionalCosts.value}', category: 'DATABASE');

    final count = await (db.update(db.settingsTable)
      ..where((t) => t.id.equals(id))).write(settings);
    
    logMessage('🔄 Настройки $id обновлены, затронуто строк: $count', category: 'DATABASE');
    return count > 0;
  } catch (e) {
    logMessage('❌ Ошибка обновления настроек: $e', category: 'DATABASE', level: LogLevel.error);
    return false;
  }
}
}