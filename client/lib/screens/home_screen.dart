import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../services/secure_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebSocketService _wsService = WebSocketService();
  final SecureStorageService _storage = SecureStorageService();
  final TextEditingController _messageController = TextEditingController();
  String _userId = '';
  List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndConnect();
    _setupListeners();
  }

  Future<void> _loadUserAndConnect() async {
    _userId = await _storage.read(key: 'userId') ?? 'unknown';
    await _wsService.connect();
  }

  void _setupListeners() {
    _wsService.addMessageListener((message) {
      setState(() {
        _messages.insert(0, '📨 $message');
      });
    });

    _wsService.addStatusListener((status) {
      setState(() {});
      if (status == ConnectionStatus.disconnected) {
        // Попробовать переподключиться через 3 секунды
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          _wsService.connect();
        });
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _wsService.sendMessage(text);
      setState(() {
        _messages.insert(0, '📤 $text');
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('PixelChat'),
        backgroundColor: Colors.black,
        actions: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  _wsService.status == ConnectionStatus.connected
                      ? Icons.circle
                      : Icons.circle_outlined,
                  color: _wsService.status == ConnectionStatus.connected
                      ? Colors.green
                      : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  _wsService.status == ConnectionStatus.connected
                      ? 'Online'
                      : _wsService.status == ConnectionStatus.connecting
                      ? 'Connecting...'
                      : 'Offline',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _messages[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _messageController.dispose();
    super.dispose();
  }
}
