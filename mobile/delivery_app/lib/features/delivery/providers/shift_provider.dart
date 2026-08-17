import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // Ключи для SharedPreferences
  static const String _keyIdleTime = 'shift_idle_time_seconds';
  static const String _keyWorkTime = 'shift_work_time_seconds';

  ShiftNotifier(this._ref) : super(const ShiftState()) {
    logMessage('🔵 [SHIFT] ShiftNotifier конструктор', category: 'SHIFT');
    _initGpsService();
    _loadFromCache();
  }

  Future<int> _loadSavedIdleTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seconds = prefs.getInt(_keyIdleTime) ?? 0;
      logMessage('🔵 [SHIFT] Загружено сохранённое время простоя: $seconds сек', category: 'SHIFT');
      return seconds;
    } catch (e) {
      logMessage('⚠️ [SHIFT] Ошибка загрузки времени простоя: $e', category: 'SHIFT');
      return 0;
    }
  }

  Future<void> _saveIdleTime(Duration duration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyIdleTime, duration.inSeconds);
      logMessage('🔵 [SHIFT] Сохранено время простоя: ${duration.inSeconds} сек', category: 'SHIFT');
    } catch (e) {
      logMessage('⚠️ [SHIFT] Ошибка сохранения времени простоя: $e', category: 'SHIFT');
    }
  }

  Future<void> _loadFromCache() async {
    logMessage('🔵 [SHIFT] _loadFromCache() начат', category: 'SHIFT');
    
    final cache = _apiService.cache;
    
    // ===== 1. ЗАГРУЖАЕМ СОХРАНЁННОЕ ВРЕМЯ ПРОСТОЯ =====
    final savedIdleSeconds = await _loadSavedIdleTime();
    final restoredIdleTime = Duration(seconds: savedIdleSeconds);
    logMessage('🔵 [SHIFT] restoredIdleTime=$restoredIdleTime.inSeconds сек', category: 'SHIFT');
    
    // ===== 2. СУММИРУЕМ ЗАКАЗЫ ИЗ КЭША =====
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

    // ===== 3. СУММИРУЕМ ВРЕМЯ РАБОТЫ ИЗ ВСЕХ СМЕН =====
    Duration totalWorkTimeFromShifts = Duration.zero;
    double totalIdleDistanceFromShifts = 0.0;
    
    logMessage('🔵 [SHIFT] cache.todayShifts.length=${cache.todayShifts.length}', category: 'SHIFT');
    
    for (final shift in cache.todayShifts) {
      if (shift.status == 'completed' && shift.duration != null) {
        totalWorkTimeFromShifts += shift.duration!;
        logMessage('🔵 [SHIFT]   смена id=${shift.id}, duration=${shift.duration!.inSeconds} сек', category: 'SHIFT');
      }
      totalIdleDistanceFromShifts += shift.totalIdleDistance;
    }
    logMessage('🔵 [SHIFT] totalWorkTimeFromShifts=${totalWorkTimeFromShifts.inSeconds} сек', category: 'SHIFT');

    // ===== 4. ВОССТАНАВЛИВАЕМ АКТИВНУЮ СМЕНУ =====
    if (cache.activeShift != null) {
      final shift = cache.activeShift!;
      logMessage('🔵 [SHIFT] cache.activeShift найден: id=${shift.id}', category: 'SHIFT');
      
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
        totalWorkTime: totalWorkTimeFromShifts,
        totalIdleTime: restoredIdleTime,
        processedIdleDistance: state.processedIdleDistance,
      );
      
      logMessage('📁 [SHIFT] Смена восстановлена из кэша: id=${shift.id}', category: 'SHIFT');
      logMessage('📁 [SHIFT] Восстановлено время работы: ${state.totalWorkTime.inSeconds} сек', category: 'SHIFT');
      logMessage('📁 [SHIFT] Восстановлено время простоя: ${state.totalIdleTime.inSeconds} сек', category: 'SHIFT');
      
      _startGpsTracking();
    } else {
      logMessage('🔵 [SHIFT] cache.activeShift == null', category: 'SHIFT');
      
      // ===== 5. НЕТ АКТИВНОЙ СМЕНЫ =====
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
          totalIdleTime: restoredIdleTime,
        );
        logMessage('📁 [SHIFT] Восстановлена статистика из кэша: заказов=${state.ordersCount}, время работы=${totalWorkTimeFromShifts.inSeconds} сек, время простоя=${state.totalIdleTime.inSeconds} сек', category: 'SHIFT');
      } else {
        // Если нет данных, но есть сохранённое время простоя
        if (restoredIdleTime > Duration.zero) {
          state = state.copyWith(
            totalIdleTime: restoredIdleTime,
          );
          logMessage('📁 [SHIFT] Восстановлено время простоя из SharedPreferences: ${state.totalIdleTime.inSeconds} сек', category: 'SHIFT');
        }
      }
    }
    logMessage('🔵 [SHIFT] _loadFromCache() завершён, state.totalIdleTime=${state.totalIdleTime.inSeconds} сек', category: 'SHIFT');
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
  logMessage('🟢 [SHIFT] _startGpsTracking() вызван', category: 'SHIFT');
  
  if (_gpsService == null) {
    logMessage('🟢 [SHIFT] _gpsService == null, пытаемся получить из провайдера', category: 'SHIFT');
    try {
      _gpsService = _ref.read(gpsServiceProvider);
      logMessage('✅ [SHIFT] _gpsService получен: ${_gpsService.hashCode}', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ [SHIFT] Не удалось получить GPS сервис: $e', category: 'SHIFT', level: LogLevel.error);
      return;
    }
  }
  
  if (_gpsService != null) {
    logMessage('🟢 [SHIFT] Запускаем GPS трекинг', category: 'SHIFT');
    _gpsService!.startTracking();
    logMessage('✅ [SHIFT] GPS трекинг запущен', category: 'SHIFT');
  } else {
    logMessage('⚠️ [SHIFT] _gpsService == null, GPS НЕ запущен', category: 'SHIFT');
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
      await _loadFromCache();
      _isLoading = false;
      return;
    }

    try {
      final shift = await _apiService.startShift();
      
      final idleTimeToPreserve = state.totalIdleTime;
      logMessage('🔵 [SHIFT] startShift: idleTimeToPreserve=${idleTimeToPreserve.inSeconds} сек', category: 'SHIFT');
      
      state = ShiftState(
        isActive: true,
        shiftStartTime: shift.startTime,
        shiftId: shift.id,
        idleStartTime: DateTime.now(),
        totalWorkTime: state.totalWorkTime,
        totalIdleTime: idleTimeToPreserve,
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
      logMessage('✅ [SHIFT] Смена начата на сервере (id=${shift.id})', category: 'SHIFT');
      logMessage('📊 [SHIFT] Накопления: заказов=${state.ordersCount}, доход=${state.totalIncome}, время=${state.totalWorkTime.inSeconds} сек, простой=${state.totalIdleTime.inSeconds} сек', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ Ошибка начала смены: $e', category: 'SHIFT', level: LogLevel.error);
      if (e.toString().contains('Уже есть активная смена')) {
        logMessage('🔄 Активная смена уже есть на сервере, перезагружаем данные', category: 'SHIFT');
        await _apiService.loadAllData();
        await _loadFromCache();
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

  // ===== РАСЧЁТ ХОЛОСТОГО ПРОБЕГА =====
  final unprocessedIdle = state.unprocessedIdleDistance;
  final settings = _ref.read(settingsProvider);
  final idleCost = _calculateIdleCost(unprocessedIdle, settings);
  
  if (unprocessedIdle > 0) {
    logMessage('📊 [СМЕНА] Списание холостого пробега: ${unprocessedIdle.toStringAsFixed(2)} км на сумму ${idleCost.toStringAsFixed(2)} руб', category: 'SHIFT');
  }

  // ===== СОХРАНЯЕМ ВСЕ ДАННЫЕ =====
  final newTotalIdleTime = state.totalIdleTime + idleDuration;
  final newTotalWorkTime = state.totalWorkTime + addedWork;
  final newTotalOrderTime = state.totalOrderTime + addedOrderTime;
  final newTotalExpenses = state.totalExpenses + idleCost;
  final newNetProfit = state.totalIncome - newTotalExpenses;

  // ===== ОБНОВЛЯЕМ ЛОКАЛЬНОЕ СОСТОЯНИЕ =====
  state = state.copyWith(
    isActive: false,
    shiftStartTime: null,
    shiftEndTime: now,
    totalWorkTime: newTotalWorkTime,
    totalIdleTime: newTotalIdleTime,
    idleStartTime: null,
    isOnOrder: false,
    orderStartTime: null,
    totalOrderTime: newTotalOrderTime,
    processedIdleDistance: state.totalIdleDistance,
    totalExpenses: newTotalExpenses,
    netProfit: newNetProfit,
  );
  
  _stopGpsTracking();

  try {
    // ===== ОТПРАВЛЯЕМ ВСЕ ДАННЫЕ НА СЕРВЕР =====
    // Используем существующий метод completeShift с передачей данных
    await _apiService.completeShift(
      state.shiftId!,
      totalPaidDistance: state.totalPaidDistance,
      totalIdleDistance: state.totalIdleDistance,
      totalOrderTimeSeconds: state.totalOrderTimeDisplay.inSeconds,
      ordersCount: state.ordersCount,
      totalIncome: state.totalIncome,
      totalExpenses: state.totalExpenses,
      netProfit: state.netProfit,
    );
    
    // ===== ПЕРЕЗАГРУЖАЕМ ДАННЫЕ С СЕРВЕРА =====
    await _apiService.loadAllData();
    
    logMessage('✅ Смена завершена на сервере (id=${state.shiftId})', category: 'SHIFT');
    logMessage('📊 Итоговые накопления за день: заказов=${state.ordersCount}, доход=${state.totalIncome}, расходы=${state.totalExpenses}, прибыль=${state.netProfit}, холостой пробег=${state.totalIdleDistance} км', category: 'SHIFT');
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

  Future<void> loadFromCache() async {
    await _loadFromCache();
  }
  
  bool get isLoading => _isLoading;
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier(ref);
});