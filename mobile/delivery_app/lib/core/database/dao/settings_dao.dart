import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/settings.dart';
import 'package:delivery_app/logger.dart';

class SettingsDao {
  final AppDatabase db;

  SettingsDao(this.db);

  // Вставка новой записи
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

  // Получение активных настроек
  Future<SettingsTableData?> getActiveSettings() async {
    try {
      return await (db.select(db.settingsTable)
        ..where((t) => t.isDefault.equals(true))
        ..where((t) => t.isActive.equals(true))
        ..limit(1)).getSingleOrNull();
    } catch (e) {
      logMessage('❌ Ошибка получения настроек: $e', category: 'DATABASE', level: LogLevel.error);
      return null;
    }
  }

  // Получение всех настроек
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

  // Обновление настроек через delete + insert
  Future<bool> updateSettings(int id, SettingsTableCompanion settings) async {
    try {
      // Удаляем старую запись
      await (db.delete(db.settingsTable)..where((t) => t.id.equals(id))).go();
      
      // Вставляем новую с тем же id
      await db.into(db.settingsTable).insert(settings);
      
      logMessage('🔄 Настройки $id обновлены (delete+insert)', category: 'DATABASE');
      return true;
    } catch (e) {
      logMessage('❌ Ошибка обновления настроек $id: $e', category: 'DATABASE', level: LogLevel.error);
      return false;
    }
  }
}