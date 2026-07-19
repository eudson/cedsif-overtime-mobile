import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  const LocalStorage(this._preferences);

  final SharedPreferences _preferences;

  String? getString(String key) => _preferences.getString(key);

  bool? getBool(String key) => _preferences.getBool(key);

  int? getInt(String key) => _preferences.getInt(key);

  double? getDouble(String key) => _preferences.getDouble(key);

  List<String>? getStringList(String key) => _preferences.getStringList(key);

  bool containsKey(String key) => _preferences.containsKey(key);

  Future<bool> setString(String key, String value) =>
      _preferences.setString(key, value);

  Future<bool> setBool(String key, {required bool value}) =>
      _preferences.setBool(key, value);

  Future<bool> setInt(String key, int value) => _preferences.setInt(key, value);

  Future<bool> setDouble(String key, double value) =>
      _preferences.setDouble(key, value);

  Future<bool> setStringList(String key, List<String> value) =>
      _preferences.setStringList(key, value);

  Future<bool> remove(String key) => _preferences.remove(key);

  Future<bool> clear() => _preferences.clear();
}
