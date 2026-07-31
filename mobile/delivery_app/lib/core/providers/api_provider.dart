import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/services/storage_service.dart';

// Базовый URL по умолчанию — для локальной разработки
const String defaultBaseUrl = 'http://localhost:8001/api/v1';

// Получаем URL из dart-define или используем default
String get baseUrl {
  // const String.fromEnvironment работает только если переменная передана через --dart-define
  const String envBaseUrl = String.fromEnvironment('API_BASE_URL');
  return envBaseUrl.isNotEmpty ? envBaseUrl : defaultBaseUrl;
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // Разрешаем самоподписанные сертификаты для тестового стенда (если используете HTTPS)
  // (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
  //   client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  //   return client;
  // };

  // Интерцепторы (без изменений)
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final storage = ref.read(storageServiceProvider);
      final token = await storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final storage = ref.read(storageServiceProvider);
        final refreshToken = await storage.getRefreshToken();
        if (refreshToken != null) {
          try {
            final response = await dio
                .post('/auth/refresh', data: {'refresh_token': refreshToken});
            final newAccess = response.data['access_token'];
            final newRefresh = response.data['refresh_token'] ?? refreshToken;
            await storage.saveTokens(newAccess, newRefresh);
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccess';
            final clone = await dio.request(opts.path,
                options: Options(method: opts.method, headers: opts.headers),
                data: opts.data,
                queryParameters: opts.queryParameters);
            return handler.resolve(clone);
          } catch (e) {
            await storage.clearTokens();
            return handler.reject(error);
          }
        }
      }
      return handler.next(error);
    },
  ));

  return dio;
});

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
