// lib/features/delivery/providers/daily_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';

class DailyStats {
  final double totalPaidDistance;
  final double totalIdleDistance;
  final int ordersCount;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final Duration totalWorkTime;
  final Duration totalIdleTime;
  final Duration totalOrderTime;

  DailyStats({
    this.totalPaidDistance = 0.0,
    this.totalIdleDistance = 0.0,
    this.ordersCount = 0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.totalWorkTime = Duration.zero,
    this.totalIdleTime = Duration.zero,
    this.totalOrderTime = Duration.zero,
  });

  DailyStats copyWith({
    double? totalPaidDistance,
    double? totalIdleDistance,
    int? ordersCount,
    double? totalIncome,
    double? totalExpenses,
    double? netProfit,
    Duration? totalWorkTime,
    Duration? totalIdleTime,
    Duration? totalOrderTime,
  }) {
    return DailyStats(
      totalPaidDistance: totalPaidDistance ?? this.totalPaidDistance,
      totalIdleDistance: totalIdleDistance ?? this.totalIdleDistance,
      ordersCount: ordersCount ?? this.ordersCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      totalWorkTime: totalWorkTime ?? this.totalWorkTime,
      totalIdleTime: totalIdleTime ?? this.totalIdleTime,
      totalOrderTime: totalOrderTime ?? this.totalOrderTime,
    );
  }

  double get totalDistance => totalPaidDistance + totalIdleDistance;
  double get avgDistancePerOrder => ordersCount > 0 ? totalPaidDistance / ordersCount : 0.0;
  double get avgCheck => ordersCount > 0 ? totalIncome / ordersCount : 0.0;

  Duration get avgTimePerOrder {
    if (ordersCount == 0) return Duration.zero;
    return Duration(
      milliseconds: (totalOrderTime.inMilliseconds / ordersCount).round()
    );
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedWorkTime => formatDuration(totalWorkTime);
  String get formattedIdleTime => formatDuration(totalIdleTime);

  String get formattedAvgTimePerOrder {
    final d = avgTimePerOrder;
    if (d == Duration.zero) return '0 мин';
    final totalSeconds = d.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds >= 30) {
      return '${minutes + 1} мин';
    } else if (minutes > 0) {
      return '$minutes мин';
    } else {
      return '$seconds сек';
    }
  }
}

// ===== NOTIFIER ДЛЯ УПРАВЛЕНИЯ СТАТИСТИКОЙ =====
class DailyStatsNotifier extends StateNotifier<DailyStats> {
  final Ref _ref;
  bool _isInitialized = false;

  DailyStatsNotifier(this._ref) : super(DailyStats()) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _calculateDailyStats(_ref);
    state = stats;
    _isInitialized = true;
    logMessage('📊 [STATS] Статистика загружена', category: 'STATS');
  }

  // Метод для принудительного обновления
  Future<void> refresh() async {
    logMessage('🔄 [STATS] Принудительное обновление статистики', category: 'STATS');
    final stats = await _calculateDailyStats(_ref);
    state = stats;
  }

  // Метод для получения текущих данных без ожидания
  DailyStats get currentStats => state;
}

// ===== ПРОВАЙДЕР =====
final dailyStatsProvider = StateNotifierProvider<DailyStatsNotifier, DailyStats>((ref) {
  return DailyStatsNotifier(ref);
});

// ===== ФУНКЦИЯ РАСЧЁТА =====
Future<DailyStats> _calculateDailyStats(Ref ref) async {
  final apiService = ApiService();
  final cache = apiService.cache;
  final shiftState = ref.watch(shiftProvider);
  final settings = ref.watch(settingsProvider);

  // ===== 1. СЧИТАЕМ ИЗ КЭША =====
  int ordersCount = cache.todayOrders.length;
  double totalPaid = 0.0;
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double netProfit = 0.0;
  Duration totalOrderTime = Duration.zero;

  for (final order in cache.todayOrders) {
    totalPaid += order.totalPaidDistance;
    totalIncome += order.totalIncome;
    totalExpenses += order.totalExpenses;
    netProfit += order.netProfit;
    totalOrderTime += order.totalTime;
  }

  // ===== 2. ПРИОРИТЕТНО ИСПОЛЬЗУЕМ ДАННЫЕ ИЗ shiftState =====
  if (shiftState.totalIncome > 0 || shiftState.totalExpenses > 0) {
  logMessage('📊 [STATS] Используем данные из shiftState (приоритет)', category: 'STATS');
  totalIncome = shiftState.totalIncome;
  totalExpenses = shiftState.totalExpenses;
  netProfit = shiftState.netProfit;
  ordersCount = shiftState.ordersCount;
  totalPaid = shiftState.totalPaidDistance;
  // Холостой пробег берём из shiftState
  totalIdle = shiftState.totalIdleDistance;
}

  // ===== 3. ВРЕМЯ РАБОТЫ =====
  Duration totalWorkTime = Duration.zero;
  double totalIdle = 0.0;
  Duration totalIdleTime = Duration.zero;

  if (shiftState.isActive) {
    totalWorkTime = shiftState.workTime;
    totalIdle = shiftState.totalIdleDistance;
    totalIdleTime = shiftState.totalIdleTimeDisplay;
  } else {
    if (cache.activeShift != null) {
      totalWorkTime = cache.activeShift!.duration ?? Duration.zero;
      totalIdle = cache.activeShift!.totalIdleDistance;
    }
    if (shiftState.totalWorkTime > Duration.zero) {
      totalWorkTime = shiftState.totalWorkTime;
      totalIdle = shiftState.totalIdleDistance;
    }
  }

  // ===== 4. ВРЕМЯ ПРОСТОЯ =====
  Duration totalIdleTimeFromCache = Duration.zero;
  for (final shift in cache.todayShifts) {
    if (shift.totalIdleTime != null) {
      totalIdleTimeFromCache += shift.totalIdleTime!;
    }
  }

  if (totalIdleTimeFromCache > Duration.zero) {
    totalIdleTime = totalIdleTimeFromCache;
  } else if (shiftState.totalIdleTime > Duration.zero) {
    totalIdleTime = shiftState.totalIdleTime;
  }

  return DailyStats(
    totalPaidDistance: totalPaid,
    totalIdleDistance: totalIdle,
    ordersCount: ordersCount,
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    netProfit: netProfit,
    totalWorkTime: totalWorkTime,
    totalIdleTime: totalIdleTime,
    totalOrderTime: totalOrderTime,
  );
}

// ===== ХЕЛПЕР ДЛЯ ОБНОВЛЕНИЯ =====
final refreshStatsProvider = Provider<void>((ref) {
  return null;
});

extension DailyStatsExtensions on WidgetRef {
  Future<void> refreshStats() async {
    final notifier = read(dailyStatsProvider.notifier);
    await notifier.refresh();
  }
}