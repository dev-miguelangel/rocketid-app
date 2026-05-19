import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _userKey = 'user';
  static const _themeKey = 'themePreference';

  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<void> setAccessToken(String? token) =>
      token == null ? deleteAccessToken() : _storage.write(key: _accessTokenKey, value: token);
  Future<void> deleteAccessToken() => _storage.delete(key: _accessTokenKey);

  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);
  Future<void> setRefreshToken(String? token) =>
      token == null ? deleteRefreshToken() : _storage.write(key: _refreshTokenKey, value: token);
  Future<void> deleteRefreshToken() => _storage.delete(key: _refreshTokenKey);

  Future<Map<String, dynamic>?> get user async {
    final json = await _storage.read(key: _userKey);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<void> setUser(Map<String, dynamic>? user) =>
      user == null ? deleteUser() : _storage.write(key: _userKey, value: jsonEncode(user));
  Future<void> deleteUser() => _storage.delete(key: _userKey);

  /// Estilo de color elegido (storageKey de `AppPaletteId`). Sobrevive al
  /// logout: no se borra en `clearAll` para no reiniciar la preferencia.
  Future<String?> get themePreference => _storage.read(key: _themeKey);
  Future<void> setThemePreference(String key) =>
      _storage.write(key: _themeKey, value: key);

  Future<void> clearAll() async {
    final theme = await themePreference;
    await _storage.deleteAll();
    if (theme != null) await setThemePreference(theme);
  }
}