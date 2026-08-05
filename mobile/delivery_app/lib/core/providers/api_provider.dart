import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/logger.dart';
import 'package:dio/dio.dart';
import 'package:delivery_app/core/services/storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://xn--e1aybc.xn--h1agffzbc.xn--p1ai', // ЗАМЕНИТЕ НА ВАШ URL
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final storage = ref.read(storageServiceProvider);
      final token = await storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      // Если 401 – пробуем обновить токен
      if (error.response?.statusCode == 401) {
        final storage = ref.read(storageServiceProvider);
        final refreshToken = await storage.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          try {
            // Обновляем токен
            final response = await dio.post(
              '/auth/refresh',
              data: {'refresh_token': refreshToken},
            );
            final newToken = response.data['access_token'];
            await storage.updateAccessToken(newToken);
            
            // Повторяем оригинальный запрос с новым токеном
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          } catch (e) {
            // Если не удалось обновить – очищаем и выдаём ошибку
            await storage.clearTokens();
            return handler.next(error);
          }
        }
      }
      return handler.next(error);
    },
  ));

  return dio;
});