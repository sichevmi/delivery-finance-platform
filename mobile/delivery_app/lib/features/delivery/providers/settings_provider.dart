import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/models/settings.dart';
import 'package:delivery_app/features/delivery/models/pricing.dart';

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
  final bool isSynced;

  SettingsState({
    this.fuelConsumption = 10.0,
    this.fuelPrice = 50.0,
    this.repairCost = 2.0,
    this.additionalCosts = 0.0,
    this.receivingFee = 50.0,
    this.deliveryFee = 100.0,
    this.pricePerKg = 5.0,
    this.pricePerKm = 10.0,
    this.baseCoefficient = 1.0,
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
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;
  final ApiService _apiService = ApiService();

  SettingsNotifier(this._ref) : super(SettingsState()) {
    _loadFromCache();
  }

  void _loadFromCache() {
    final cache = _apiService.cache;
    state = SettingsState(
      fuelConsumption: cache.settings.fuelConsumption,
      fuelPrice: cache.settings.fuelPrice,
      repairCost: cache.settings.repairCost,
      additionalCosts: cache.settings.additionalCosts,
      receivingFee: cache.pricing.receivingFee,
      deliveryFee: cache.pricing.deliveryFee,
      pricePerKg: cache.pricing.pricePerKg,
      pricePerKm: cache.pricing.pricePerKm,
      baseCoefficient: cache.pricing.baseCoefficient,
      isSynced: true,
    );
  }

  Future<void> saveSettings() async {
    try {
      // Сохраняем настройки
      final settingsResponse = await _apiService.apiClient.updateSettings({
        'fuelConsumption': state.fuelConsumption,
        'fuelPrice': state.fuelPrice,
        'repairCost': state.repairCost,
        'additionalCosts': state.additionalCosts,
      });
      if (settingsResponse['status'] == 'success') {
        _apiService.cache.settings = Settings.fromJson(settingsResponse['settings']);
      }

      // Сохраняем тарифы
      final pricingResponse = await _apiService.apiClient.updatePricing({
        'receivingFee': state.receivingFee,
        'deliveryFee': state.deliveryFee,
        'pricePerKg': state.pricePerKg,
        'pricePerKm': state.pricePerKm,
        'baseCoefficient': state.baseCoefficient,
      });
      if (pricingResponse['status'] == 'success') {
        _apiService.cache.pricing = PricingConfig.fromJson(pricingResponse['pricing']);
      }

      state = state.copyWith(isSynced: true);
      logMessage('✅ Настройки сохранены на сервере', category: 'SETTINGS');
    } catch (e) {
      logMessage('❌ Ошибка сохранения настроек: $e', category: 'SETTINGS', level: LogLevel.error);
    }
  }

  void updateFuelConsumption(double value) => state = state.copyWith(fuelConsumption: value, isSynced: false);
  void updateFuelPrice(double value) => state = state.copyWith(fuelPrice: value, isSynced: false);
  void updateRepairCost(double value) => state = state.copyWith(repairCost: value, isSynced: false);
  void updateAdditionalCosts(double value) => state = state.copyWith(additionalCosts: value, isSynced: false);
  void updateReceivingFee(double value) => state = state.copyWith(receivingFee: value, isSynced: false);
  void updateDeliveryFee(double value) => state = state.copyWith(deliveryFee: value, isSynced: false);
  void updatePricePerKg(double value) => state = state.copyWith(pricePerKg: value, isSynced: false);
  void updatePricePerKm(double value) => state = state.copyWith(pricePerKm: value, isSynced: false);
  void updateBaseCoefficient(double value) => state = state.copyWith(baseCoefficient: value, isSynced: false);
}