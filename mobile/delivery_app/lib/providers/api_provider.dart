import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/services/storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://тест.финфлоу.рф/api/v1', // замените на ваш IP
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Интерцептор для добавления access токена
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
      // Если 401 – попробуем обновить токен
      if (error.response?.statusCode == 401) {
        final storage = ref.read(storageServiceProvider);
        final refreshToken = await storage.getRefreshToken();
        if (refreshToken != null) {
          try {
            // Вызываем /auth/refresh
            final dio2 = Dio(BaseOptions(baseUrl: 'http://192.168.1.121:8001/api/v1'));
            final response = await dio2.post('/auth/refresh', data: {'refresh_token': refreshToken});
            final newAccess = response.data['access_token'];
            final newRefresh = response.data['refresh_token'] ?? refreshToken; // или новый refresh, если приходит
            await storage.saveTokens(newAccess, newRefresh);

            // Повторяем исходный запрос с новым токеном
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccess';
            final clone = await dio.request(opts.path,
                options: Options(method: opts.method, headers: opts.headers),
                data: opts.data,
                queryParameters: opts.queryParameters);
            return handler.resolve(clone);
          } catch (e) {
            // Если обновление не удалось, разлогиниваем
            await storage.clearTokens();
            // Можно выбросить ошибку или редирект
            return handler.reject(error);
          }
        }
      }
      return handler.next(error);
    },
  ));

  return dio;
});

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());