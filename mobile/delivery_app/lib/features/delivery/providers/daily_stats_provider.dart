// lib/features/delivery/providers/daily_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
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

  double get totalDistance => _roundToTwo(totalPaidDistance + totalIdleDistance);
  double get avgDistancePerOrder => ordersCount > 0 ? _roundToTwo(totalPaidDistance / ordersCount) : 0.0;
  double get avgCheck => ordersCount > 0 ? _roundToTwo(totalIncome / ordersCount) : 0.0;

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

  static double _roundToTwo(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}

// ===== NOTIFIER =====
class DailyStatsNotifier extends StateNotifier<DailyStats> {
  final Ref _ref;
  bool _isDisposed = false;

  DailyStatsNotifier(this._ref) : super(DailyStats()) {
    _loadStats();
    
    // ===== ВАЖНО: Слушаем изменения shiftProvider =====
    _ref.listen(shiftProvider, (previous, next) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    if (_isDisposed) return;
    try {
      final stats = await _calculateDailyStats(_ref);
      if (!_isDisposed) {
        state = stats;
      }
    } catch (e) {
      if (!_isDisposed) {
        logMessage('❌ [STATS] Ошибка загрузки: $e', category: 'STATS', level: LogLevel.error);
      }
    }
  }

  Future<void> refresh() async {
    if (_isDisposed) return;
    try {
      final stats = await _calculateDailyStats(_ref);
      if (!_isDisposed) {
        state = stats;
      }
    } catch (e) {
      if (!_isDisposed) {
        logMessage('❌ [STATS] Ошибка обновления: $e', category: 'STATS', level: LogLevel.error);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

final dailyStatsProvider = StateNotifierProvider<DailyStatsNotifier, DailyStats>((ref) {
  return DailyStatsNotifier(ref);
});

extension DailyStatsExtensions on WidgetRef {
  Future<void> refreshStats() async {
    final notifier = read(dailyStatsProvider.notifier);
    await notifier.refresh();
  }
}

// ===== ФУНКЦИЯ РАСЧЁТА =====
Future<DailyStats> _calculateDailyStats(Ref ref) async {
  final shiftState = ref.watch(shiftProvider);
  final settings = ref.watch(settingsProvider);

  // ===== ВАЖНО: Используем ТОЛЬКО данные из shiftState =====
  int ordersCount = shiftState.ordersCount;
  double totalPaid = shiftState.totalPaidDistance;
  double totalIncome = shiftState.totalIncome;
  double totalExpenses = shiftState.totalExpenses;
  double netProfit = shiftState.netProfit;
  Duration totalOrderTime = shiftState.totalOrderTime;
  double totalIdleDistance = shiftState.totalIdleDistance;
  
  // ===== ВРЕМЯ РАБОТЫ И ПРОСТОЯ =====
  Duration totalWorkTime = shiftState.currentWorkTime;
  Duration totalIdleTime = shiftState.currentIdleTime;
  Duration totalOrderTimeFinal = shiftState.currentOrderTime;
  
  // ===== ОКРУГЛЯЕМ =====
  final roundToTwo = DailyStats._roundToTwo;

  return DailyStats(
    totalPaidDistance: roundToTwo(totalPaid),
    totalIdleDistance: roundToTwo(totalIdleDistance),
    ordersCount: ordersCount,
    totalIncome: roundToTwo(totalIncome),
    totalExpenses: roundToTwo(totalExpenses),
    netProfit: roundToTwo(netProfit),
    totalWorkTime: totalWorkTime,
    totalIdleTime: totalIdleTime,
    totalOrderTime: totalOrderTimeFinal,
  );
}