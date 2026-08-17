import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';

class ShiftState {
  final bool isActive;
  final DateTime? shiftStartTime;
  final DateTime? shiftEndTime;
  final Duration totalWorkTime;      // НАКАПЛИВАЕТСЯ ЗА ДЕНЬ
  final Duration totalIdleTime;       // НАКАПЛИВАЕТСЯ ЗА ДЕНЬ
  final DateTime? idleStartTime;
  final bool isOnOrder;
  final DateTime? orderStartTime;
  final Duration totalOrderTime;      // НАКАПЛИВАЕТСЯ ЗА ДЕНЬ
  final double totalPaidDistance;     // НАКАПЛИВАЕТСЯ ЗА ДЕНЬ
  final double totalIdleDistance;     // НАКАПЛИВАЕТСЯ ЗА ДЕНЬ
  final int ordersCount;              // НАКАПЛИВАЕТСЯ ЗА ДЕНЬ
  final double totalIncome;           // НАКАПЛИВАЕТСЯ ЗА ДЕНЬ
  final double totalExpenses;         // НАКАПЛИВАЕТСЯ ЗА ДЕНЬ
  final double netProfit;             // НАКАПЛИВАЕТСЯ ЗА ДЕНЬ
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
      ordersCount: ordersCount ?? this.ordersCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      shiftId: shiftId ?? this.shiftId,
    );
  }

  Duration get workTime {
    if (!isActive || shiftStartTime == null) {
      return totalWorkTime;
    }
    // Используем локальное время (сервер теперь возвращает правильное)
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
    if (cache.activeShift != null) {
      final shift = cache.activeShift!;
      state = state.copyWith(
        isActive: true,
        shiftStartTime: shift.startTime,
        shiftId: shift.id,
        totalPaidDistance: shift.totalPaidDistance,
        totalIdleDistance: shift.totalIdleDistance,
        ordersCount: shift.ordersCount,
        totalIncome: shift.totalIncome,
        totalExpenses: shift.totalExpenses,
        netProfit: shift.netProfit,
        idleStartTime: DateTime.now(),
        // НЕ СБРАСЫВАЕМ — сохраняем накопления за день
        totalWorkTime: state.totalWorkTime,
        totalIdleTime: state.totalIdleTime,
      );
      _startGpsTracking();
      logMessage('📁 Смена восстановлена из кэша: id=${shift.id}', category: 'SHIFT');
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
      logMessage('🕐 [КЛИЕНТ] Время от сервера (raw): ${shift.startTime}', category: 'SHIFT');
logMessage('🕐 [КЛИЕНТ] Тип времени: ${shift.startTime.runtimeType}', category: 'SHIFT');
logMessage('🕐 [КЛИЕНТ] Текущее время клиента: ${DateTime.now()}', category: 'SHIFT');
final diff = DateTime.now().difference(shift.startTime);
logMessage('🕐 [КЛИЕНТ] Разница: ${diff.inSeconds} сек (${diff.inHours} ч)', category: 'SHIFT');
      
      // ===== СТАРТ НОВОЙ СМЕНЫ — НИЧЕГО НЕ СБРАСЫВАЕМ =====
      // Все накопления за день сохраняются
      state = ShiftState(
        isActive: true,
        shiftStartTime: shift.startTime,  // сервер возвращает правильное время
        shiftId: shift.id,
        idleStartTime: DateTime.now(),
        // СОХРАНЯЕМ все накопленные за день данные
        totalWorkTime: state.totalWorkTime,
        totalIdleTime: state.totalIdleTime,
        totalPaidDistance: state.totalPaidDistance,
        totalIdleDistance: state.totalIdleDistance,
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
      logMessage('📊 Накопления за день: заказов=${state.ordersCount}, время=${state.totalWorkTime.inSeconds} сек', category: 'SHIFT');
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

    // ===== ОСТАНАВЛИВАЕМ СМЕНУ, НО СОХРАНЯЕМ НАКОПЛЕНИЯ =====
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
    );
    
    _stopGpsTracking();

    try {
      await _apiService.completeShift(state.shiftId!);
      logMessage('✅ Смена завершена на сервере (id=${state.shiftId})', category: 'SHIFT');
      logMessage('📊 Итоговые накопления за день: заказов=${state.ordersCount}, время=${state.totalWorkTime.inSeconds} сек', category: 'SHIFT');
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

    state = state.copyWith(
      isOnOrder: false,
      orderStartTime: null,
      totalOrderTime: state.totalOrderTime + orderTime,
      totalPaidDistance: state.totalPaidDistance + paidDistance,
      ordersCount: state.ordersCount + 1,
      totalIncome: state.totalIncome + income,
      totalExpenses: state.totalExpenses + expenses,
      netProfit: state.totalIncome + income - (state.totalExpenses + expenses),
      idleStartTime: now,
    );
    logMessage('✅ Заказ завершён: пробег=$paidDistance, доход=$income', category: 'SHIFT');
  }

  void addIdleDistance(double distance) {
    if (!state.isActive || state.isOnOrder || distance <= 0) return;
    state = state.copyWith(
      totalIdleDistance: state.totalIdleDistance + distance,
    );
    logMessage('🔄 Холостой пробег: +$distance км (всего: ${state.totalIdleDistance})', category: 'SHIFT');
  }

  void loadFromCache() {
    _loadFromCache();
  }
  
  bool get isLoading => _isLoading;
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier(ref);
});