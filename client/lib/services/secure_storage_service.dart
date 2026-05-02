import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// НЕ импортируй dart:io напрямую, если планируешь билд под Web

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // На вебе используем SharedPreferences (LocalStorage),
  // на мобилках - FlutterSecureStorage
  final FlutterSecureStorage? _secureStorage = kIsWeb
      ? null
      : const FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {
    if (_secureStorage != null) {
      await _secureStorage!.write(key: key, value: value);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  Future<String?> read({required String key}) async {
    if (_secureStorage != null) {
      return await _secureStorage!.read(key: key);
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  Future<void> delete({required String key}) async {
    if (_secureStorage != null) {
      await _secureStorage!.delete(key: key);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }

  Future<bool> containsKey({required String key}) async {
    if (_secureStorage != null) {
      // Исправляем потенциальный баг с проверкой наличия ключа
      final value = await _secureStorage!.read(key: key);
      return value != null;
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    }
  }
}
