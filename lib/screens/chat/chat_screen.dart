import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';
import '../../services/crypto_service.dart';
import '../../services/websocket_service.dart';
import '../../models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String chatId;
  late String otherUserId;

  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = true;
  late ChatService _chatService;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Provider.of<ApiService>(context, listen: false));
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    chatId = args['chatId'];
    otherUserId = args['otherUserId'];
    _loadMessages();
  }

  Future<void> _loadCurrentUser() async {
    _currentUserId = await CryptoService.getCurrentUserId();
  }

  Future<void> _loadMessages() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final messages = await apiService.getChatMessages(chatId);

    for (var msg in messages) {
      try {
        final decrypted = await _chatService.decryptMessageForChat(
            chatId, msg.encryptedContent);
        msg.decryptedContent = decrypted;
      } catch (e) {
        msg.decryptedContent = '[Зашифрованное сообщение]';
      }
    }

    if (mounted) {
      setState(() {
        _messages.addAll(messages.reversed);
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final encrypted = await _chatService.encryptMessageForChat(chatId, text);

      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.sendMessage(chatId, encrypted);

      if (result['success'] && mounted) {
        final tempMessage = Message(
          id: result['message_id'],
          chatId: chatId,
          senderId: _currentUserId ?? '',
          encryptedContent: encrypted,
          createdAt: DateTime.now(),
          isRead: false,
          decryptedContent: text,
        );
        setState(() {
          _messages.add(tempMessage);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат'),
        actions: [
          Consumer<WebSocketService>(
            builder: (context, ws, _) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  ws.isConnected ? Icons.wifi : Icons.wifi_off,
                  size: 20,
                  color: ws.isConnected ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages.reversed.toList()[index];
                      final isMe = msg.senderId == _currentUserId;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg.decryptedContent ?? msg.encryptedContent,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
