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
      }

      state = state.copyWith(isLoading: false);
      logMessage('📁 X5 настройки загружены из БД', category: 'SETTINGS');
    } catch (e) {
      logMessage('❌ Ошибка загрузки X5 настроек: $e', category: 'SETTINGS', level: LogLevel.error);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveSettings() async {
    try {
      state = state.copyWith(isLoading: true);
      final db = _ref.read(appDatabaseProvider);

      final companion = X5SettingsTableCompanion(
        pickupPrice: Value(state.pickupPrice),
        deliveryPrice: Value(state.deliveryPrice),
        perKmPrice: Value(state.perKmPrice),
        perKgPrice: Value(state.perKgPrice),
        isDefault: Value(true),
        isActive: Value(true),
        isSynced: Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      if (state.id != null) {
        await db.x5SettingsDao.updateX5Settings(state.id!, companion);
      } else {
        final id = await db.x5SettingsDao.insertX5Settings(companion);
        state = state.copyWith(id: id);
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