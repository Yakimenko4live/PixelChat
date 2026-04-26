import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/websocket_service.dart';
import 'chat_list_screen_ui.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  WebSocketService? _webSocketService;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectWebSocket();
    });
  }

  @override
  void dispose() {
    _webSocketService?.disconnect();
    super.dispose();
  }

  Future<void> _connectWebSocket() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final webSocketService =
        Provider.of<WebSocketService>(context, listen: false);

    _webSocketService = webSocketService;

    final token = authService.token;
    if (token != null) {
      await webSocketService.connect(token);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _webSocketService?.disconnect();
      await authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  String? get userLogin {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.currentUserLogin;
  }

  @override
  Widget build(BuildContext context) {
    final webSocketService = Provider.of<WebSocketService>(context);

    return ChatListScreenUI(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      userLogin: userLogin,
      connectionQuality: webSocketService.quality,
      isConnected: webSocketService.isConnected,
      onRefresh: _loadData,
      onLogout: _logout,
    );
  }
}
