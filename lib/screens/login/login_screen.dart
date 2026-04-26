import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'login_ui.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSwitchToRegister;

  const LoginScreen({super.key, required this.onSwitchToRegister});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final login = _loginController.text.trim();
    final password = _passwordController.text;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.login(
        login: login,
        password: password,
        apiService: apiService,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/chat_list');
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('ключ') || e.toString().contains('Ключи')) {
          _showKeyErrorDialog();
        } else {
          setState(() {
            _errorMessage = e.toString();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showKeyErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка ключей шифрования'),
        content: const Text(
          'У вас проблемы с ключами шифрования.\n\n'
          'Пожалуйста, зарегистрируйтесь заново или обратитесь к администратору.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSwitchToRegister();
            },
            child: const Text('Зарегистрироваться'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  String? _validateLogin(String? value) {
    if (value == null || value.isEmpty) return 'Введите логин';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LoginUI(
      formKey: _formKey,
      loginController: _loginController,
      passwordController: _passwordController,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onLogin: _login,
      onSwitchToRegister: widget.onSwitchToRegister,
      validateLogin: _validateLogin,
      validatePassword: _validatePassword,
    );
  }
}
