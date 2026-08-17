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
    // Используем firstWhereOrNull для безопасного поиска активной смены
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

  // Геттер для доступа к ApiClient (используется в settings_provider)
  ApiClient get apiClient => _apiClient;

  // Загрузка всех данных при старте
  Future<void> loadAllData() async {
    try {
      final todayResponse = await _apiClient.getTodayData();
      _cache.updateTodayData(todayResponse);

      final dirsResponse = await _apiClient.getDirectories();
      _cache.updateDirectories(dirsResponse);

      logMessage('✅ Все данные загружены с сервера', category: 'API');
    } catch (e) {
      logMessage('❌ Ошибка загрузки данных: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  // Смена
  Future<Shift> startShift() async {
    try {
      final response = await _apiClient.startShift();
      final shift = Shift.fromJson(response);
      _cache.activeShift = shift;
      logMessage('✅ Смена начата на сервере', category: 'API');
      return shift;
    } catch (e) {
      logMessage('❌ Ошибка начала смены: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<void> completeShift(int shiftId) async {
    try {
      await _apiClient.completeShift(shiftId);
      _cache.activeShift = null;
      await loadAllData();
      logMessage('✅ Смена завершена на сервере', category: 'API');
    } catch (e) {
      logMessage('❌ Ошибка завершения смены: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  // Заказ
  // В ApiService классе, метод createOrder:

Future<Order> createOrder(Map<String, dynamic> data) async {
  try {
    final response = await _apiClient.createOrder(data);
    final order = Order.fromJson(response);
    _cache.todayOrders.add(order);
    
    // Если есть доставки — добавляем их в кэш (опционально)
    final deliveries = data['deliveries'] as List?;
    if (deliveries != null) {
      logMessage('📦 Создано ${deliveries.length} доставок для заказа ${order.id}', category: 'API');
    }
    
    logMessage('✅ Заказ создан на сервере', category: 'API');
    return order;
  } catch (e) {
    logMessage('❌ Ошибка создания заказа: $e', category: 'API', level: LogLevel.error);
    rethrow;
  }
}

  Future<void> completeOrder(int orderId) async {
    try {
      await _apiClient.completeOrder(orderId);
      await loadAllData();
      logMessage('✅ Заказ завершён на сервере', category: 'API');
    } catch (e) {
      logMessage('❌ Ошибка завершения заказа: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  AppCache get cache => _cache;
}