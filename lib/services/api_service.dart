import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/department_tree.dart';
import '../models/message.dart';

class ApiService extends ChangeNotifier {
  late Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: kIsWeb ? 'https://localhost:3000' : 'https://10.0.2.2:3000',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
          debugPrint('🔐 Token added to request: ${options.path}');
        } else {
          debugPrint('⚠️ No token for request: ${options.path}');
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        debugPrint(
            '🔴 Dio error: ${error.response?.statusCode} - ${error.response?.data}');
        return handler.next(error);
      },
    ));

    if (!kIsWeb && kDebugMode) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      if (_authToken != null) {
        debugPrint('✅ Token loaded from storage');
      } else {
        debugPrint('⚠️ No token in storage');
      }
    } catch (e) {
      debugPrint('🔴 Failed to load token: $e');
    }
  }

  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    debugPrint('🔐 Token cleared');
  }

  Future<Map<String, dynamic>> register({
    required String login,
    required String lastName,
    required String firstName,
    required String patronymic,
    required String password,
    required String publicKey,
    required String occupation,
    required String? departmentId,
  }) async {
    try {
      final response = await _dio.post('/api/register', data: {
        'login': login,
        'last_name': lastName,
        'first_name': firstName,
        'patronymic': patronymic.isEmpty ? null : patronymic,
        'password': password,
        'public_key': publicKey,
        'occupation': occupation.isEmpty ? null : occupation,
        'department_id': departmentId,
      });

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return {
          'success': false,
          'error': 'Логин уже занят',
        };
      }
      debugPrint(
          '🔴 Register error: ${e.response?.statusCode} - ${e.response?.data}');
      return {
        'success': false,
        'error': 'Ошибка соединения с сервером: ${e.message}',
      };
    } catch (e) {
      debugPrint('🔴 Register unknown error: $e');
      return {
        'success': false,
        'error': 'Неизвестная ошибка: $e',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Login attempt for: $login');

      final response = await _dio.post('/api/login', data: {
        'login': login,
        'password': password,
      });

      final token = response.data['token'] as String;
      final userId = response.data['user_id'] as String;
      final role = response.data['role'] as String;

      if (token.isEmpty) {
        debugPrint('🔴 Login failed: empty token');
        return {
          'success': false,
          'error': 'Сервер не вернул токен',
        };
      }

      _authToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_id', userId);
      await prefs.setString('user_role', role);

      debugPrint('✅ Login successful, token saved');
      debugPrint('📝 User ID: $userId');
      debugPrint('👤 Role: $role');

      return {
        'success': true,
        'token': token,
        'userId': userId,
        'role': role,
      };
    } on DioException catch (e) {
      debugPrint('🔴 Login Dio error: ${e.response?.statusCode}');
      if (e.response?.statusCode == 401) {
        return {
          'success': false,
          'error': 'Неверный логин или пароль',
        };
      }
      if (e.response?.statusCode == 403) {
        return {
          'success': false,
          'error': 'Аккаунт не подтверждён администратором',
        };
      }
      return {
        'success': false,
        'error': 'Ошибка соединения: ${e.message}',
      };
    } catch (e) {
      debugPrint('🔴 Login unknown error: $e');
      return {
        'success': false,
        'error': 'Неизвестная ошибка: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final response = await _dio.get('/api/departments');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('🔴 Error loading departments: $e');
      return [];
    }
  }

  Future<List<DepartmentTree>> getDepartmentTree() async {
    try {
      final response = await _dio.get('/api/departments/tree');
      final List data = response.data;
      return data.map((json) => DepartmentTree.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔴 Error loading department tree: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createDirectChat(String participantId) async {
    try {
      debugPrint('💬 Creating chat with participant: $participantId');

      if (_authToken == null) {
        debugPrint('🔴 Cannot create chat: no auth token');
        return {
          'success': false,
          'error': 'Не авторизован',
        };
      }

      final response = await _dio.post('/api/chats/create', data: {
        'participant_id': participantId,
      });

      debugPrint('✅ Chat created: ${response.data['chat_id']}');

      return {
        'success': true,
        'chat_id': response.data['chat_id'],
        'participants': response.data['participants'],
      };
    } on DioException catch (e) {
      debugPrint(
          '🔴 Create chat error: ${e.response?.statusCode} - ${e.response?.data}');
      return {
        'success': false,
        'error': 'Ошибка создания чата: ${e.message}',
      };
    } catch (e) {
      debugPrint('🔴 Create chat unknown error: $e');
      return {
        'success': false,
        'error': 'Неизвестная ошибка: $e',
      };
    }
  }

  Future<Map<String, dynamic>> sendMessage(
      String chatId, String encryptedContent) async {
    try {
      final response = await _dio.post('/api/messages/send', data: {
        'chat_id': chatId,
        'encrypted_content': encryptedContent,
      });

      return {
        'success': true,
        'message_id': response.data['id'],
        'created_at': response.data['created_at'],
      };
    } catch (e) {
      debugPrint('🔴 Send message error: $e');
      return {
        'success': false,
        'error': 'Ошибка отправки: $e',
      };
    }
  }

  Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final response = await _dio.get('/api/chats/$chatId/messages');
      final List data = response.data;
      return data.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔴 Get messages error: $e');
      return [];
    }
  }

  Future<String?> getUserPublicKey(String userId) async {
    try {
      final response = await _dio.get('/api/users/$userId/public_key');
      String key = response.data['public_key'] as String;
      // Очищаем ключ от пробелов и переносов строк
      key = key.trim().replaceAll('\n', '').replaceAll('\r', '');
      return key;
    } catch (e) {
      debugPrint('🔴 Get user public key error: $e');
      return null;
    }
  }

  Future<bool> saveChatKey(String chatId, String encryptedKey) async {
    try {
      await _dio.post('/api/chat/key/save', data: {
        'chat_id': chatId,
        'encrypted_key': encryptedKey,
      });
      return true;
    } catch (e) {
      debugPrint('🔴 Save chat key error: $e');
      return false;
    }
  }

  Future<String?> getChatKey(String chatId) async {
    try {
      final response = await _dio.get('/api/chat/key/$chatId');
      return response.data['encrypted_key'];
    } catch (e) {
      debugPrint('🔴 Get chat key error: $e');
      return null;
    }
  }
}
