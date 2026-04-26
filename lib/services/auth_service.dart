import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'crypto_service.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _userId;
  bool _isAuthenticated = false;

  String? get token => _token;
  String? get userId => _userId;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(
      String login, String password, ApiService apiService) async {
    final result = await apiService.login(login, password);
    if (result['success']) {
      _token = result['token'];
      _userId = result['userId'];
      _isAuthenticated = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('userId', _userId!);

      notifyListeners();
    } else {
      throw Exception(result['error']);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    _token = null;
    _userId = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _isAuthenticated = _token != null && _userId != null;
    notifyListeners();
  }
}
