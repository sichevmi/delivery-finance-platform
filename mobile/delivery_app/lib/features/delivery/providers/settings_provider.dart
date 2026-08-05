import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/database/database_provider.dart';
import 'package:delivery_app/core/database/tables/pricing.dart';
import 'package:delivery_app/core/database/tables/settings.dart';
import 'package:delivery_app/core/database/app_database.dart';  // <-- ДОБАВЛЕНО
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
      }

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
      }

      state = state.copyWith(isLoading: false);
      logMessage('📁 Настройки загружены из БД', category: 'SETTINGS');
    } catch (e) {
      logMessage('❌ Ошибка загрузки настроек: $e', category: 'SETTINGS', level: LogLevel.error);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveSettings() async {
    try {
      state = state.copyWith(isLoading: true);
      final db = _ref.read(appDatabaseProvider);

      final settingsCompanion = SettingsTableCompanion(
        fuelConsumption: Value(state.fuelConsumption),
        fuelPrice: Value(state.fuelPrice),
        repairCost: Value(state.repairCost),
        additionalCosts: Value(state.additionalCosts),
        name: Value('Текущие настройки'),
        isDefault: Value(true),
        isActive: Value(true),
        isSynced: Value(false),
        updatedAt: Value(DateTime.now()),
      );

      if (state.settingsId != null) {
        await db.settingsDao.updateSettings(state.settingsId!, settingsCompanion);
      } else {
        final id = await db.settingsDao.insertSettings(settingsCompanion);
        state = state.copyWith(settingsId: id);
      }

      final pricingCompanion = PricingTableCompanion(
        receivingFee: Value(state.receivingFee),
        deliveryFee: Value(state.deliveryFee),
        pricePerKg: Value(state.pricePerKg),
        pricePerKm: Value(state.pricePerKm),
        baseCoefficient: Value(state.baseCoefficient),
        name: Value('Текущий тариф'),
        isDefault: Value(true),
        isActive: Value(true),
        isSynced: Value(false),
        updatedAt: Value(DateTime.now()),
      );

      if (state.pricingId != null) {
        await db.pricingDao.updatePricing(state.pricingId!, pricingCompanion);
      } else {
        final id = await db.pricingDao.insertPricing(pricingCompanion);
        state = state.copyWith(pricingId: id);
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