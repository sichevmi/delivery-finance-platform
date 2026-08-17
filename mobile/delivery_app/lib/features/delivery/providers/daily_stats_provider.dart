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

final dailyStatsProvider = FutureProvider<DailyStats>((ref) {
  logMessage('📊 Пересчёт дневной статистики', category: 'STATS');
  return _calculateDailyStats(ref);
});

Future<DailyStats> _calculateDailyStats(Ref ref) async {
  final apiService = ApiService();
  final cache = apiService.cache;
  final shiftState = ref.watch(shiftProvider);
  final settings = ref.watch(settingsProvider);

  // ===== 1. СЧИТАЕМ ИЗ КЭША (заказы с сервера) =====
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

  // ===== 2. ДОБАВЛЯЕМ ДАННЫЕ ИЗ shiftState (текущие накопления) =====
  // Если смена активна или есть данные в shiftState, суммируем их
  if (shiftState.isActive || shiftState.ordersCount > 0) {
    // Используем данные из shiftState, но не дублируем заказы
    // shiftState.ordersCount - это заказы, сделанные в текущей сессии
    // Они ещё могут не быть в кэше, поэтому добавляем их отдельно
    
    // Но чтобы не дублировать, проверяем: если заказы из кэша уже есть,
    // а shiftState показывает больше заказов - значит есть несинхронизированные
    final shiftOrdersCount = shiftState.ordersCount;
    final cachedOrdersCount = cache.todayOrders.length;
    
    // Если в shiftState больше заказов, чем в кэше, добавляем недостающие
    // Но мы не можем просто добавить недостающие, т.к. у нас нет их данных в shiftState
    // Поэтому используем данные из shiftState как основные для дохода/расходов
    // и добавляем их к данным из кэша
    
    // Однако в shiftState мы храним полные накопления (totalIncome, totalExpenses, netProfit)
    // Поэтому используем их как основные, если они больше нуля
    if (shiftState.totalIncome > 0 || shiftState.totalExpenses > 0) {
      // Используем данные из shiftState как основные
      // Но нужно быть осторожным: если есть заказы в кэше, они уже учтены
      // Поэтому берём максимум или сумму
      // Лучше всего: если shiftState показывает больше - используем его данные
      if (shiftState.totalIncome > totalIncome || shiftState.ordersCount > cachedOrdersCount) {
        // Заменяем данные из кэша данными из shiftState
        totalIncome = shiftState.totalIncome;
        totalExpenses = shiftState.totalExpenses;
        netProfit = shiftState.netProfit;
        // ordersCount берём из shiftState, т.к. там актуальное количество
        ordersCount = shiftState.ordersCount;
        // Пробег тоже берём из shiftState
        totalPaid = shiftState.totalPaidDistance;
      }
    }
    
    // Время работы и холостой пробег
    if (shiftState.isActive) {
      // Если смена активна, время работы считается в реальном времени
      // totalWorkTime будет добавлено позже
    }
  }

  // ===== 3. ВРЕМЯ РАБОТЫ И ХОЛОСТОЙ ПРОБЕГ =====
  Duration totalWorkTime = Duration.zero;
  double totalIdle = 0.0;
  Duration totalIdleTime = Duration.zero;

  if (shiftState.isActive) {
    totalWorkTime = shiftState.workTime;
    totalIdle = shiftState.totalIdleDistance;
    totalIdleTime = shiftState.totalIdleTimeDisplay;
  } else {
    // Если смена не активна, берём данные из кэша
    if (cache.activeShift != null) {
      totalWorkTime = cache.activeShift!.duration ?? Duration.zero;
      totalIdle = cache.activeShift!.totalIdleDistance;
    }
    // Также добавляем накопленное время из shiftState (если смена была завершена)
    if (shiftState.totalWorkTime > Duration.zero) {
      totalWorkTime = shiftState.totalWorkTime;
      totalIdle = shiftState.totalIdleDistance;
    }
  }

  logMessage('📊 Дневная статистика: заказов=$ordersCount, пробег=$totalPaid, доход=$totalIncome, расходы=$totalExpenses, прибыль=$netProfit', category: 'STATS');

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