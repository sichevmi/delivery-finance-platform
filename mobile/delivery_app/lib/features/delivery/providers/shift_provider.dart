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
  
  static const String _keyIdleTime = 'shift_idle_time_seconds';
  static const String _keyIdleDistance = 'shift_idle_distance';
  static const String _keyProcessedIdleDistance = 'shift_processed_idle_distance';
  static const String _keyOrdersCount = 'shift_orders_count';
  static const String _keyTotalIncome = 'shift_total_income';
  static const String _keyTotalExpenses = 'shift_total_expenses';
  static const String _keyNetProfit = 'shift_net_profit';
  static const String _keyTotalPaidDistance = 'shift_total_paid_distance';
  static const String _keyTotalOrderTime = 'shift_total_order_time_seconds';
  static const String _keyTotalWorkTime = 'shift_total_work_time_seconds';

  ShiftNotifier(this._ref) : super(const ShiftState()) {
    logMessage('🔵 [SHIFT] ShiftNotifier конструктор', category: 'SHIFT');
    _initGpsService();
    _loadFromCache();
  }

  // ===== НОВЫЙ МЕТОД: ПРИНУДИТЕЛЬНОЕ ЗАВЕРШЕНИЕ ВСЕХ АКТИВНЫХ СМЕН =====
  Future<void> forceCompleteAllActiveShifts() async {
    logMessage('🔄 [SHIFT] forceCompleteAllActiveShifts() начат', category: 'SHIFT');
    
    try {
      // Загружаем свежие данные с сервера
      await _apiService.loadAllData();
      
      // Проверяем, есть ли активная смена
      final activeShift = _apiService.cache.activeShift;
      if (activeShift == null) {
        logMessage('✅ [SHIFT] Нет активных смен для завершения', category: 'SHIFT');
        return;
      }
      
      logMessage('🔄 [SHIFT] Найдена активная смена id=${activeShift.id}, завершаем...', category: 'SHIFT');
      
      // Завершаем смену с нулевыми данными
      await _apiService.completeShift(
        activeShift.id,
        totalPaidDistance: 0,
        totalIdleDistance: 0,
        totalOrderTimeSeconds: 0,
        ordersCount: 0,
        totalIncome: 0,
        totalExpenses: 0,
        netProfit: 0,
      );
      
      logMessage('✅ [SHIFT] Активная смена принудительно завершена', category: 'SHIFT');
      
      // Перезагружаем данные
      await _apiService.loadAllData();
      await _loadFromCache();
      
      logMessage('✅ [SHIFT] forceCompleteAllActiveShifts() завершён', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ [SHIFT] Ошибка принудительного завершения смены: $e', category: 'SHIFT', level: LogLevel.error);
      rethrow;
    }
  }

  Future<void> _saveShiftState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyIdleDistance, state.totalIdleDistance);
      await prefs.setDouble(_keyProcessedIdleDistance, state.processedIdleDistance);
      await prefs.setInt(_keyOrdersCount, state.ordersCount);
      await prefs.setDouble(_keyTotalIncome, state.totalIncome);
      await prefs.setDouble(_keyTotalExpenses, state.totalExpenses);
      await prefs.setDouble(_keyNetProfit, state.netProfit);
      await prefs.setDouble(_keyTotalPaidDistance, state.totalPaidDistance);
      await prefs.setInt(_keyTotalOrderTime, state.totalOrderTime.inSeconds);
      await prefs.setInt(_keyTotalWorkTime, state.totalWorkTime.inSeconds);
      logMessage('🔵 [SHIFT] Состояние смены сохранено: totalIdleDistance=${state.totalIdleDistance}, processedIdleDistance=${state.processedIdleDistance}, totalExpenses=${state.totalExpenses}', category: 'SHIFT');
    } catch (e) {
      logMessage('⚠️ [SHIFT] Ошибка сохранения состояния: $e', category: 'SHIFT');
    }
  }

  Future<Map<String, dynamic>> _loadSavedShiftState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'totalIdleDistance': prefs.getDouble(_keyIdleDistance) ?? 0.0,
        'processedIdleDistance': prefs.getDouble(_keyProcessedIdleDistance) ?? 0.0,
        'ordersCount': prefs.getInt(_keyOrdersCount) ?? 0,
        'totalIncome': prefs.getDouble(_keyTotalIncome) ?? 0.0,
        'totalExpenses': prefs.getDouble(_keyTotalExpenses) ?? 0.0,
        'netProfit': prefs.getDouble(_keyNetProfit) ?? 0.0,
        'totalPaidDistance': prefs.getDouble(_keyTotalPaidDistance) ?? 0.0,
        'totalOrderTime': Duration(seconds: prefs.getInt(_keyTotalOrderTime) ?? 0),
        'totalWorkTime': Duration(seconds: prefs.getInt(_keyTotalWorkTime) ?? 0),
      };
    } catch (e) {
      logMessage('⚠️ [SHIFT] Ошибка загрузки состояния: $e', category: 'SHIFT');
      return {};
    }
  }

  Future<void> _clearSavedShiftState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIdleDistance);
      await prefs.remove(_keyProcessedIdleDistance);
      await prefs.remove(_keyOrdersCount);
      await prefs.remove(_keyTotalIncome);
      await prefs.remove(_keyTotalExpenses);
      await prefs.remove(_keyNetProfit);
      await prefs.remove(_keyTotalPaidDistance);
      await prefs.remove(_keyTotalOrderTime);
      await prefs.remove(_keyTotalWorkTime);
      logMessage('🔵 [SHIFT] Состояние смены очищено', category: 'SHIFT');
    } catch (e) {
      logMessage('⚠️ [SHIFT] Ошибка очистки состояния: $e', category: 'SHIFT');
    }
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
    
    final savedState = await _loadSavedShiftState();
    final savedIdleSeconds = await _loadSavedIdleTime();
    final restoredIdleTime = Duration(seconds: savedIdleSeconds);
    
    logMessage('🔵 [SHIFT] restoredIdleTime=${restoredIdleTime.inSeconds} сек', category: 'SHIFT');
    logMessage('🔵 [SHIFT] savedState.totalIdleDistance=${savedState['totalIdleDistance']}', category: 'SHIFT');
    logMessage('🔵 [SHIFT] savedState.processedIdleDistance=${savedState['processedIdleDistance']}', category: 'SHIFT');
    logMessage('🔵 [SHIFT] savedState.totalExpenses=${savedState['totalExpenses']}', category: 'SHIFT');
    logMessage('🔵 [SHIFT] savedState.netProfit=${savedState['netProfit']}', category: 'SHIFT');
    
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

    Duration totalWorkTimeFromShifts = Duration.zero;
    Duration totalIdleTimeFromShifts = Duration.zero;
    
    logMessage('🔵 [SHIFT] cache.todayShifts.length=${cache.todayShifts.length}', category: 'SHIFT');
    
    for (final shift in cache.todayShifts) {
      if (shift.status == 'completed' && shift.duration != null) {
        totalWorkTimeFromShifts += shift.duration!;
        logMessage('🔵 [SHIFT]   смена id=${shift.id}, duration=${shift.duration!.inSeconds} сек', category: 'SHIFT');
      }
      if (shift.status == 'completed' && shift.totalIdleTime != null) {
        totalIdleTimeFromShifts += shift.totalIdleTime!;
        logMessage('🔵 [SHIFT]   смена id=${shift.id}, idleTime=${shift.totalIdleTime!.inSeconds} сек', category: 'SHIFT');
      }
    }
    
    logMessage('🔵 [SHIFT] totalWorkTimeFromShifts=${totalWorkTimeFromShifts.inSeconds} сек', category: 'SHIFT');
    logMessage('🔵 [SHIFT] totalIdleTimeFromShifts=${totalIdleTimeFromShifts.inSeconds} сек', category: 'SHIFT');

    Duration finalIdleTime = restoredIdleTime;
    if (totalIdleTimeFromShifts > finalIdleTime) {
      finalIdleTime = totalIdleTimeFromShifts;
    }
    logMessage('🔵 [SHIFT] finalIdleTime=${finalIdleTime.inSeconds} сек', category: 'SHIFT');

    double restoredIdleDistance = savedState['totalIdleDistance'] ?? 0.0;
    double restoredProcessedIdleDistance = savedState['processedIdleDistance'] ?? 0.0;
    int restoredOrdersCount = savedState['ordersCount'] ?? 0;
    double restoredTotalIncome = savedState['totalIncome'] ?? 0.0;
    double restoredTotalExpenses = savedState['totalExpenses'] ?? 0.0;
    double restoredNetProfit = savedState['netProfit'] ?? 0.0;
    double restoredTotalPaidDistance = savedState['totalPaidDistance'] ?? 0.0;
    Duration restoredTotalOrderTime = savedState['totalOrderTime'] ?? Duration.zero;
    Duration restoredTotalWorkTime = savedState['totalWorkTime'] ?? Duration.zero;

    logMessage('🔵 [SHIFT] restoredIdleDistance=$restoredIdleDistance км', category: 'SHIFT');
    logMessage('🔵 [SHIFT] restoredProcessedIdleDistance=$restoredProcessedIdleDistance км', category: 'SHIFT');
    logMessage('🔵 [SHIFT] restoredTotalExpenses=$restoredTotalExpenses руб', category: 'SHIFT');

    if (cache.activeShift != null) {
      final shift = cache.activeShift!;
      logMessage('🔵 [SHIFT] cache.activeShift найден: id=${shift.id}', category: 'SHIFT');
      
      state = state.copyWith(
        isActive: true,
        shiftStartTime: shift.startTime,
        shiftId: shift.id,
        totalPaidDistance: shift.totalPaidDistance > 0 ? shift.totalPaidDistance : restoredTotalPaidDistance,
        totalIdleDistance: restoredIdleDistance,
        processedIdleDistance: restoredProcessedIdleDistance,
        ordersCount: restoredOrdersCount > 0 ? restoredOrdersCount : cachedOrdersCount,
        totalIncome: restoredTotalIncome > 0 ? restoredTotalIncome : cachedTotalIncome,
        totalExpenses: restoredTotalExpenses > 0 ? restoredTotalExpenses : cachedTotalExpenses,
        netProfit: restoredNetProfit > 0 ? restoredNetProfit : cachedNetProfit,
        totalOrderTime: restoredTotalOrderTime > Duration.zero ? restoredTotalOrderTime : cachedTotalOrderTime,
        idleStartTime: DateTime.now(),
        totalWorkTime: restoredTotalWorkTime > Duration.zero ? restoredTotalWorkTime : totalWorkTimeFromShifts,
        totalIdleTime: finalIdleTime,
      );
      
      logMessage('📁 [SHIFT] Смена восстановлена из кэша: id=${shift.id}', category: 'SHIFT');
      logMessage('📁 [SHIFT] Восстановлен холостой пробег: ${state.totalIdleDistance} км', category: 'SHIFT');
      logMessage('📁 [SHIFT] Восстановлен списанный пробег: ${state.processedIdleDistance} км', category: 'SHIFT');
      logMessage('📁 [SHIFT] Восстановлены расходы: ${state.totalExpenses} руб', category: 'SHIFT');
      
      _startGpsTracking();
    } else {
      logMessage('🔵 [SHIFT] cache.activeShift == null', category: 'SHIFT');
      
      state = state.copyWith(
        isActive: false,
        ordersCount: restoredOrdersCount,
        totalIncome: restoredTotalIncome,
        totalExpenses: restoredTotalExpenses,
        netProfit: restoredNetProfit,
        totalPaidDistance: restoredTotalPaidDistance,
        totalOrderTime: restoredTotalOrderTime,
        totalWorkTime: restoredTotalWorkTime > Duration.zero ? restoredTotalWorkTime : totalWorkTimeFromShifts,
        totalIdleDistance: restoredIdleDistance,
        processedIdleDistance: restoredProcessedIdleDistance,
        totalIdleTime: finalIdleTime,
      );
      logMessage('📁 [SHIFT] Восстановлена статистика: заказов=${state.ordersCount}, холостой пробег=${state.totalIdleDistance} км, списано=${state.processedIdleDistance} км, расходы=${state.totalExpenses} руб', category: 'SHIFT');
    }
    logMessage('🔵 [SHIFT] _loadFromCache() завершён', category: 'SHIFT');
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
      try {
        _gpsService = _ref.read(gpsServiceProvider);
      } catch (e) {
        logMessage('❌ [SHIFT] Не удалось получить GPS сервис: $e', category: 'SHIFT', level: LogLevel.error);
        return;
      }
    }
    
    if (_gpsService != null) {
      _gpsService!.startTracking();
      logMessage('✅ [SHIFT] GPS трекинг запущен', category: 'SHIFT');
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

    try {
      logMessage('🔄 [SHIFT] Проверка активной смены на сервере...', category: 'SHIFT');
      await _apiService.loadAllData();
      logMessage('🔄 [SHIFT] Данные с сервера загружены, activeShift=${_apiService.cache.activeShift?.id}', category: 'SHIFT');
      
      if (_apiService.cache.activeShift != null) {
        logMessage('🔄 На сервере есть активная смена ${_apiService.cache.activeShift!.id}, восстанавливаем...', category: 'SHIFT');
        await _loadFromCache();
        _isLoading = false;
        return;
      }
    } catch (e) {
      logMessage('⚠️ Ошибка проверки активной смены: $e', category: 'SHIFT', level: LogLevel.error);
    }

    try {
      logMessage('🔄 [SHIFT] Отправка запроса на создание смены...', category: 'SHIFT');
      final shift = await _apiService.startShift();
      logMessage('✅ [SHIFT] Смена создана на сервере id=${shift.id}', category: 'SHIFT');
      
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
      
      await _saveShiftState();
      _startGpsTracking();
      logMessage('✅ [SHIFT] Смена начата на сервере (id=${shift.id})', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ Ошибка начала смены: $e', category: 'SHIFT', level: LogLevel.error);
      
      final errorMessage = e.toString();
      if (errorMessage.contains('Уже есть активная смена') || 
          errorMessage.contains('400') ||
          errorMessage.contains('active shift')) {
        logMessage('🔄 Активная смена уже есть на сервере, перезагружаем данные', category: 'SHIFT');
        try {
          await _apiService.loadAllData();
          logMessage('🔄 [SHIFT] Данные загружены, activeShift=${_apiService.cache.activeShift?.id}', category: 'SHIFT');
          
          if (_apiService.cache.activeShift != null) {
            logMessage('🔄 Восстанавливаем активную смену ${_apiService.cache.activeShift!.id}', category: 'SHIFT');
            await _loadFromCache();
          } else {
            logMessage('⚠️ Сервер говорит что есть активная смена, но в кеше её нет. Принудительно завершаем.', category: 'SHIFT');
            // Принудительно завершаем активную смену на сервере
            await forceCompleteAllActiveShifts();
            // Теперь можно создавать новую смену
            _isLoading = false;
            return startShift();
          }
        } catch (loadError) {
          logMessage('❌ Ошибка загрузки данных после ошибки: $loadError', category: 'SHIFT', level: LogLevel.error);
        }
      }
      _isLoading = false;
      return;
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

    final unprocessedIdle = state.unprocessedIdleDistance;
    final settings = _ref.read(settingsProvider);
    final idleCost = _calculateIdleCost(unprocessedIdle, settings);
    
    logMessage('📊 [СМЕНА] Данные перед завершением:', category: 'SHIFT');
    logMessage('   totalPaidDistance: ${state.totalPaidDistance}', category: 'SHIFT');
    logMessage('   totalIdleDistance: ${state.totalIdleDistance}', category: 'SHIFT');
    logMessage('   processedIdleDistance: ${state.processedIdleDistance}', category: 'SHIFT');
    logMessage('   ordersCount: ${state.ordersCount}', category: 'SHIFT');
    logMessage('   totalIncome: ${state.totalIncome}', category: 'SHIFT');
    logMessage('   totalExpenses: ${state.totalExpenses}', category: 'SHIFT');
    logMessage('   netProfit: ${state.netProfit}', category: 'SHIFT');

    final newTotalIdleTime = state.totalIdleTime + idleDuration;
    final newTotalWorkTime = state.totalWorkTime + addedWork;
    final newTotalOrderTime = state.totalOrderTime + addedOrderTime;
    final newTotalExpenses = state.totalExpenses + idleCost;
    final newNetProfit = state.totalIncome - newTotalExpenses;

    final savedShiftData = {
      'totalPaidDistance': state.totalPaidDistance,
      'totalIdleDistance': state.totalIdleDistance,
      'processedIdleDistance': state.processedIdleDistance,
      'ordersCount': state.ordersCount,
      'totalIncome': state.totalIncome,
      'totalExpenses': newTotalExpenses,
      'netProfit': newNetProfit,
      'totalWorkTime': newTotalWorkTime,
      'totalIdleTime': newTotalIdleTime,
      'totalOrderTime': newTotalOrderTime,
    };

    await _saveIdleTime(newTotalIdleTime);

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
    
    await _saveShiftState();
    _stopGpsTracking();

    try {
      final shiftId = state.shiftId!;
      
      logMessage('📤 [СМЕНА] Отправка данных на сервер:', category: 'SHIFT');
      logMessage('   totalPaidDistance: ${state.totalPaidDistance}', category: 'SHIFT');
      logMessage('   totalIdleDistance: ${state.totalIdleDistance}', category: 'SHIFT');
      logMessage('   ordersCount: ${state.ordersCount}', category: 'SHIFT');
      logMessage('   totalIncome: ${state.totalIncome}', category: 'SHIFT');
      logMessage('   totalExpenses: ${state.totalExpenses}', category: 'SHIFT');
      logMessage('   netProfit: ${state.netProfit}', category: 'SHIFT');
      
      await _apiService.completeShift(
        shiftId,
        totalPaidDistance: state.totalPaidDistance,
        totalIdleDistance: state.totalIdleDistance,
        totalOrderTimeSeconds: state.totalOrderTime.inSeconds,
        ordersCount: state.ordersCount,
        totalIncome: state.totalIncome,
        totalExpenses: state.totalExpenses,
        netProfit: state.netProfit,
      );
      
      await _apiService.loadAllData();
      
      state = state.copyWith(
        totalPaidDistance: savedShiftData['totalPaidDistance'] as double,
        totalIdleDistance: savedShiftData['totalIdleDistance'] as double,
        processedIdleDistance: savedShiftData['processedIdleDistance'] as double,
        ordersCount: savedShiftData['ordersCount'] as int,
        totalIncome: savedShiftData['totalIncome'] as double,
        totalExpenses: savedShiftData['totalExpenses'] as double,
        netProfit: savedShiftData['netProfit'] as double,
        totalWorkTime: savedShiftData['totalWorkTime'] as Duration,
        totalIdleTime: savedShiftData['totalIdleTime'] as Duration,
        totalOrderTime: savedShiftData['totalOrderTime'] as Duration,
      );
      
      await _saveShiftState();
      logMessage('✅ [SHIFT] Смена завершена на сервере (id=$shiftId)', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ [SHIFT] Ошибка завершения смены: $e', category: 'SHIFT', level: LogLevel.error);
      
      if (e.toString().contains('уже завершена') || e.toString().contains('not found')) {
        logMessage('🔄 Смена уже завершена на сервере, обновляем состояние', category: 'SHIFT');
        await _apiService.loadAllData();
        await _loadFromCache();
      }
    }
    _isLoading = false;
  }

  void startOrder() {
    if (!state.isActive) {
      logMessage('⚠️ Нельзя начать заказ: смена не активна', category: 'SHIFT');
      return;
    }
    if (state.isOnOrder) {
      logMessage('⚠️ Заказ уже активен', category: 'SHIFT');
      return;
    }
    
    final now = DateTime.now();
    final idleDuration = state.currentIdlePeriod;

    state = state.copyWith(
      isOnOrder: true,
      orderStartTime: now,
      totalIdleTime: state.totalIdleTime + idleDuration,
      idleStartTime: null,
    );
    _saveShiftState();
    logMessage('🟢 Заказ начат, isOnOrder=${state.isOnOrder}', category: 'SHIFT');
  }

  void cancelOrder() {
    if (!state.isOnOrder) return;
    final now = DateTime.now();
    state = state.copyWith(
      isOnOrder: false,
      orderStartTime: null,
      idleStartTime: now,
    );
    _saveShiftState();
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
    
    logMessage('📊 [ЗАКАЗ] Данные перед завершением:', category: 'SHIFT');
    logMessage('   totalIdleDistance: ${state.totalIdleDistance}', category: 'SHIFT');
    logMessage('   processedIdleDistance: ${state.processedIdleDistance}', category: 'SHIFT');
    logMessage('   unprocessedIdle: $unprocessedIdle', category: 'SHIFT');
    
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
    
    logMessage('📊 [ЗАКАЗ] После завершения:', category: 'SHIFT');
    logMessage('   totalIdleDistance: ${state.totalIdleDistance}', category: 'SHIFT');
    logMessage('   processedIdleDistance: ${state.processedIdleDistance}', category: 'SHIFT');
    logMessage('   unprocessedIdle: ${state.unprocessedIdleDistance}', category: 'SHIFT');
    logMessage('   totalExpenses: ${state.totalExpenses}', category: 'SHIFT');
    
    _saveShiftState();
    logMessage('✅ Заказ завершён: пробег=$paidDistance, доход=$income, расходы=${expenses + idleCost}, холостой пробег списан=${unprocessedIdle.toStringAsFixed(2)} км', category: 'SHIFT');
  }

  void addIdleDistance(double distance) {
    if (!state.isActive || state.isOnOrder || distance <= 0) return;
    state = state.copyWith(
      totalIdleDistance: state.totalIdleDistance + distance,
    );
    _saveShiftState();
    logMessage('🔄 Холостой пробег: +$distance км (всего: ${state.totalIdleDistance})', category: 'SHIFT');
  }

  Future<void> loadFromCache() async {
    await _loadFromCache();
  }
  
  bool get isLoading => _isLoading;
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier(ref);
});