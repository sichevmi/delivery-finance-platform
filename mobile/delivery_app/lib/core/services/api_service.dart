import 'package:delivery_app/core/services/api_client.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/models/shift.dart';
import 'package:delivery_app/features/delivery/models/order.dart';
import 'package:delivery_app/features/delivery/models/settings.dart';
import 'package:delivery_app/features/delivery/models/pricing.dart';
import 'package:delivery_app/features/delivery/models/x5_settings.dart';

// ===== КЭШ В ПАМЯТИ =====
class AppCache {
  static final AppCache _instance = AppCache._();
  factory AppCache() => _instance;
  AppCache._();

  Shift? activeShift;
  List<Order> todayOrders = [];
  List<Shift> todayShifts = [];
  Settings settings = Settings.defaults();
  PricingConfig pricing = PricingConfig.defaults();
  X5Settings x5Settings = X5Settings.defaults();

  void clear() {
    activeShift = null;
    todayOrders.clear();
    todayShifts.clear();
  }

  void updateTodayData(Map<String, dynamic> data) {
    final shiftsList = data['shifts'] as List? ?? [];
    todayShifts = shiftsList.map((s) => Shift.fromJson(s)).toList();
    // Ищем смену со статусом active или paused
    activeShift = todayShifts.cast<Shift?>().firstWhere(
      (s) => s?.status == 'active' || s?.status == 'paused',
      orElse: () => null,
    );
    
    // Если есть активная смена — обновляем её данные
    if (activeShift != null) {
      logMessage('🔄 [API] Активная смена: id=${activeShift!.id}, durationSeconds=${activeShift!.durationSeconds}', category: 'API');
    }
    
    final ordersList = data['orders'] as List? ?? [];
    todayOrders = ordersList.map((o) => Order.fromJson(o)).toList();
  }

  void updateDirectories(Map<String, dynamic> data) {
    if (data['settings'] != null) {
      settings = Settings.fromJson(data['settings']);
    }
    if (data['pricing'] != null) {
      pricing = PricingConfig.fromJson(data['pricing']);
    }
    if (data['x5Settings'] != null) {
      x5Settings = X5Settings.fromJson(data['x5Settings']);
    }
  }
}

// ===== API СЕРВИС =====
class ApiService {
  final ApiClient _apiClient = ApiClient();
  final AppCache _cache = AppCache();

  ApiClient get apiClient => _apiClient;
  AppCache get cache => _cache;

  Future<void> loadAllData() async {
    try {
      logMessage('🔄 [API] loadAllData() начат', category: 'API');
      final todayResponse = await _apiClient.getTodayData();
      _cache.updateTodayData(todayResponse);
      logMessage('🔄 [API] todayResponse: shifts=${_cache.todayShifts.length}, activeShift=${_cache.activeShift?.id ?? 'null'}, status=${_cache.activeShift?.status ?? 'null'}', category: 'API');

      final dirsResponse = await _apiClient.getDirectories();
      _cache.updateDirectories(dirsResponse);
      logMessage('🔄 [API] directories получены', category: 'API');

      logMessage('✅ [API] Все данные загружены', category: 'API');
    } catch (e) {
      logMessage('❌ [API] Ошибка загрузки: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  // ===== СМЕНА =====

  Future<Shift> startShift() async {
    try {
      logMessage('🔄 [API] startShift()', category: 'API');
      
      if (_cache.activeShift != null) {
        logMessage('⚠️ [API] Уже есть смена id=${_cache.activeShift!.id}, status=${_cache.activeShift!.status}', category: 'API');
        return _cache.activeShift!;
      }
      
      final response = await _apiClient.startShift();
      final shift = Shift.fromJson(response);
      
      // ===== ВАЖНО: ПРОВЕРЯЕМ СТАТУС =====
      if (shift.status == 'active') {
        logMessage('⚠️ [API] Сервер вернул статус active, меняем на paused', category: 'API');
        await _apiClient.pauseShift(
          shift.id,
          addedWorkSeconds: 0,
          addedIdleSeconds: 0,
          totalPaidDistance: 0,
          totalIdleDistance: 0,
          totalOrderTimeSeconds: 0,
          ordersCount: 0,
          totalIncome: 0,
          totalExpenses: 0,
          netProfit: 0,
        );
        await loadAllData();
        final updatedShift = _cache.activeShift;
        if (updatedShift != null) {
          logMessage('✅ [API] Статус обновлён: ${updatedShift.status}', category: 'API');
          return updatedShift;
        }
        return shift;
      }
      
      _cache.activeShift = shift;
      logMessage('✅ [API] Создана смена id=${shift.id}, status=${shift.status}', category: 'API');
      return shift;
    } catch (e) {
      logMessage('❌ [API] Ошибка создания смены: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<void> pauseShift(
  int shiftId, {
  int? durationSeconds,
  required int addedWorkSeconds,
  required int addedIdleSeconds,
  required double totalPaidDistance,
  required double totalIdleDistance,
  required int totalOrderTimeSeconds,
  required int ordersCount,
  required double totalIncome,
  required double totalExpenses,
  required double netProfit,
}) async {
  try {
    await _apiClient.pauseShift(
      shiftId,
      durationSeconds: durationSeconds ?? 0,  // <-- Всегда передаём
      addedWorkSeconds: addedWorkSeconds,
      addedIdleSeconds: addedIdleSeconds,
      totalPaidDistance: totalPaidDistance,
      totalIdleDistance: totalIdleDistance,
      totalOrderTimeSeconds: totalOrderTimeSeconds,
      ordersCount: ordersCount,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
    );
    await loadAllData();
    logMessage('✅ [API] Смена приостановлена', category: 'API');
  } catch (e) {
    logMessage('❌ [API] Ошибка приостановки: $e', category: 'API', level: LogLevel.error);
    rethrow;
  }
}

  Future<void> resumeShift(int shiftId) async {
    try {
      await _apiClient.resumeShift(shiftId);
      await loadAllData();
      logMessage('✅ [API] Смена возобновлена', category: 'API');
    } catch (e) {
      logMessage('❌ [API] Ошибка возобновления: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<void> updateShiftState(
  int shiftId, {
  int? durationSeconds,
  double? totalPaidDistance,
  double? totalIdleDistance,
  int? totalOrderTimeSeconds,
  int? ordersCount,
  double? totalIncome,
  double? totalExpenses,
  double? netProfit,
}) async {
  try {
    logMessage('🔄 [API] Обновление состояния смены $shiftId', category: 'API');
    await _apiClient.updateShiftState(
      shiftId,
      durationSeconds: durationSeconds,
      totalPaidDistance: totalPaidDistance,
      totalIdleDistance: totalIdleDistance,
      totalOrderTimeSeconds: totalOrderTimeSeconds,
      ordersCount: ordersCount,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
    );
    logMessage('✅ [API] Состояние смены обновлено', category: 'API');
  } catch (e) {
    logMessage('⚠️ [API] Ошибка обновления состояния смены: $e', category: 'API');
  }
}

  Future<void> completeShift(
  int shiftId, {
  int? durationSeconds,
  double? totalPaidDistance,
  double? totalIdleDistance,
  int? totalOrderTimeSeconds,
  int? ordersCount,
  double? totalIncome,
  double? totalExpenses,
  double? netProfit,
}) async {
  try {
    await _apiClient.completeShift(
      shiftId,
      durationSeconds: durationSeconds ?? 0,  // <-- Всегда передаём
      totalPaidDistance: totalPaidDistance ?? 0.0,
      totalIdleDistance: totalIdleDistance ?? 0.0,
      totalOrderTimeSeconds: totalOrderTimeSeconds ?? 0,
      ordersCount: ordersCount ?? 0,
      totalIncome: totalIncome ?? 0.0,
      totalExpenses: totalExpenses ?? 0.0,
      netProfit: netProfit ?? 0.0,
    );
    _cache.activeShift = null;
    await loadAllData();
    logMessage('✅ [API] Смена завершена', category: 'API');
  } catch (e) {
    logMessage('❌ [API] Ошибка завершения: $e', category: 'API', level: LogLevel.error);
    rethrow;
  }
}

  // ===== ЗАКАЗ =====

  Future<Order> createOrder(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.createOrder(data);
      final order = Order.fromJson(response);
      _cache.todayOrders.add(order);
      final deliveries = data['deliveries'] as List?;
      if (deliveries != null) {
        logMessage('📦 Создано ${deliveries.length} доставок для заказа ${order.id}', category: 'API');
      }
      logMessage('✅ [API] Заказ создан', category: 'API');
      return order;
    } catch (e) {
      logMessage('❌ [API] Ошибка создания заказа: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<void> completeOrder(int orderId) async {
    try {
      await _apiClient.completeOrder(orderId);
      await loadAllData();
      logMessage('✅ [API] Заказ завершён', category: 'API');
    } catch (e) {
      logMessage('❌ [API] Ошибка завершения заказа: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }
}