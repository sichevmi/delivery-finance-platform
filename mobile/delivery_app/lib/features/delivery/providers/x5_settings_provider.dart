import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/database/database_provider.dart';
import 'package:delivery_app/core/database/tables/x5_settings.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:drift/drift.dart';

class X5SettingsState {
  final double pickupPrice;
  final double deliveryPrice;
  final double perKmPrice;
  final double perKgPrice;
  final int? id;
  final bool isLoading;
  final bool isSynced;

  const X5SettingsState({
    this.pickupPrice = 250.0,
    this.deliveryPrice = 150.0,
    this.perKmPrice = 25.0,
    this.perKgPrice = 10.0,
    this.id,
    this.isLoading = false,
    this.isSynced = true,
  });

  X5SettingsState copyWith({
    double? pickupPrice,
    double? deliveryPrice,
    double? perKmPrice,
    double? perKgPrice,
    int? id,
    bool? isLoading,
    bool? isSynced,
  }) {
    return X5SettingsState(
      pickupPrice: pickupPrice ?? this.pickupPrice,
      deliveryPrice: deliveryPrice ?? this.deliveryPrice,
      perKmPrice: perKmPrice ?? this.perKmPrice,
      perKgPrice: perKgPrice ?? this.perKgPrice,
      id: id ?? this.id,
      isLoading: isLoading ?? this.isLoading,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class X5SettingsNotifier extends StateNotifier<X5SettingsState> {
  final Ref _ref;

  X5SettingsNotifier(this._ref) : super(const X5SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      state = state.copyWith(isLoading: true);
      final db = _ref.read(appDatabaseProvider);

      // Ищем активную запись (isDefault = true, isActive = true)
      final settings = await db.x5SettingsDao.getActiveX5Settings();
      
      if (settings != null) {
        state = state.copyWith(
          pickupPrice: settings.pickupPrice,
          deliveryPrice: settings.deliveryPrice,
          perKmPrice: settings.perKmPrice,
          perKgPrice: settings.perKgPrice,
          id: settings.id,
          isSynced: settings.isSynced,
        );
        logMessage('📁 X5 настройки загружены из БД (id=${settings.id})', category: 'SETTINGS');
      } else {
        // Если нет активной записи — создаём дефолтную
        logMessage('⚠️ X5 настройки не найдены, создаём дефолтные', category: 'SETTINGS');
        await _createDefaultSettings();
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      logMessage('❌ Ошибка загрузки X5 настроек: $e', category: 'SETTINGS', level: LogLevel.error);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _createDefaultSettings() async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final companion = X5SettingsTableCompanion(
        pickupPrice: const Value(250.0),
        deliveryPrice: const Value(150.0),
        perKmPrice: const Value(25.0),
        perKgPrice: const Value(10.0),
        isDefault: const Value(true),
        isActive: const Value(true),
        isSynced: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      final id = await db.x5SettingsDao.insertX5Settings(companion);
      state = state.copyWith(id: id);
      logMessage('💾 Дефолтные X5 настройки созданы (id=$id)', category: 'SETTINGS');
    } catch (e) {
      logMessage('❌ Ошибка создания дефолтных X5 настроек: $e', category: 'SETTINGS', level: LogLevel.error);
    }
  }

  Future<void> saveSettings() async {
    try {
      state = state.copyWith(isLoading: true);
      final db = _ref.read(appDatabaseProvider);

      // Получаем текущую запись, чтобы сохранить id
      final existing = await db.x5SettingsDao.getActiveX5Settings();
      
      // Создаём companion с сохранением id
      final companion = X5SettingsTableCompanion(
        id: existing != null ? Value(existing.id) : const Value.absent(),
        pickupPrice: Value(state.pickupPrice),
        deliveryPrice: Value(state.deliveryPrice),
        perKmPrice: Value(state.perKmPrice),
        perKgPrice: Value(state.perKgPrice),
        isDefault: const Value(true),
        isActive: const Value(true),
        isSynced: const Value(false),
        createdAt: existing != null ? Value(existing.createdAt) : Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      if (existing != null) {
        // Используем update вместо delete+insert, чтобы сохранить id
        await db.x5SettingsDao.updateX5Settings(existing.id, companion);
        state = state.copyWith(id: existing.id);
        logMessage('🔄 X5 настройки обновлены (id=${existing.id})', category: 'SETTINGS');
      } else {
        final id = await db.x5SettingsDao.insertX5Settings(companion);
        state = state.copyWith(id: id);
        logMessage('💾 X5 настройки созданы (id=$id)', category: 'SETTINGS');
      }

      state = state.copyWith(isSynced: false, isLoading: false);
      logMessage('✅ X5 настройки сохранены в БД', category: 'SETTINGS');
    } catch (e) {
      logMessage('❌ Ошибка сохранения X5 настроек: $e', category: 'SETTINGS', level: LogLevel.error);
      state = state.copyWith(isLoading: false);
    }
  }

  void updatePickupPrice(double value) => state = state.copyWith(pickupPrice: value);
  void updateDeliveryPrice(double value) => state = state.copyWith(deliveryPrice: value);
  void updatePerKmPrice(double value) => state = state.copyWith(perKmPrice: value);
  void updatePerKgPrice(double value) => state = state.copyWith(perKgPrice: value);
}

final x5SettingsProvider = StateNotifierProvider<X5SettingsNotifier, X5SettingsState>((ref) {
  return X5SettingsNotifier(ref);
});