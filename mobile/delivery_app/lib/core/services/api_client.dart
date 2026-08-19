import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:delivery_app/logger.dart';

class ApiClient {
  static const String baseUrl = 'http://195.19.20.178:8001/api/v1';

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(_LoggingInterceptor());
  }

  Dio get dio => _dio;

  // ===== АУТЕНТИФИКАЦИЯ =====

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    logMessage('🔑 Токены сохранены', category: 'API');
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    logMessage('🔑 Токены удалены', category: 'API');
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  // ===== ЛОГИН =====

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка логина: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка обновления токена: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(
        '/auth/logout',
        data: {'refresh_token': refreshToken},
      );
      logMessage('🚪 Выход выполнен', category: 'API');
    } catch (e) {
      logMessage('⚠️ Ошибка выхода: $e', category: 'API', level: LogLevel.error);
    }
  }

  // ===== СМЕНЫ (НОВАЯ ЛОГИКА) =====

  Future<Map<String, dynamic>> startShift() async {
    try {
      final response = await _dio.post('/shifts/start');
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка создания смены: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> pauseShift(
    int shiftId, {
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
      final data = {
        'addedWorkSeconds': addedWorkSeconds,
        'addedIdleSeconds': addedIdleSeconds,
        'totalPaidDistance': totalPaidDistance,
        'totalIdleDistance': totalIdleDistance,
        'totalOrderTimeSeconds': totalOrderTimeSeconds,
        'ordersCount': ordersCount,
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netProfit': netProfit,
      };
      
      logMessage('⏸️ [API] Приостановка смены $shiftId', category: 'API');
      
      final response = await _dio.post(
        '/shifts/$shiftId/pause',
        data: data,
      );
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка приостановки смены: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resumeShift(int shiftId) async {
    try {
      logMessage('▶️ [API] Возобновление смены $shiftId', category: 'API');
      
      final response = await _dio.post(
        '/shifts/$shiftId/resume',
      );
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка возобновления смены: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeShift(
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
      final data = <String, dynamic>{};
      if (totalPaidDistance != null) data['totalPaidDistance'] = totalPaidDistance;
      if (totalIdleDistance != null) data['totalIdleDistance'] = totalIdleDistance;
      if (totalOrderTimeSeconds != null) data['totalOrderTimeSeconds'] = totalOrderTimeSeconds;
      if (ordersCount != null) data['ordersCount'] = ordersCount;
      if (totalIncome != null) data['totalIncome'] = totalIncome;
      if (totalExpenses != null) data['totalExpenses'] = totalExpenses;
      if (netProfit != null) data['netProfit'] = netProfit;
      
      logMessage('📤 [API] Завершение смены $shiftId', category: 'API');
      
      final response = await _dio.post(
        '/shifts/$shiftId/complete',
        data: data,
      );
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка завершения смены: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  // ===== ЗАКАЗЫ =====

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    try {
      final requestData = {
        'serviceName': data['serviceName'],
        'coefficient': data['coefficient'],
        'deliveryNumber': data['deliveryNumber'],
        'totalPaidDistance': data['totalPaidDistance'],
        'totalIncome': data['totalIncome'],
        'totalExpenses': data['totalExpenses'],
        'netProfit': data['netProfit'],
        'totalTimeSeconds': data['totalTimeSeconds'],
        'shopAddress': data['shopAddress'] ?? '',
        'deliveries': data['deliveries'] ?? [],
      };
      
      logMessage('📤 [API] Создание заказа', category: 'API');
      
      final response = await _dio.post(
        '/orders',
        data: requestData,
      );
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка создания заказа: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeOrder(int orderId) async {
    try {
      final response = await _dio.post('/orders/$orderId/complete');
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка завершения заказа: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  // ===== ЗАГРУЗКА ДАННЫХ =====

  Future<Map<String, dynamic>> getTodayData() async {
    try {
      final response = await _dio.get('/sync/today');
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка getTodayData: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  // ===== СПРАВОЧНИКИ =====

  Future<Map<String, dynamic>> getDirectories() async {
    try {
      final response = await _dio.get('/directories');
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка getDirectories: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _dio.post('/directories/settings', data: settings);
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка updateSettings: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updatePricing(Map<String, dynamic> pricing) async {
    try {
      final response = await _dio.post('/directories/pricing', data: pricing);
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка updatePricing: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateX5Settings(Map<String, dynamic> x5Settings) async {
    try {
      final response = await _dio.post('/directories/x5', data: x5Settings);
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка updateX5Settings: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }
}

// ===== ИНТЕРСЕПТОРЫ =====

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          logMessage('🔄 Обновление токена...', category: 'API');
          final response = await Dio().post(
            '${ApiClient.baseUrl}/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: Options(headers: {'Content-Type': 'application/json'}),
          );
          final newToken = response.data['access_token'];
          if (newToken != null && newToken.isNotEmpty) {
            await _storage.write(key: 'access_token', value: newToken);
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await Dio().fetch(err.requestOptions);
            handler.resolve(retryResponse);
            return;
          }
        } catch (_) {
          await _storage.delete(key: 'access_token');
          await _storage.delete(key: 'refresh_token');
        }
      }
    }
    handler.next(err);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logMessage('🌐 ${options.method} ${options.path}', category: 'API');
    if (options.data != null) {
      logMessage('📦 Data: ${options.data}', category: 'API', level: LogLevel.debug);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logMessage('✅ ${response.statusCode} ${response.requestOptions.path}', category: 'API');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logMessage('❌ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}',
        category: 'API', level: LogLevel.error);
    if (err.response?.data != null) {
      logMessage('📦 Error data: ${err.response?.data}', category: 'API', level: LogLevel.error);
    }
    handler.next(err);
  }
}