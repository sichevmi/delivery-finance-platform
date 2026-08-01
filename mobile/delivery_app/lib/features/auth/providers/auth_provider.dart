import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:delivery_app/core/services/storage_service.dart';
import 'package:delivery_app/features/auth/models/user.dart';
import 'package:delivery_app/core/providers/api_provider.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final Dio dio;
  final StorageService storage;

  AuthNotifier(this.ref, this.dio, this.storage) : super(AuthState());

  // ===== РЕГИСТРАЦИЯ =====
  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await dio.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );
      // После регистрации сразу логинимся
      await login(email, password);
    } on DioException catch (e) {
      final errorMsg = e.response?.data['detail'] ?? 
                       e.response?.data['message'] ?? 
                       'Ошибка регистрации';
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Неизвестная ошибка регистрации',
      );
      rethrow;
    }
  }

  // ===== ВХОД =====
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      print('🔐 Login response status: ${response.statusCode}');
      print('🔐 Login response data: ${response.data}');

      final access = response.data['access_token'];
      final refresh = response.data['refresh_token'];
      await storage.saveTokens(access, refresh);

      // Получаем данные пользователя
      final userResponse = await dio.get('/auth/me');
      print('👤 User response: ${userResponse.data}');
      final user = User.fromJson(userResponse.data);
      
      await storage.saveUserId(user.id);
      
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
    } on DioException catch (e) {
      print('❌ DioException: ${e.response?.statusCode} - ${e.response?.data}');
      final errorMsg = e.response?.data['detail'] ?? 
                       e.response?.data['message'] ?? 
                       'Ошибка входа';
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: errorMsg,
      );
      rethrow;
    } catch (e) {
      print('❌ Unexpected error: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Неизвестная ошибка',
      );
      rethrow;
    }
  }

  // ===== АВТОМАТИЧЕСКАЯ АВТОРИЗАЦИЯ =====
  Future<bool> autoLogin() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final hasTokens = await storage.hasTokens();
      if (!hasTokens) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
        );
        return false;
      }

      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
        );
        return false;
      }

      // Пытаемся обновить access-токен
      try {
        final refreshResponse = await dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        
        final newAccessToken = refreshResponse.data['access_token'];
        await storage.updateAccessToken(newAccessToken);
        
        // Получаем данные пользователя
        final userResponse = await dio.get('/auth/me');
        final user = User.fromJson(userResponse.data);
        await storage.saveUserId(user.id);
        
        state = state.copyWith(
          user: user,
          isLoading: false,
          isAuthenticated: true,
          error: null,
        );
        return true;
      } on DioException catch (e) {
        // Если refresh-токен истёк – чистим хранилище
        if (e.response?.statusCode == 401) {
          await storage.clearTokens();
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            error: 'Сессия истекла, войдите заново',
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            error: 'Ошибка обновления сессии',
          );
        }
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Ошибка автоматического входа',
      );
      return false;
    }
  }

  // ===== ОБНОВЛЕНИЕ ACCESS-ТОКЕНА =====
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      
      final newAccessToken = response.data['access_token'];
      await storage.updateAccessToken(newAccessToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===== ВЫХОД =====
  Future<void> logout() async {
    try {
      // Уведомляем сервер о выходе (опционально)
      await dio.post('/auth/logout');
    } catch (e) {
      // Игнорируем ошибки при выходе
    }
    await storage.clearTokens();
    state = AuthState();
  }

  // ===== ПРОВЕРКА ТЕКУЩЕЙ СЕССИИ =====
  Future<void> checkAuth() async {
    final token = await storage.getAccessToken();
    if (token != null) {
      try {
        final response = await dio.get('/auth/me');
        final user = User.fromJson(response.data);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
        );
      } catch (e) {
        await storage.clearTokens();
        state = AuthState();
      }
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(ref, dio, storage);
});