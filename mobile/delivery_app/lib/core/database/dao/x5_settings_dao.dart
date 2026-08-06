import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:delivery_app/core/database/tables/x5_settings.dart';
import 'package:delivery_app/logger.dart';

class X5SettingsDao {
  final AppDatabase db;

  X5SettingsDao(this.db);

  Future<int> insertX5Settings(X5SettingsTableCompanion settings) async {
    try {
      final id = await db.into(db.x5SettingsTable).insert(settings);
      logMessage('💾 X5 настройки сохранены, id=$id', category: 'DATABASE');
      return id;
    } catch (e) {
      logMessage('❌ Ошибка сохранения X5 настроек: $e', category: 'DATABASE', level: LogLevel.error);
      rethrow;
    }
  }

  Future<X5SettingsTableData?> getActiveX5Settings() async {
    try {
      return await (db.select(db.x5SettingsTable)
        ..where((t) => t.isDefault.equals(true))
        ..where((t) => t.isActive.equals(true))
        ..limit(1)).getSingleOrNull();
    } catch (e) {
      logMessage('❌ Ошибка получения X5 настроек: $e', category: 'DATABASE', level: LogLevel.error);
      return null;
    }
  }

  Future<bool> updateX5Settings(int id, X5SettingsTableCompanion settings) async {
    try {
      // Используем update вместо delete+insert
      final count = await (db.update(db.x5SettingsTable)
        ..where((t) => t.id.equals(id))).write(settings);
      
      if (count > 0) {
        logMessage('🔄 X5 настройки $id обновлены (update)', category: 'DATABASE');
        return true;
      } else {
        logMessage('⚠️ X5 настройки $id не найдены для обновления', category: 'DATABASE');
        return false;
      }
    } catch (e) {
      logMessage('❌ Ошибка обновления X5 настроек $id: $e', category: 'DATABASE', level: LogLevel.error);
      return false;
    }
  }
}