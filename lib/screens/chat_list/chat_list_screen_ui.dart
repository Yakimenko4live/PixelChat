import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/connection_indicator.dart';
import '../../widgets/organization_browser.dart';
import '../../models/department_tree.dart';

class ChatListScreenUI extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final String? userLogin;
  final ConnectionQuality connectionQuality;
  final bool isConnected;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const ChatListScreenUI({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.userLogin,
    required this.connectionQuality,
    required this.isConnected,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  State<ChatListScreenUI> createState() => _ChatListScreenUIState();
}

class _ChatListScreenUIState extends State<ChatListScreenUI> {
  void _showMenuBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Поиск сотрудников'),
              onTap: () {
                Navigator.pop(context);
                _showOrganizationBrowser();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Профиль'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Профиль будет доступен позже')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOrganizationBrowser() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => FutureBuilder<List<DepartmentTree>>(
        future: apiService.getDepartmentTree(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Dialog(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ошибка загрузки структуры'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              ),
            );
          }

          final departments = snapshot.data ?? [];
          return Dialog(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: OrganizationBrowser(
                departments: departments,
                onClose: () => Navigator.pop(dialogContext),
                onUserTap: (userId) => _startChat(userId, dialogContext),
              ),
            ),
          );
        },
      ),
    );
  }

  void _startChat(String userId, BuildContext dialogContext) async {
    Navigator.pop(dialogContext);

    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = ChatService(apiService);

    try {
      final chatId = await chatService.createEncryptedChat(
          userId, authService.currentUserId!);
      if (mounted) {
        Navigator.pushNamed(context, '/chat', arguments: {
          'chatId': chatId,
          'otherUserId': userId,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания чата: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PixelChat'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: ConnectionIndicator(
                webSocketService: Provider.of<WebSocketService>(context),
              ),
            ),
          ),
          if (widget.userLogin != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  widget.userLogin!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: widget.onLogout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMenuBottomSheet,
        child: const Icon(Icons.menu),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка чатов...'),
          ],
        ),
      );
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (!widget.isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет подключения к серверу',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Проверьте интернет-соединение',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Здесь будут ваши чаты',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Нажмите на кнопку меню и выберите "Поиск сотрудников"',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            'чтобы начать диалог',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
