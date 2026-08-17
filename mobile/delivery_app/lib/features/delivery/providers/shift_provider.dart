import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';

class ShiftState {
  final bool isActive;
  final DateTime? shiftStartTime;
  final DateTime? shiftEndTime;
  final Duration totalWorkTime;
  final Duration totalIdleTime;
  final DateTime? idleStartTime;
  final bool isOnOrder;
  final DateTime? orderStartTime;
  final Duration totalOrderTime;
  final double totalPaidDistance;
  final double totalIdleDistance;
  final double processedIdleDistance;
  final int ordersCount;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final int? shiftId;

  const ShiftState({
    this.isActive = false,
    this.shiftStartTime,
    this.shiftEndTime,
    this.totalWorkTime = Duration.zero,
    this.totalIdleTime = Duration.zero,
    this.idleStartTime,
    this.isOnOrder = false,
    this.orderStartTime,
    this.totalOrderTime = Duration.zero,
    this.totalPaidDistance = 0.0,
    this.totalIdleDistance = 0.0,
    this.processedIdleDistance = 0.0,
    this.ordersCount = 0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.shiftId,
  });

  ShiftState copyWith({
    bool? isActive,
    DateTime? shiftStartTime,
    DateTime? shiftEndTime,
    Duration? totalWorkTime,
    Duration? totalIdleTime,
    DateTime? idleStartTime,
    bool? isOnOrder,
    DateTime? orderStartTime,
    Duration? totalOrderTime,
    double? totalPaidDistance,
    double? totalIdleDistance,
    double? processedIdleDistance,
    int? ordersCount,
    double? totalIncome,
    double? totalExpenses,
    double? netProfit,
    int? shiftId,
  }) {
    return ShiftState(
      isActive: isActive ?? this.isActive,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      totalWorkTime: totalWorkTime ?? this.totalWorkTime,
      totalIdleTime: totalIdleTime ?? this.totalIdleTime,
      idleStartTime: idleStartTime ?? this.idleStartTime,
      isOnOrder: isOnOrder ?? this.isOnOrder,
      orderStartTime: orderStartTime ?? this.orderStartTime,
      totalOrderTime: totalOrderTime ?? this.totalOrderTime,
      totalPaidDistance: totalPaidDistance ?? this.totalPaidDistance,
      totalIdleDistance: totalIdleDistance ?? this.totalIdleDistance,
      processedIdleDistance: processedIdleDistance ?? this.processedIdleDistance,
      ordersCount: ordersCount ?? this.ordersCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      shiftId: shiftId ?? this.shiftId,
    );
  }

  // ===== ВЫЧИСЛЯЕМЫЕ ПОЛЯ =====

  double get unprocessedIdleDistance => totalIdleDistance - processedIdleDistance;

  Duration get workTime {
    if (!isActive || shiftStartTime == null) {
      return totalWorkTime;
    }
    return totalWorkTime + DateTime.now().difference(shiftStartTime!);
  }

  Duration get currentIdlePeriod {
    if (!isActive) return Duration.zero;
    if (isOnOrder) return Duration.zero;
    if (idleStartTime == null) return Duration.zero;
    return DateTime.now().difference(idleStartTime!);
  }

  Duration get totalIdleTimeDisplay => totalIdleTime + currentIdlePeriod;

  Duration get currentOrderTime {
    if (!isOnOrder || orderStartTime == null) return Duration.zero;
    return DateTime.now().difference(orderStartTime!);
  }

  Duration get totalOrderTimeDisplay => totalOrderTime + currentOrderTime;

  Duration get avgTimePerOrder {
    if (ordersCount == 0) return Duration.zero;
    return Duration(
      milliseconds: (totalOrderTimeDisplay.inMilliseconds / ordersCount).round()
    );
  }

  String get formattedAvgTimePerOrder {
    final d = avgTimePerOrder;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    if (minutes > 0 && seconds > 0) {
      return '$minutes мин $seconds сек';
    } else if (minutes > 0) {
      return '$minutes мин';
    } else {
      return '$seconds сек';
    }
  }

  double get totalDistance => totalPaidDistance + totalIdleDistance;
  double get avgDistancePerOrder => ordersCount > 0 ? totalPaidDistance / ordersCount : 0.0;
  double get avgCheck => ordersCount > 0 ? totalIncome / ordersCount : 0.0;

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedWorkTime => formatDuration(workTime);
  String get formattedIdleTime => formatDuration(totalIdleTimeDisplay);
}

class ShiftNotifier extends StateNotifier<ShiftState> {
  final Ref _ref;
  final ApiService _apiService = ApiService();
  GpsService? _gpsService;
  bool _isLoading = false;

  ShiftNotifier(this._ref) : super(const ShiftState()) {
    _initGpsService();
    _loadFromCache();
  }

  void _loadFromCache() {
    final cache = _apiService.cache;
    
    // ===== 1. СУММИРУЕМ ЗАКАЗЫ ИЗ КЭША =====
    int cachedOrdersCount = cache.todayOrders.length;
    double cachedTotalIncome = 0.0;
    double cachedTotalExpenses = 0.0;
    double cachedNetProfit = 0.0;
    double cachedTotalPaid = 0.0;
    Duration cachedTotalOrderTime = Duration.zero;

    for (final order in cache.todayOrders) {
      cachedTotalIncome += order.totalIncome;
      cachedTotalExpenses += order.totalExpenses;
      cachedNetProfit += order.netProfit;
      cachedTotalPaid += order.totalPaidDistance;
      cachedTotalOrderTime += order.totalTime;
    }

    // ===== 2. СУММИРУЕМ ВРЕМЯ РАБОТЫ И ПРОСТОЯ ИЗ ВСЕХ СМЕН =====
    Duration totalWorkTimeFromShifts = Duration.zero;
    Duration totalIdleTimeFromShifts = Duration.zero;
    double totalIdleDistanceFromShifts = 0.0;
    
    for (final shift in cache.todayShifts) {
      // Время работы
      if (shift.status == 'completed' && shift.duration != null) {
        totalWorkTimeFromShifts += shift.duration!;
      }
      // Холостой пробег
      totalIdleDistanceFromShifts += shift.totalIdleDistance;
      
      // ===== ВРЕМЯ ПРОСТОЯ =====
      // В модели Shift нет отдельного поля для времени простоя,
      // поэтому мы не можем восстановить его из кэша.
      // Оставляем как есть (будет накапливаться заново)
      // Но если смена активна, idleStartTime устанавливается сейчас
    }

    // ===== 3. ВОССТАНАВЛИВАЕМ АКТИВНУЮ СМЕНУ =====
    if (cache.activeShift != null) {
      final shift = cache.activeShift!;
      
      state = state.copyWith(
        isActive: true,
        shiftStartTime: shift.startTime,
        shiftId: shift.id,
        totalPaidDistance: shift.totalPaidDistance,
        totalIdleDistance: shift.totalIdleDistance,
        ordersCount: cachedOrdersCount > 0 ? cachedOrdersCount : state.ordersCount,
        totalIncome: cachedTotalIncome > 0 ? cachedTotalIncome : state.totalIncome,
        totalExpenses: cachedTotalExpenses > 0 ? cachedTotalExpenses : state.totalExpenses,
        netProfit: cachedNetProfit > 0 ? cachedNetProfit : state.netProfit,
        totalOrderTime: cachedTotalOrderTime > Duration.zero ? cachedTotalOrderTime : state.totalOrderTime,
        idleStartTime: DateTime.now(),
        // ===== ВОССТАНАВЛИВАЕМ ВРЕМЯ РАБОТЫ =====
        totalWorkTime: totalWorkTimeFromShifts,
        // ===== ВРЕМЯ ПРОСТОЯ: НЕ СБРАСЫВАЕМ, А ПРОДОЛЖАЕМ =====
        totalIdleTime: state.totalIdleTime, // сохраняем накопленное
        processedIdleDistance: state.processedIdleDistance,
      );
      
      logMessage('📁 Смена восстановлена из кэша: id=${shift.id}', category: 'SHIFT');
      logMessage('📁 Восстановлено время работы: ${totalWorkTimeFromShifts.inSeconds} сек', category: 'SHIFT');
      logMessage('📁 Восстановлено время простоя: ${state.totalIdleTime.inSeconds} сек', category: 'SHIFT');
      logMessage('📁 Заказов: ${state.ordersCount}, доход: ${state.totalIncome}', category: 'SHIFT');
      
      _startGpsTracking();
    } else {
      // ===== 4. НЕТ АКТИВНОЙ СМЕНЫ, НО ЕСТЬ ДАННЫЕ =====
      if (cachedOrdersCount > 0 || totalWorkTimeFromShifts > Duration.zero) {
        state = state.copyWith(
          isActive: false,
          ordersCount: cachedOrdersCount,
          totalIncome: cachedTotalIncome,
          totalExpenses: cachedTotalExpenses,
          netProfit: cachedNetProfit,
          totalPaidDistance: cachedTotalPaid,
          totalOrderTime: cachedTotalOrderTime,
          totalWorkTime: totalWorkTimeFromShifts,
          totalIdleDistance: totalIdleDistanceFromShifts,
          // totalIdleTime сохраняем
        );
        logMessage('📁 Восстановлена статистика из кэша: заказов=${state.ordersCount}, доход=${state.totalIncome}, время работы=${totalWorkTimeFromShifts.inSeconds} сек', category: 'SHIFT');
      }
    }
  }

  void _initGpsService() {
    try {
      _gpsService = _ref.read(gpsServiceProvider);
      if (state.isActive) {
        _gpsService!.startTracking();
      }
    } catch (e) {
      logMessage('⚠️ ShiftNotifier: GPS сервис ещё не готов: $e', category: 'SHIFT');
    }
  }

  void _startGpsTracking() {
    if (_gpsService == null) {
      try {
        _gpsService = _ref.read(gpsServiceProvider);
      } catch (e) {
        logMessage('⚠️ Не удалось получить GPS сервис: $e', category: 'SHIFT');
        return;
      }
    }
    if (_gpsService != null) {
      _gpsService!.startTracking();
    }
  }

  void _stopGpsTracking() {
    if (_gpsService != null) {
      _gpsService!.stopTracking();
    }
  }

  double _calculateIdleCost(double idleKm, SettingsState settings) {
    if (idleKm <= 0) return 0.0;
    final fuelCostPerKm = (settings.fuelConsumption / 100) * settings.fuelPrice;
    final costPerKm = fuelCostPerKm + settings.repairCost;
    return idleKm * costPerKm;
  }

  Future<void> startShift() async {
    if (_isLoading) return;
    if (state.isActive) {
      logMessage('⚠️ Смена уже активна', category: 'SHIFT');
      return;
    }

    _isLoading = true;

    if (_apiService.cache.activeShift != null) {
      _loadFromCache();
      _isLoading = false;
      return;
    }

    try {
      final shift = await _apiService.startShift();
      
      state = ShiftState(
        isActive: true,
        shiftStartTime: shift.startTime,
        shiftId: shift.id,
        idleStartTime: DateTime.now(),
        // Сохраняем накопления
        totalWorkTime: state.totalWorkTime,
        totalIdleTime: state.totalIdleTime,
        totalPaidDistance: state.totalPaidDistance,
        totalIdleDistance: state.totalIdleDistance,
        processedIdleDistance: state.processedIdleDistance,
        ordersCount: state.ordersCount,
        totalIncome: state.totalIncome,
        totalExpenses: state.totalExpenses,
        netProfit: state.netProfit,
        totalOrderTime: state.totalOrderTime,
        isOnOrder: false,
        orderStartTime: null,
      );
      
      _startGpsTracking();
      logMessage('✅ Смена начата на сервере (id=${shift.id})', category: 'SHIFT');
      logMessage('📊 Накопления: заказов=${state.ordersCount}, доход=${state.totalIncome}, время=${state.totalWorkTime.inSeconds} сек, простой=${state.totalIdleTime.inSeconds} сек', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ Ошибка начала смены: $e', category: 'SHIFT', level: LogLevel.error);
      if (e.toString().contains('Уже есть активная смена')) {
        logMessage('🔄 Активная смена уже есть на сервере, перезагружаем данные', category: 'SHIFT');
        await _apiService.loadAllData();
        _loadFromCache();
      }
    }
    _isLoading = false;
  }

  Future<void> stopShift() async {
    if (_isLoading) return;
    if (!state.isActive || state.shiftId == null) {
      logMessage('⚠️ Нет активной смены для остановки', category: 'SHIFT');
      return;
    }

    _isLoading = true;
    final now = DateTime.now();
    final addedWork = now.difference(state.shiftStartTime!);
    final idleDuration = state.currentIdlePeriod;
    
    Duration addedOrderTime = Duration.zero;
    if (state.isOnOrder && state.orderStartTime != null) {
      addedOrderTime = now.difference(state.orderStartTime!);
    }

    // ==== ПРИ ЗАВЕРШЕНИИ СМЕНЫ СПИСЫВАЕМ ВЕСЬ ОСТАВШИЙСЯ ХОЛОСТОЙ ПРОБЕГ ====
    final unprocessedIdle = state.unprocessedIdleDistance;
    final settings = _ref.read(settingsProvider);
    final idleCost = _calculateIdleCost(unprocessedIdle, settings);
    
    if (unprocessedIdle > 0) {
      logMessage('📊 [СМЕНА] Списание холостого пробега: ${unprocessedIdle.toStringAsFixed(2)} км на сумму ${idleCost.toStringAsFixed(2)} руб', category: 'SHIFT');
    }

    state = state.copyWith(
      isActive: false,
      shiftStartTime: null,
      shiftEndTime: now,
      totalWorkTime: state.totalWorkTime + addedWork,
      totalIdleTime: state.totalIdleTime + idleDuration,
      idleStartTime: null,
      isOnOrder: false,
      orderStartTime: null,
      totalOrderTime: state.totalOrderTime + addedOrderTime,
      processedIdleDistance: state.totalIdleDistance,
      totalExpenses: state.totalExpenses + idleCost,
      netProfit: state.totalIncome - (state.totalExpenses + idleCost),
    );
    
    _stopGpsTracking();

    try {
      await _apiService.completeShift(state.shiftId!);
      logMessage('✅ Смена завершена на сервере (id=${state.shiftId})', category: 'SHIFT');
      logMessage('📊 Итоговые накопления за день: заказов=${state.ordersCount}, доход=${state.totalIncome}, расходы=${state.totalExpenses}, прибыль=${state.netProfit}, время=${state.totalWorkTime.inSeconds} сек, простой=${state.totalIdleTime.inSeconds} сек', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ Ошибка завершения смены: $e', category: 'SHIFT', level: LogLevel.error);
    }
    _isLoading = false;
  }

  void startOrder() {
    if (!state.isActive || state.isOnOrder) return;
    final now = DateTime.now();
    final idleDuration = state.currentIdlePeriod;

    state = state.copyWith(
      isOnOrder: true,
      orderStartTime: now,
      totalIdleTime: state.totalIdleTime + idleDuration,
      idleStartTime: null,
    );
    logMessage('🟢 Заказ начат', category: 'SHIFT');
  }

  void cancelOrder() {
    if (!state.isOnOrder) return;
    final now = DateTime.now();
    state = state.copyWith(
      isOnOrder: false,
      orderStartTime: null,
      idleStartTime: now,
    );
    logMessage('❌ Заказ отменён', category: 'SHIFT');
  }

  void finishOrder({
    required double paidDistance,
    required double income,
    required double expenses,
    required Duration orderDuration,
  }) {
    if (!state.isOnOrder) {
      logMessage('⚠️ Нельзя завершить заказ: заказ не активен', category: 'SHIFT');
      return;
    }
    final now = DateTime.now();
    final orderTime = now.difference(state.orderStartTime!);

    // ==== ПРИ ЗАВЕРШЕНИИ ЗАКАЗА СПИСЫВАЕМ ХОЛОСТОЙ ПРОБЕГ ====
    final unprocessedIdle = state.unprocessedIdleDistance;
    final settings = _ref.read(settingsProvider);
    final idleCost = _calculateIdleCost(unprocessedIdle, settings);
    
    if (unprocessedIdle > 0) {
      logMessage('📊 [ЗАКАЗ] Списание холостого пробега: ${unprocessedIdle.toStringAsFixed(2)} км на сумму ${idleCost.toStringAsFixed(2)} руб', category: 'SHIFT');
    }

    state = state.copyWith(
      isOnOrder: false,
      orderStartTime: null,
      totalOrderTime: state.totalOrderTime + orderTime,
      totalPaidDistance: state.totalPaidDistance + paidDistance,
      ordersCount: state.ordersCount + 1,
      totalIncome: state.totalIncome + income,
      totalExpenses: state.totalExpenses + expenses + idleCost,
      netProfit: (state.totalIncome + income) - (state.totalExpenses + expenses + idleCost),
      idleStartTime: now,
      processedIdleDistance: state.totalIdleDistance,
    );
    logMessage('✅ Заказ завершён: пробег=$paidDistance, доход=$income, расходы=${expenses + idleCost}, холостой пробег списан=${unprocessedIdle.toStringAsFixed(2)} км', category: 'SHIFT');
  }

  void addIdleDistance(double distance) {
    if (!state.isActive || state.isOnOrder || distance <= 0) return;
    state = state.copyWith(
      totalIdleDistance: state.totalIdleDistance + distance,
    );
  }

  void loadFromCache() {
    _loadFromCache();
  }
  
  bool get isLoading => _isLoading;
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier(ref);
});