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
    activeShift = todayShifts.cast<Shift?>().firstWhere(
      (s) => s?.status == 'active',
      orElse: () => null,
    );
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
      logMessage('🔄 [API] todayResponse получен: shifts=${_cache.todayShifts.length}, orders=${_cache.todayOrders.length}, activeShift=${_cache.activeShift?.id ?? 'null'}', category: 'API');

      final dirsResponse = await _apiClient.getDirectories();
      _cache.updateDirectories(dirsResponse);
      logMessage('🔄 [API] directories получены', category: 'API');

      logMessage('✅ [API] Все данные загружены с сервера', category: 'API');
    } catch (e) {
      logMessage('❌ [API] Ошибка загрузки данных: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  // ===== СМЕНА =====

  Future<Shift> startShift() async {
    try {
      logMessage('🔄 [API] startShift() вызван', category: 'API');
      
      // Перед созданием смены проверяем, нет ли активной в кеше
      if (_cache.activeShift != null) {
        logMessage('⚠️ [API] В кеше уже есть активная смена id=${_cache.activeShift!.id}', category: 'API');
        // Возвращаем существующую смену из кеша
        return _cache.activeShift!;
      }
      
      final response = await _apiClient.startShift();
      final shift = Shift.fromJson(response);
      _cache.activeShift = shift;
      logMessage('✅ [API] Смена начата на сервере id=${shift.id}', category: 'API');
      return shift;
    } catch (e) {
      logMessage('❌ [API] Ошибка начала смены: $e', category: 'API', level: LogLevel.error);
      
      // Если ошибка "Уже есть активная смена" - перезагружаем данные
      final errorMessage = e.toString();
      if (errorMessage.contains('Уже есть активная смена') || 
          errorMessage.contains('400') ||
          errorMessage.contains('active shift')) {
        logMessage('🔄 [API] Обнаружена активная смена, перезагружаем данные...', category: 'API');
        try {
          await loadAllData();
          if (_cache.activeShift != null) {
            logMessage('✅ [API] Активная смена восстановлена id=${_cache.activeShift!.id}', category: 'API');
            // Возвращаем восстановленную смену
            return _cache.activeShift!;
          }
        } catch (loadError) {
          logMessage('❌ [API] Ошибка перезагрузки данных: $loadError', category: 'API', level: LogLevel.error);
        }
      }
      rethrow;
    }
  }

  Future<void> completeShift(
    int shiftId, {
    double? totalPaidDistance,
    double? totalIdleDistance,
    int? totalOrderTimeSeconds,
    int? ordersCount,
    double? totalIncome,
    double? totalExpenses,
    double? netProfit,
  }) async {
    try {
      logMessage('📤 [API] Отправка завершения смены $shiftId: {totalPaidDistance: $totalPaidDistance, totalIdleDistance: $totalIdleDistance, totalOrderTimeSeconds: $totalOrderTimeSeconds, ordersCount: $ordersCount, totalIncome: $totalIncome, totalExpenses: $totalExpenses, netProfit: $netProfit}', category: 'API');
      
      await _apiClient.completeShift(
        shiftId,
        totalPaidDistance: totalPaidDistance,
        totalIdleDistance: totalIdleDistance,
        totalOrderTimeSeconds: totalOrderTimeSeconds,
        ordersCount: ordersCount,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
      );
      _cache.activeShift = null;
      await loadAllData();
      logMessage('✅ [API] Смена завершена на сервере', category: 'API');
    } catch (e) {
      logMessage('❌ [API] Ошибка завершения смены: $e', category: 'API', level: LogLevel.error);
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
      logMessage('✅ [API] Заказ создан на сервере', category: 'API');
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
      logMessage('✅ [API] Заказ завершён на сервере', category: 'API');
    } catch (e) {
      logMessage('❌ [API] Ошибка завершения заказа: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }
}