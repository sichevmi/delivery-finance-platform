import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/database/database_provider.dart';
import 'package:delivery_app/core/database/tables/settings.dart';
import 'package:delivery_app/core/database/app_database.dart';
import 'package:drift/drift.dart';

class SettingsState {
  final double fuelConsumption;
  final double fuelPrice;
  final double repairCost;
  final double additionalCosts;
  final double receivingFee;
  final double deliveryFee;
  final double pricePerKg;
  final double pricePerKm;
  final double baseCoefficient;
  final int? settingsId;
  final int? pricingId;
  final bool isLoading;
  final bool isSynced;

  const SettingsState({
    this.fuelConsumption = 10.0,
    this.fuelPrice = 50.0,
    this.repairCost = 2.0,
    this.additionalCosts = 0.0,
    this.receivingFee = 50.0,
    this.deliveryFee = 100.0,
    this.pricePerKg = 5.0,
    this.pricePerKm = 10.0,
    this.baseCoefficient = 1.0,
    this.settingsId,
    this.pricingId,
    this.isLoading = false,
    this.isSynced = true,
  });

  SettingsState copyWith({
    double? fuelConsumption,
    double? fuelPrice,
    double? repairCost,
    double? additionalCosts,
    double? receivingFee,
    double? deliveryFee,
    double? pricePerKg,
    double? pricePerKm,
    double? baseCoefficient,
    int? settingsId,
    int? pricingId,
    bool? isLoading,
    bool? isSynced,
  }) {
    return SettingsState(
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      fuelPrice: fuelPrice ?? this.fuelPrice,
      repairCost: repairCost ?? this.repairCost,
      additionalCosts: additionalCosts ?? this.additionalCosts,
      receivingFee: receivingFee ?? this.receivingFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      baseCoefficient: baseCoefficient ?? this.baseCoefficient,
      settingsId: settingsId ?? this.settingsId,
      pricingId: pricingId ?? this.pricingId,
      isLoading: isLoading ?? this.isLoading,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      state = state.copyWith(isLoading: true);
      final db = _ref.read(appDatabaseProvider);

      // Загружаем настройки
      final settings = await db.settingsDao.getActiveSettings();
      if (settings != null) {
        state = state.copyWith(
          fuelConsumption: settings.fuelConsumption,
          fuelPrice: settings.fuelPrice,
          repairCost: settings.repairCost,
          additionalCosts: settings.additionalCosts,
          settingsId: settings.id,
          isSynced: settings.isSynced,
        );
        logMessage('📁 Настройки загружены из БД (id=${settings.id})', category: 'SETTINGS');
      } else {
        logMessage('⚠️ Настройки не найдены, создаём дефолтные', category: 'SETTINGS');
        await _createDefaultSettings();
      }

      // Загружаем тарифы
      final pricing = await db.pricingDao.getActivePricing();
      if (pricing != null) {
        state = state.copyWith(
          receivingFee: pricing.receivingFee,
          deliveryFee: pricing.deliveryFee,
          pricePerKg: pricing.pricePerKg,
          pricePerKm: pricing.pricePerKm,
          baseCoefficient: pricing.baseCoefficient,
          pricingId: pricing.id,
        );
        logMessage('📁 Тарифы загружены из БД (id=${pricing.id})', category: 'SETTINGS');
      } else {
        logMessage('⚠️ Тарифы не найдены, создаём дефолтные', category: 'SETTINGS');
        await _createDefaultPricing();
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      logMessage('❌ Ошибка загрузки настроек: $e', category: 'SETTINGS', level: LogLevel.error);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _createDefaultSettings() async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final companion = SettingsTableCompanion(
        fuelConsumption: const Value(10.0),
        fuelPrice: const Value(50.0),
        repairCost: const Value(2.0),
        additionalCosts: const Value(0.0),
        name: const Value('Стандартные настройки'),
        isDefault: const Value(true),
        isActive: const Value(true),
        isSynced: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      final id = await db.settingsDao.insertSettings(companion);
      state = state.copyWith(settingsId: id);
      logMessage('💾 Дефолтные настройки созданы (id=$id)', category: 'SETTINGS');
    } catch (e) {
      logMessage('❌ Ошибка создания дефолтных настроек: $e', category: 'SETTINGS', level: LogLevel.error);
    }
  }

  Future<void> _createDefaultPricing() async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final companion = PricingTableCompanion(
        receivingFee: const Value(50.0),
        deliveryFee: const Value(100.0),
        pricePerKg: const Value(5.0),
        pricePerKm: const Value(10.0),
        baseCoefficient: const Value(1.0),
        name: const Value('Стандартный тариф'),
        isDefault: const Value(true),
        isActive: const Value(true),
        isSynced: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      final id = await db.pricingDao.insertPricing(companion);
      state = state.copyWith(pricingId: id);
      logMessage('💾 Дефолтный тариф создан (id=$id)', category: 'SETTINGS');
    } catch (e) {
      logMessage('❌ Ошибка создания дефолтного тарифа: $e', category: 'SETTINGS', level: LogLevel.error);
    }
  }

  Future<void> saveSettings() async {
    try {
      state = state.copyWith(isLoading: true);
      final db = _ref.read(appDatabaseProvider);

      // Сохраняем настройки
      final existingSettings = await db.settingsDao.getActiveSettings();
      final settingsCompanion = SettingsTableCompanion(
        id: existingSettings != null ? Value(existingSettings.id) : const Value.absent(),
        fuelConsumption: Value(state.fuelConsumption),
        fuelPrice: Value(state.fuelPrice),
        repairCost: Value(state.repairCost),
        additionalCosts: Value(state.additionalCosts),
        name: const Value('Текущие настройки'),
        isDefault: const Value(true),
        isActive: const Value(true),
        isSynced: const Value(false),
        createdAt: existingSettings != null ? Value(existingSettings.createdAt) : Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      if (existingSettings != null) {
        await db.settingsDao.updateSettings(existingSettings.id, settingsCompanion);
        state = state.copyWith(settingsId: existingSettings.id);
        logMessage('🔄 Настройки обновлены (id=${existingSettings.id})', category: 'SETTINGS');
      } else {
        final id = await db.settingsDao.insertSettings(settingsCompanion);
        state = state.copyWith(settingsId: id);
        logMessage('💾 Настройки созданы (id=$id)', category: 'SETTINGS');
      }

      // Сохраняем тарифы
      final existingPricing = await db.pricingDao.getActivePricing();
      final pricingCompanion = PricingTableCompanion(
        id: existingPricing != null ? Value(existingPricing.id) : const Value.absent(),
        receivingFee: Value(state.receivingFee),
        deliveryFee: Value(state.deliveryFee),
        pricePerKg: Value(state.pricePerKg),
        pricePerKm: Value(state.pricePerKm),
        baseCoefficient: Value(state.baseCoefficient),
        name: const Value('Текущий тариф'),
        isDefault: const Value(true),
        isActive: const Value(true),
        isSynced: const Value(false),
        createdAt: existingPricing != null ? Value(existingPricing.createdAt) : Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      if (existingPricing != null) {
        await db.pricingDao.updatePricing(existingPricing.id, pricingCompanion);
        state = state.copyWith(pricingId: existingPricing.id);
        logMessage('🔄 Тарифы обновлены (id=${existingPricing.id})', category: 'SETTINGS');
      } else {
        final id = await db.pricingDao.insertPricing(pricingCompanion);
        state = state.copyWith(pricingId: id);
        logMessage('💾 Тарифы созданы (id=$id)', category: 'SETTINGS');
      }

      state = state.copyWith(isSynced: false, isLoading: false);
      logMessage('✅ Настройки и тарифы сохранены в БД', category: 'SETTINGS');
    } catch (e) {
      logMessage('❌ Ошибка сохранения настроек: $e', category: 'SETTINGS', level: LogLevel.error);
      state = state.copyWith(isLoading: false);
    }
  }

  void updateFuelConsumption(double value) => state = state.copyWith(fuelConsumption: value);
  void updateFuelPrice(double value) => state = state.copyWith(fuelPrice: value);
  void updateRepairCost(double value) => state = state.copyWith(repairCost: value);
  void updateAdditionalCosts(double value) => state = state.copyWith(additionalCosts: value);
  void updateReceivingFee(double value) => state = state.copyWith(receivingFee: value);
  void updateDeliveryFee(double value) => state = state.copyWith(deliveryFee: value);
  void updatePricePerKg(double value) => state = state.copyWith(pricePerKg: value);
  void updatePricePerKm(double value) => state = state.copyWith(pricePerKm: value);
  void updateBaseCoefficient(double value) => state = state.copyWith(baseCoefficient: value);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});