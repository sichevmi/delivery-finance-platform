import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- добавить

class StorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    print('💾 Saving tokens...');
    final prefs = await _prefs;
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    print('💾 Tokens saved successfully');
    
    final saved = prefs.getString(_accessTokenKey);
    print('💾 Saved access token: ${saved != null ? saved.substring(0, 20) + "..." : "null"}');
  }

  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    final token = prefs.getString(_accessTokenKey);
    print('🔑 Access token: ${token != null ? token.substring(0, 20) + "..." : "null"}');
    return token;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    final token = prefs.getString(_refreshTokenKey);
    print('🔑 Refresh token: ${token != null ? token.substring(0, 20) + "..." : "null"}');
    return token;
  }

  Future<void> updateAccessToken(String newAccessToken) async {
    final prefs = await _prefs;
    await prefs.setString(_accessTokenKey, newAccessToken);
    print('💾 Access token updated');
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
    final has = refresh != null && refresh.isNotEmpty;
    print('💾 hasTokens: $has');
    return has;
  }

  Future<void> clearTokens() async {
    final prefs = await _prefs;
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    print('💾 Tokens cleared');
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});