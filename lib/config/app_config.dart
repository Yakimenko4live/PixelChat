import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl {
    // Для Android эмулятора
    if (Platform.isAndroid) {
      // В эмуляторе localhost = 10.0.2.2
      return 'https://10.0.2.2:3000';
    }

    // Для iOS симулятора
    if (Platform.isIOS) {
      return 'https://localhost:3000';
    }

    // Для Web (Chrome)
    if (kIsWeb) {
      return 'https://localhost:3000';
    }

    // Для реальных устройств - используем .env если есть
    if (dotenv.env['API_BASE_URL'] != null) {
      return dotenv.env['API_BASE_URL']!;
    }

    // Fallback
    return 'https://localhost:3000';
  }

  static String get wsBaseUrl {
    if (Platform.isAndroid) {
      return 'wss://10.0.2.2:3000';
    }

    if (Platform.isIOS) {
      return 'wss://localhost:3000';
    }

    if (kIsWeb) {
      return 'wss://localhost:3000';
    }

    if (dotenv.env['WS_BASE_URL'] != null) {
      return dotenv.env['WS_BASE_URL']!;
    }

    return 'wss://localhost:3000';
  }

  static bool get isDevelopment {
    return kDebugMode;
  }
}
