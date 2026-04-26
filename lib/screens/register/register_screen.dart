import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/crypto_service.dart';
import 'register_ui.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterScreen({super.key, required this.onSwitchToLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _loginController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _occupationController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showApprovalMessage = false;

  // Для подразделений
  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;
  bool _isLoadingDepartments = true;
  String? _departmentsError;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final deps = await apiService.getDepartments();
      print('Loaded departments: ${deps.length}'); // Добавь
      setState(() {
        _departments = deps;
        _isLoadingDepartments = false;
        _departmentsError = null;
      });
    } catch (e) {
      print('Error: $e'); // Добавь
      setState(() {
        _isLoadingDepartments = false;
        _departmentsError = 'Ошибка загрузки подразделений: $e';
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Пароли не совпадают';
      });
      return;
    }

    if (_selectedDepartmentId == null) {
      setState(() {
        _errorMessage = 'Выберите подразделение';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final login = _loginController.text.trim();
    final lastName = _lastNameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final patronymic = _patronymicController.text.trim();
    final password = _passwordController.text;
    final occupation = _occupationController.text.trim();

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final keyPair = await CryptoService.generateKeyPair();
      final publicKey = keyPair['publicKey']!;
      final keyAlias = keyPair['keyAlias']!;

      final result = await apiService.register(
        login: login,
        lastName: lastName,
        firstName: firstName,
        patronymic: patronymic,
        password: password,
        publicKey: publicKey,
        occupation: occupation,
        departmentId: _selectedDepartmentId,
      );

      if (!mounted) return;

      if (result['success']) {
        await CryptoService.saveUserKeys(
          login: login,
          keyAlias: keyAlias,
          publicKey: publicKey,
        );

        setState(() {
          _showApprovalMessage = true;
        });
      } else {
        setState(() {
          _errorMessage = result['error'];
        });
        CryptoService.deleteAllKeys().ignore();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка: $e';
        });
      }
      CryptoService.deleteAllKeys().ignore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateLogin(String? value) {
    if (value == null || value.isEmpty) return 'Введите логин';
    if (value.length < 3) return 'Логин должен быть не менее 3 символов';
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) return 'Введите фамилию';
    return null;
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) return 'Введите имя';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < 6) return 'Пароль должен быть не менее 6 символов';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Подтвердите пароль';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return RegisterUI(
      formKey: _formKey,
      loginController: _loginController,
      lastNameController: _lastNameController,
      firstNameController: _firstNameController,
      patronymicController: _patronymicController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      occupationController: _occupationController,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      showApprovalMessage: _showApprovalMessage,
      onSwitchToLogin: widget.onSwitchToLogin,
      onRegister: _register,
      validateLogin: _validateLogin,
      validateLastName: _validateLastName,
      validateFirstName: _validateFirstName,
      validatePassword: _validatePassword,
      validateConfirmPassword: _validateConfirmPassword,
      // Новые параметры
      departments: _departments,
      isLoadingDepartments: _isLoadingDepartments,
      selectedDepartmentId: _selectedDepartmentId,
      departmentsError: _departmentsError,
      onDepartmentChanged: (value) {
        setState(() {
          _selectedDepartmentId = value;
        });
      },
      onRetryLoadDepartments: _loadDepartments,
    );
  }
}
