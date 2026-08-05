import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final double fuelPrice;
  final double fuelConsumption;
  final double repairCost; // стоимость ремонта в рублях на 1 км

  SettingsState({
    required this.fuelPrice,
    required this.fuelConsumption,
    required this.repairCost,
  });

  SettingsState copyWith({
    double? fuelPrice,
    double? fuelConsumption,
    double? repairCost,
  }) {
    return SettingsState(
      fuelPrice: fuelPrice ?? this.fuelPrice,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      repairCost: repairCost ?? this.repairCost,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          fuelPrice: 50.0,
          fuelConsumption: 10.0,
          repairCost: 2.0,
        ));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final fuelPrice = prefs.getDouble('fuelPrice') ?? 50.0;
    final fuelConsumption = prefs.getDouble('fuelConsumption') ?? 10.0;
    final repairCost = prefs.getDouble('repairCost') ?? 2.0;
    state = SettingsState(
      fuelPrice: fuelPrice,
      fuelConsumption: fuelConsumption,
      repairCost: repairCost,
    );
  }

  Future<void> saveFuelPrice(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fuelPrice', value);
    state = state.copyWith(fuelPrice: value);
  }

  Future<void> saveFuelConsumption(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fuelConsumption', value);
    state = state.copyWith(fuelConsumption: value);
  }

  Future<void> saveRepairCost(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('repairCost', value);
    state = state.copyWith(repairCost: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final notifier = SettingsNotifier();
  notifier.load();
  return notifier;
});