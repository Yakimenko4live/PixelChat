import 'package:flutter/material.dart';

class LoginUI extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController loginController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onLogin;
  final VoidCallback onSwitchToRegister;
  final String? Function(String?) validateLogin;
  final String? Function(String?) validatePassword;

  const LoginUI({
    super.key,
    required this.formKey,
    required this.loginController,
    required this.passwordController,
    required this.isLoading,
    required this.errorMessage,
    required this.onLogin,
    required this.onSwitchToRegister,
    required this.validateLogin,
    required this.validatePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat, size: 80, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'PixelChat',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: loginController,
                decoration: const InputDecoration(
                  labelText: 'Логин',
                  border: OutlineInputBorder(),
                ),
                validator: validateLogin,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                ),
                validator: validatePassword,
              ),
              const SizedBox(height: 24),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Войти'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onSwitchToRegister,
                child: const Text('Нет аккаунта? Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
