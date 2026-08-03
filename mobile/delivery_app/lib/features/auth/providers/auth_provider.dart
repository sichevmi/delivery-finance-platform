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

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await dio.post(
        '/api/v1/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );
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

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      print('🔐 Login response status: ${response.statusCode}');
      print('🔐 Login response data: ${response.data}');

      final access = response.data['access_token'];
      final refresh = response.data['refresh_token'];
      await storage.saveTokens(access, refresh);

      final userResponse = await dio.get('/api/v1/auth/hello');
      print('👤 User response: ${userResponse.data}');
      
      dynamic userData;
      if (userResponse.data is Map && userResponse.data.containsKey('user')) {
        userData = userResponse.data['user'];
      } else {
        userData = userResponse.data;
      }
      
      final user = User.fromJson(userData);
      await storage.saveUserId(user.id.toString());
      
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

  Future<bool> autoLogin() async {
    print('🔄 autoLogin() started');
    state = state.copyWith(isLoading: true);
    
    try {
      final hasTokens = await storage.hasTokens();
      print('🔄 hasTokens: $hasTokens');
      
      if (!hasTokens) {
        print('🔄 No tokens found');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
        return false;
      }

      final refreshToken = await storage.getRefreshToken();
      print('🔄 Refresh token: ${refreshToken != null ? refreshToken.substring(0, 20) + "..." : "null"}');
      
      if (refreshToken == null || refreshToken.isEmpty) {
        print('🔄 Refresh token is empty');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
        return false;
      }

      print('🔄 Trying to refresh token...');
      try {
        final refreshResponse = await dio.post(
          '/api/v1/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        
        final newAccessToken = refreshResponse.data['access_token'];
        await storage.updateAccessToken(newAccessToken);
        print('🔄 Token refreshed successfully');
        
        final userResponse = await dio.get('/api/v1/auth/hello');
        dynamic userData;
        if (userResponse.data is Map && userResponse.data.containsKey('user')) {
          userData = userResponse.data['user'];
        } else {
          userData = userResponse.data;
        }
        
        final user = User.fromJson(userData);
        await storage.saveUserId(user.id.toString());
        
        state = state.copyWith(
          user: user,
          isLoading: false,
          isAuthenticated: true,
          error: null,
        );
        print('🔄 Auto-login successful! User: ${user.email}');
        return true;
      } on DioException catch (e) {
        print('🔄 Refresh failed: ${e.response?.statusCode} - ${e.response?.data}');
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
      print('🔄 Unexpected error in autoLogin: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Ошибка автоматического входа',
      );
      return false;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await dio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      
      final newAccessToken = response.data['access_token'];
      await storage.updateAccessToken(newAccessToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===== ИСПРАВЛЕННЫЙ ВЫХОД =====
  Future<void> logout() async {
    try {
      // Получаем refresh_token из хранилища
      final refreshToken = await storage.getRefreshToken();
      
      // Отправляем запрос на сервер с refresh_token
      await dio.post(
        '/api/v1/auth/logout',
        data: {'refresh_token': refreshToken},
      );
      print('🔐 Logout успешно на сервере');
    } catch (e) {
      print('⚠️ Ошибка при выходе на сервере: $e');
    }
    // В любом случае очищаем локальные токены
    await storage.clearTokens();
    state = AuthState();
  }

  Future<void> checkAuth() async {
    final token = await storage.getAccessToken();
    if (token != null) {
      try {
        final response = await dio.get('/api/v1/auth/hello');
        dynamic userData;
        if (response.data is Map && response.data.containsKey('user')) {
          userData = response.data['user'];
        } else {
          userData = response.data;
        }
        final user = User.fromJson(userData);
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