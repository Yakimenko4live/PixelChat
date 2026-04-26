import 'package:flutter/material.dart';
import 'login/login_screen.dart';
import 'register/register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoginMode
            ? LoginScreen(
                onSwitchToRegister: () {
                  setState(() {
                    _isLoginMode = false;
                  });
                },
              )
            : RegisterScreen(
                onSwitchToLogin: () {
                  setState(() {
                    _isLoginMode = true;
                  });
                },
              ),
      ),
    );
  }
}
