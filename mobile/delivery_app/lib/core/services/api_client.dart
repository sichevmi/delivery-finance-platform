import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:delivery_app/logger.dart';

class ApiClient {
  static const String baseUrl = 'https://тест.финфлоу.рф/api'; // TODO: заменить на реальный URL
  
  
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

  // ===== СИНХРОНИЗАЦИЯ =====

  Future<Map<String, dynamic>> syncShifts(List<Map<String, dynamic>> shifts) async {
    try {
      logMessage('📤 Отправка ${shifts.length} смен', category: 'API');
      final response = await _dio.post(
        '/sync/shifts',
        data: {'shifts': shifts},
      );
      logMessage('✅ Смены синхронизированы', category: 'API');
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка syncShifts: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> syncOrders(List<Map<String, dynamic>> orders) async {
    try {
      logMessage('📤 Отправка ${orders.length} заказов', category: 'API');
      final response = await _dio.post(
        '/sync/orders',
        data: {'orders': orders},
      );
      logMessage('✅ Заказы синхронизированы', category: 'API');
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка syncOrders: $e', category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> syncSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _dio.post(
        '/sync/settings',
        data: settings,
      );
      return response.data;
    } catch (e) {
      logMessage('⚠️ Ошибка syncSettings: $e', category: 'API', level: LogLevel.error);
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
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final response = await Dio().post(
            '${ApiClient.baseUrl}/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(headers: {'Content-Type': 'application/json'}),
          );
          final newToken = response.data['accessToken'];
          await _storage.write(key: 'access_token', value: newToken);
          
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await Dio().fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
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
    handler.next(err);
  }
}