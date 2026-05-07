import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  SecureStorageService._(this._preferences);

  final SharedPreferencesAsync _preferences;

  static Future<SecureStorageService> create() async {
    return SecureStorageService._(SharedPreferencesAsync());
  }

  Future<String?> read(String key) {
    return _preferences.getString(key);
  }

  Future<void> write({
    required String key,
    required String value,
  }) async {
    await _preferences.setString(key, value);
  }

  Future<void> delete(String key) async {
    await _preferences.remove(key);
  }
}
