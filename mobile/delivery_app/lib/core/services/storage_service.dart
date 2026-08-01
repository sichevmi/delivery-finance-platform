import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await _prefs;
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> updateAccessToken(String newAccessToken) async {
    final prefs = await _prefs;
    await prefs.setString(_accessTokenKey, newAccessToken);
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await _prefs;
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_userIdKey);
  }

  Future<bool> hasTokens() async {
    final prefs = await _prefs;
    final refresh = prefs.getString(_refreshTokenKey);
    return refresh != null && refresh.isNotEmpty;
  }

  Future<void> clearTokens() async {
    final prefs = await _prefs;
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});