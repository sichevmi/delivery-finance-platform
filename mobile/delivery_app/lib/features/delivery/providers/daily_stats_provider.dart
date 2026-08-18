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

  Future<void> refresh() async {
    logMessage('🔄 [STATS] Принудительное обновление статистики', category: 'STATS');
    final stats = await _calculateDailyStats(_ref);
    state = stats;
  }

  DailyStats get currentStats => state;
}

final dailyStatsProvider = StateNotifierProvider<DailyStatsNotifier, DailyStats>((ref) {
  return DailyStatsNotifier(ref);
});

// ===== РАСШИРЕНИЕ ДЛЯ ОБНОВЛЕНИЯ =====
extension DailyStatsExtensions on WidgetRef {
  Future<void> refreshStats() async {
    final notifier = read(dailyStatsProvider.notifier);
    await notifier.refresh();
  }
}

// ===== ФУНКЦИЯ РАСЧЁТА =====
Future<DailyStats> _calculateDailyStats(Ref ref) async {
  final apiService = ApiService();
  final cache = apiService.cache;
  final shiftState = ref.watch(shiftProvider);
  final settings = ref.watch(settingsProvider);

  logMessage('📊 [STATS] _calculateDailyStats() начат', category: 'STATS');
  logMessage('📊 [STATS] cache.todayOrders.length=${cache.todayOrders.length}', category: 'STATS');
  logMessage('📊 [STATS] cache.todayShifts.length=${cache.todayShifts.length}', category: 'STATS');
  logMessage('📊 [STATS] shiftState.ordersCount=${shiftState.ordersCount}', category: 'STATS');
  logMessage('📊 [STATS] shiftState.totalIncome=${shiftState.totalIncome}', category: 'STATS');
  logMessage('📊 [STATS] shiftState.totalExpenses=${shiftState.totalExpenses}', category: 'STATS');
  logMessage('📊 [STATS] shiftState.netProfit=${shiftState.netProfit}', category: 'STATS');
  logMessage('📊 [STATS] shiftState.totalIdleDistance=${shiftState.totalIdleDistance}', category: 'STATS');

  // ===== 1. СЧИТАЕМ ИЗ КЭША =====
  int ordersCount = cache.todayOrders.length;
  double totalPaid = 0.0;
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double netProfit = 0.0;
  Duration totalOrderTime = Duration.zero;
  double totalIdleDistance = 0.0;

  for (final order in cache.todayOrders) {
    totalPaid += order.totalPaidDistance;
    totalIncome += order.totalIncome;
    totalExpenses += order.totalExpenses;
    netProfit += order.netProfit;
    totalOrderTime += order.totalTime;
  }

  logMessage('📊 [STATS] После кэша: ordersCount=$ordersCount, totalIncome=$totalIncome, totalExpenses=$totalExpenses, netProfit=$netProfit', category: 'STATS');

  // ===== 2. ПРИОРИТЕТНО ИСПОЛЬЗУЕМ ДАННЫЕ ИЗ shiftState =====
  if (shiftState.totalIncome > 0 || shiftState.totalExpenses > 0) {
    logMessage('📊 [STATS] Используем данные из shiftState (приоритет)', category: 'STATS');
    totalIncome = shiftState.totalIncome;
    totalExpenses = shiftState.totalExpenses;
    netProfit = shiftState.netProfit;
    ordersCount = shiftState.ordersCount;
    totalPaid = shiftState.totalPaidDistance;
    totalIdleDistance = shiftState.totalIdleDistance;
  }

  logMessage('📊 [STATS] После shiftState: ordersCount=$ordersCount, totalIncome=$totalIncome, totalExpenses=$totalExpenses, netProfit=$netProfit', category: 'STATS');

  // ===== 3. ВРЕМЯ РАБОТЫ =====
  Duration totalWorkTime = Duration.zero;
  Duration totalIdleTime = Duration.zero;

  if (shiftState.isActive) {
    totalWorkTime = shiftState.workTime;
    totalIdleTime = shiftState.totalIdleTimeDisplay;
    // Если смена активна, холостой пробег уже взят из shiftState выше
  } else {
    if (cache.activeShift != null) {
      totalWorkTime = cache.activeShift!.duration ?? Duration.zero;
    }
    if (shiftState.totalWorkTime > Duration.zero) {
      totalWorkTime = shiftState.totalWorkTime;
    }
    // Время простоя из кэша
    Duration totalIdleTimeFromCache = Duration.zero;
    for (final shift in cache.todayShifts) {
      if (shift.totalIdleTime != null) {
        totalIdleTimeFromCache += shift.totalIdleTime!;
        logMessage('📊 [STATS] Смена ${shift.id}: idleTime=${shift.totalIdleTime!.inSeconds} сек', category: 'STATS');
      }
    }
    if (totalIdleTimeFromCache > Duration.zero) {
      totalIdleTime = totalIdleTimeFromCache;
      logMessage('📊 [STATS] Восстановлено время простоя из кэша: ${totalIdleTime.inSeconds} сек', category: 'STATS');
    } else if (shiftState.totalIdleTime > Duration.zero) {
      totalIdleTime = shiftState.totalIdleTime;
    }
  }

  logMessage('📊 [STATS] ФИНАЛЬНЫЕ ДАННЫЕ: заказов=$ordersCount, пробег=$totalPaid, доход=$totalIncome, расходы=$totalExpenses, прибыль=$netProfit, холостой пробег=$totalIdleDistance, время простоя=${totalIdleTime.inSeconds} сек', category: 'STATS');

  return DailyStats(
    totalPaidDistance: totalPaid,
    totalIdleDistance: totalIdleDistance,
    ordersCount: ordersCount,
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    netProfit: netProfit,
    totalWorkTime: totalWorkTime,
    totalIdleTime: totalIdleTime,
    totalOrderTime: totalOrderTime,
  );
}