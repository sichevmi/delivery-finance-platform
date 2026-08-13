import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:dio/dio.dart';
import 'package:delivery_app/core/services/storage_service.dart';
import 'package:delivery_app/features/auth/models/user.dart';
import 'package:delivery_app/core/services/api_client.dart';
import 'package:delivery_app/features/delivery/providers/sync_provider.dart';

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
  final ApiClient apiClient;
  final StorageService storage;

  AuthNotifier(this.ref, this.apiClient, this.storage) : super(AuthState());

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiClient.dio.post(
        '/auth/register',
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
      final response = await apiClient.login(email, password);
      
      final access = response['access_token'];
      final refresh = response['refresh_token'];
      await storage.saveTokens(access, refresh);
      await apiClient.setTokens(access, refresh);

      // Проверяем, что токен сохранился
      final savedToken = await apiClient.getAccessToken();
      logMessage('🔑 Токен сохранён: ${savedToken != null ? savedToken.substring(0, 20) + "..." : "null"}', category: 'AUTH');

      final userResponse = await apiClient.dio.get('/auth/hello');
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
      logMessage('❌ DioException: ${e.response?.statusCode} - ${e.response?.data}');
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
      logMessage('❌ Unexpected error: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Неизвестная ошибка',
      );
      rethrow;
    }
  }

  Future<bool> autoLogin() async {
    logMessage('🔄 autoLogin() started');
    state = state.copyWith(isLoading: true);
    
    try {
      final hasTokens = await storage.hasTokens();
      logMessage('🔄 hasTokens: $hasTokens');
      
      if (!hasTokens) {
        logMessage('🔄 No tokens found');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
        return false;
      }

      final refreshToken = await storage.getRefreshToken();
      
      if (refreshToken == null || refreshToken.isEmpty) {
        logMessage('🔄 Refresh token is empty');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
        return false;
      }

      logMessage('🔄 Trying to refresh token...');
      try {
        final refreshResponse = await apiClient.refreshToken(refreshToken);
        
        final newAccessToken = refreshResponse['access_token'];
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await storage.updateAccessToken(newAccessToken);
          await apiClient.setTokens(newAccessToken, refreshToken);
          logMessage('🔄 Token refreshed successfully');
        }
        
        final userResponse = await apiClient.dio.get('/auth/hello');
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
        logMessage('🔄 Auto-login successful! User: ${user.email}');
        return true;
      } on DioException catch (e) {
        logMessage('🔄 Refresh failed: ${e.response?.statusCode} - ${e.response?.data}');
        if (e.response?.statusCode == 401) {
          await storage.clearTokens();
          await apiClient.clearTokens();
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
      logMessage('🔄 Unexpected error in autoLogin: $e');
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

      final response = await apiClient.refreshToken(refreshToken);
      final newAccessToken = response['access_token'];
      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        await storage.updateAccessToken(newAccessToken);
        await apiClient.setTokens(newAccessToken, refreshToken);
        return true;
      }
      return false;
    } catch (e) {
      logMessage('❌ Error refreshing token: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await apiClient.logout(refreshToken);
      }
    } catch (e) {
      logMessage('⚠️ Ошибка при выходе на сервере: $e');
    }
    await storage.clearTokens();
    await apiClient.clearTokens();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(ref, apiClient, storage);
});