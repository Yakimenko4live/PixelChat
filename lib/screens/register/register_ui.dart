import 'package:flutter/material.dart';

class RegisterUI extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController loginController;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController patronymicController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController occupationController;
  final bool isLoading;
  final String? errorMessage;
  final bool showApprovalMessage;
  final VoidCallback onSwitchToLogin;
  final VoidCallback onRegister;
  final String? Function(String?) validateLogin;
  final String? Function(String?) validateLastName;
  final String? Function(String?) validateFirstName;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirmPassword;

  // Новые параметры для подразделений
  final List<Map<String, dynamic>> departments;
  final bool isLoadingDepartments;
  final String? selectedDepartmentId;
  final String? departmentsError;
  final void Function(String?) onDepartmentChanged;
  final VoidCallback onRetryLoadDepartments;

  const RegisterUI({
    super.key,
    required this.formKey,
    required this.loginController,
    required this.lastNameController,
    required this.firstNameController,
    required this.patronymicController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.occupationController,
    required this.isLoading,
    required this.errorMessage,
    required this.showApprovalMessage,
    required this.onSwitchToLogin,
    required this.onRegister,
    required this.validateLogin,
    required this.validateLastName,
    required this.validateFirstName,
    required this.validatePassword,
    required this.validateConfirmPassword,
    required this.departments,
    required this.isLoadingDepartments,
    required this.selectedDepartmentId,
    required this.departmentsError,
    required this.onDepartmentChanged,
    required this.onRetryLoadDepartments,
  });

  @override
  Widget build(BuildContext context) {
    if (showApprovalMessage) {
      return _buildApprovalScreen();
    }
    return _buildRegisterForm();
  }

  Widget _buildApprovalScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pending_actions, size: 80, color: Colors.orange),
            const SizedBox(height: 32),
            const Text(
              'Регистрация успешна!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ваш аккаунт будет активирован после подтверждения администратором.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text(
              'Ожидайте уведомление о подтверждении.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: onSwitchToLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Понятно'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.chat, size: 80, color: Colors.blue),
            const SizedBox(height: 32),
            const Text(
              'Регистрация',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Логин
            TextFormField(
              controller: loginController,
              decoration: const InputDecoration(
                labelText: 'Логин',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: validateLogin,
            ),
            const SizedBox(height: 16),

            // Фамилия
            TextFormField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Фамилия',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              validator: validateLastName,
            ),
            const SizedBox(height: 16),

            // Имя
            TextFormField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: validateFirstName,
            ),
            const SizedBox(height: 16),

            // Отчество
            TextFormField(
              controller: patronymicController,
              decoration: const InputDecoration(
                labelText: 'Отчество (необязательно)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_add_alt),
              ),
            ),
            const SizedBox(height: 16),

            // Должность
            TextFormField(
              controller: occupationController,
              decoration: const InputDecoration(
                labelText: 'Должность',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 16),

            // Подразделение (Dropdown)
            _buildDepartmentField(),
            const SizedBox(height: 16),

            // Пароль
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              validator: validatePassword,
            ),
            const SizedBox(height: 16),

            // Подтверждение пароля
            TextFormField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Подтвердите пароль',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: validateConfirmPassword,
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: isLoading ? null : onRegister,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Зарегистрироваться'),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: onSwitchToLogin,
              child: const Text('Уже есть аккаунт? Войти'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentField() {
    if (isLoadingDepartments) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (departmentsError != null) {
      return Column(
        children: [
          Text(
            departmentsError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetryLoadDepartments,
            child: const Text('Повторить'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      value: selectedDepartmentId,
      decoration: const InputDecoration(
        labelText: 'Подразделение *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Выберите подразделение'),
        ),
        ...departments.map((dept) {
          final level = dept['level'] as int;
          final indent = '  ' * (level - 1);
          return DropdownMenuItem<String>(
            value: dept['id'] as String,
            child: Text('$indent${dept['name']}'),
          );
        }),
      ],
      onChanged: onDepartmentChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Выберите подразделение';
        }
        return null;
      },
    );
  }
}
