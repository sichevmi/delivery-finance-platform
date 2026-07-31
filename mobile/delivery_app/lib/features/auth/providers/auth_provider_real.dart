import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:delivery_app/core/services/storage_service.dart';
import 'package:delivery_app/features/auth/models/user.dart';
import 'package:delivery_app/core/providers/api_provider.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final Dio dio;
  final StorageService storage;

  AuthNotifier(this.ref, this.dio, this.storage) : super(AuthState());

  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await dio
          .post('/auth/register', data: {'email': email, 'password': password});
      // После регистрации сразу логиним?
      await login(email, password);
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.response?.data['detail'] ?? 'Ошибка регистрации');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Неизвестная ошибка');
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await dio
          .post('/auth/login', data: {'email': email, 'password': password});
      print('🔐 Login response status: ${response.statusCode}');
      print('🔐 Login response data: ${response.data}');

      final access = response.data['access_token'];
      final refresh = response.data['refresh_token'];
      await storage.saveTokens(access, refresh);

      final userResponse = await dio.get('/auth/hello');
      print('👤 User response: ${userResponse.data}');
      final user = User.fromJson(userResponse.data['user']);
      state = state.copyWith(user: user, isLoading: false);
    } on DioException catch (e) {
      print('❌ DioException: ${e.response?.statusCode} - ${e.response?.data}');
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['detail'] ?? 'Ошибка входа',
      );
    } catch (e) {
      print('❌ Unexpected error: $e');
      state = state.copyWith(isLoading: false, error: 'Неизвестная ошибка');
    }
  }

  Future<void> logout() async {
    await storage.clearTokens();
    state = AuthState();
  }

  Future<void> checkAuth() async {
    final token = await storage.getAccessToken();
    if (token != null) {
      try {
        final response = await dio.get('/auth/hello');
        final user = User.fromJson(response.data);
        state = state.copyWith(user: user);
      } catch (e) {
        // Токен невалиден, чистим
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