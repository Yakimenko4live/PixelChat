import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/crypto_service.dart';
import '../services/department_service.dart';
import '../services/secure_storage_service.dart';
import '../models/user.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _cryptoService = CryptoService();
  final _departmentService = DepartmentService();
  final _storage = SecureStorageService();

  bool _isLoginMode = true;
  bool _isLoading = false;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _regLastNameController = TextEditingController();
  final _regFirstNameController = TextEditingController();
  final _regPatronymicController = TextEditingController();
  final _regLoginController = TextEditingController();
  final _regPositionController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();

  int? _selectedDepartmentId;
  List<Map<String, dynamic>> _departments = [];
  bool _isLoadingDepartments = true;

  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
    _fetchDepartments();
  }

  Future<void> _checkAuthAndRedirect() async {
    final token = await _storage.read(key: 'token');
    final isVerified = await _storage.read(key: 'isVerified');

    if (token != null && token.isNotEmpty && isVerified == 'true') {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final departments = await _departmentService.getDepartments();
      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDepartments = false;
        _errorMessage = 'Ошибка загрузки подразделений: $e';
      });
    }
  }

  Future<void> _register() async {
    if (_regPasswordController.text != _regConfirmPasswordController.text) {
      setState(() => _errorMessage = 'Пароли не совпадают');
      return;
    }

    if (_selectedDepartmentId == null) {
      setState(() => _errorMessage = 'Выберите подразделение');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (await _cryptoService.hasPrivateKey()) {
        await _cryptoService.deleteExistingKey();
      }

      await _cryptoService.generateAndSaveKeys();
      final publicKey = await _cryptoService.getPublicKey();

      final request = RegisterRequest(
        lastName: _regLastNameController.text,
        firstName: _regFirstNameController.text,
        patronymic: _regPatronymicController.text.isEmpty
            ? null
            : _regPatronymicController.text,
        login: _regLoginController.text,
        departmentId: _selectedDepartmentId!,
        position: _regPositionController.text,
        publicKey: publicKey,
        password: _regPasswordController.text,
      );

      await _authService.register(request);

      setState(() {
        _successMessage =
            'Регистрация прошла успешно!\nДождитесь подтверждения администратора.';
        _isLoading = false;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isLoginMode = true;
            _successMessage = null;
            _clearRegisterForm();
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.login(
        _loginEmailController.text,
        _loginPasswordController.text,
      );

      await _storage.write(key: 'token', value: response['token']);
      await _storage.write(
        key: 'userId',
        value: response['user_id'].toString(),
      );
      await _storage.write(key: 'role', value: response['role']);
      await _storage.write(
        key: 'isVerified',
        value: response['is_verified'].toString(),
      );

      if (!response['is_verified']) {
        setState(() {
          _successMessage = 'Ваш аккаунт ожидает подтверждения администратора';
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка входа: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _clearRegisterForm() {
    _regLastNameController.clear();
    _regFirstNameController.clear();
    _regPatronymicController.clear();
    _regLoginController.clear();
    _regPositionController.clear();
    _regPasswordController.clear();
    _regConfirmPasswordController.clear();
    setState(() {
      _selectedDepartmentId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey[800],
                ),
                const SizedBox(height: 8),
                Text(
                  'PixelChat',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    final offset = _isLoginMode
                        ? Tween<Offset>(
                            begin: const Offset(-1, 0),
                            end: Offset.zero,
                          )
                        : Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          );
                    return SlideTransition(
                      position: animation.drive(offset),
                      child: child,
                    );
                  },
                  child: _isLoginMode
                      ? _buildLoginForm()
                      : _buildRegisterForm(),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                      _errorMessage = null;
                      _successMessage = null;
                    });
                  },
                  child: Text(
                    _isLoginMode
                        ? 'Нет аккаунта? Зарегистрироваться'
                        : 'Уже есть аккаунт? Войти',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      children: [
        TextField(
          controller: _loginEmailController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Логин',
            labelStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Пароль',
            labelStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[900],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Войти', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      children: [
        TextField(
          controller: _regLastNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Фамилия',
            labelStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regFirstNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Имя',
            labelStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPatronymicController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Отчество (необязательно)',
            labelStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regLoginController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Логин',
            labelStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPositionController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Должность',
            labelStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            _showDepartmentsModal();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.business, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDepartmentId != null
                        ? _departments.firstWhere(
                            (d) => d['id'] == _selectedDepartmentId,
                          )['name']
                        : 'Выберите подразделение',
                    style: TextStyle(
                      color: _selectedDepartmentId != null
                          ? Colors.white
                          : Colors.grey[500],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPasswordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Пароль',
            labelStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regConfirmPasswordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Подтвердите пароль',
            labelStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[900],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Зарегистрироваться',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  void _showDepartmentsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Выберите подразделение',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoadingDepartments)
                const CircularProgressIndicator()
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _departments.length,
                  itemBuilder: (context, index) {
                    final dept = _departments[index];
                    final typeText = dept['type_'] == 'regional'
                        ? 'Окружной'
                        : dept['type_'] == 'subject'
                        ? 'Субъектовый'
                        : 'Районный';
                    return ListTile(
                      title: Text(
                        dept['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        typeText,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedDepartmentId = dept['id'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regLastNameController.dispose();
    _regFirstNameController.dispose();
    _regPatronymicController.dispose();
    _regLoginController.dispose();
    _regPositionController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }
}
