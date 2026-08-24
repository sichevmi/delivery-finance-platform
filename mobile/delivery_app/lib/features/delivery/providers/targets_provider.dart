// lib/features/delivery/providers/targets_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TargetsState {
  final double loadFactorGreen;    // > 65%
  final double loadFactorYellow;   // 40-65%
  final double ordersPerHourGreen; // > 2.5
  final double ordersPerHourYellow; // 1.5-2.5
  final double profitPerHourGreen; // > 1000
  final double profitPerHourYellow; // 500-1000

  const TargetsState({
    this.loadFactorGreen = 65.0,
    this.loadFactorYellow = 40.0,
    this.ordersPerHourGreen = 2.5,
    this.ordersPerHourYellow = 1.5,
    this.profitPerHourGreen = 1000.0,
    this.profitPerHourYellow = 500.0,
  });

  TargetsState copyWith({
    double? loadFactorGreen,
    double? loadFactorYellow,
    double? ordersPerHourGreen,
    double? ordersPerHourYellow,
    double? profitPerHourGreen,
    double? profitPerHourYellow,
  }) {
    return TargetsState(
      loadFactorGreen: loadFactorGreen ?? this.loadFactorGreen,
      loadFactorYellow: loadFactorYellow ?? this.loadFactorYellow,
      ordersPerHourGreen: ordersPerHourGreen ?? this.ordersPerHourGreen,
      ordersPerHourYellow: ordersPerHourYellow ?? this.ordersPerHourYellow,
      profitPerHourGreen: profitPerHourGreen ?? this.profitPerHourGreen,
      profitPerHourYellow: profitPerHourYellow ?? this.profitPerHourYellow,
    );
  }

  Map<String, dynamic> toJson() => {
    'loadFactorGreen': loadFactorGreen,
    'loadFactorYellow': loadFactorYellow,
    'ordersPerHourGreen': ordersPerHourGreen,
    'ordersPerHourYellow': ordersPerHourYellow,
    'profitPerHourGreen': profitPerHourGreen,
    'profitPerHourYellow': profitPerHourYellow,
  };

  factory TargetsState.fromJson(Map<String, dynamic> json) => TargetsState(
    loadFactorGreen: (json['loadFactorGreen'] ?? 65.0).toDouble(),
    loadFactorYellow: (json['loadFactorYellow'] ?? 40.0).toDouble(),
    ordersPerHourGreen: (json['ordersPerHourGreen'] ?? 2.5).toDouble(),
    ordersPerHourYellow: (json['ordersPerHourYellow'] ?? 1.5).toDouble(),
    profitPerHourGreen: (json['profitPerHourGreen'] ?? 1000.0).toDouble(),
    profitPerHourYellow: (json['profitPerHourYellow'] ?? 500.0).toDouble(),
  );
}

class TargetsNotifier extends StateNotifier<TargetsState> {
  TargetsNotifier() : super(const TargetsState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('targets_settings');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          jsonDecode(jsonStr) as Map
        );
        state = TargetsState.fromJson(data);
        logMessage('📁 [TARGETS] Загружены целевые показатели', category: 'TARGETS');
      }
    } catch (e) {
      logMessage('⚠️ [TARGETS] Ошибка загрузки: $e', category: 'TARGETS');
    }
  }

  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('targets_settings', jsonEncode(state.toJson()));
      logMessage('💾 [TARGETS] Целевые показатели сохранены', category: 'TARGETS');
    } catch (e) {
      logMessage('⚠️ [TARGETS] Ошибка сохранения: $e', category: 'TARGETS');
    }
  }

  void updateLoadFactorGreen(double value) {
    state = state.copyWith(loadFactorGreen: value);
    saveSettings();
  }
  void updateLoadFactorYellow(double value) {
    state = state.copyWith(loadFactorYellow: value);
    saveSettings();
  }
  void updateOrdersPerHourGreen(double value) {
    state = state.copyWith(ordersPerHourGreen: value);
    saveSettings();
  }
  void updateOrdersPerHourYellow(double value) {
    state = state.copyWith(ordersPerHourYellow: value);
    saveSettings();
  }
  void updateProfitPerHourGreen(double value) {
    state = state.copyWith(profitPerHourGreen: value);
    saveSettings();
  }
  void updateProfitPerHourYellow(double value) {
    state = state.copyWith(profitPerHourYellow: value);
    saveSettings();
  }
}

final targetsProvider = StateNotifierProvider<TargetsNotifier, TargetsState>((ref) {
  return TargetsNotifier();
});