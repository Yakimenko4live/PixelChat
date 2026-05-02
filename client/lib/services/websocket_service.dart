import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'secure_storage_service.dart';

enum ConnectionStatus { connecting, connected, disconnected, error }

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final SecureStorageService _storage = SecureStorageService();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  final List<Function> _messageListeners = [];
  final List<Function(ConnectionStatus)> _statusListeners = [];

  void addMessageListener(Function(dynamic) listener) {
    _messageListeners.add(listener);
  }

  void removeMessageListener(Function(dynamic) listener) {
    _messageListeners.remove(listener);
  }

  void addStatusListener(Function(ConnectionStatus) listener) {
    _statusListeners.add(listener);
  }

  void removeStatusListener(Function(ConnectionStatus) listener) {
    _statusListeners.remove(listener);
  }

  void _setStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    for (var listener in _statusListeners) {
      listener(newStatus);
    }
  }

  Future<void> connect() async {
    if (_channel != null) {
      await disconnect();
    }

    _setStatus(ConnectionStatus.connecting);

    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      _setStatus(ConnectionStatus.error);
      return;
    }

    try {
      final url = 'wss://domenfromdevigor4live.store/ws?token=$token';
      _channel = IOWebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (message) {
          _onMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _setStatus(ConnectionStatus.error);
        },
        onDone: () {
          print('WebSocket closed');
          _setStatus(ConnectionStatus.disconnected);
          _channel = null;
        },
      );

      _setStatus(ConnectionStatus.connected);
      print('WebSocket connected');
    } catch (e) {
      print('WebSocket connection failed: $e');
      _setStatus(ConnectionStatus.error);
      _channel = null;
    }
  }

  void _onMessage(dynamic message) {
    print('Received: $message');
    for (var listener in _messageListeners) {
      listener(message);
    }
  }

  void sendMessage(String message) {
    if (_channel != null && _status == ConnectionStatus.connected) {
      _channel!.sink.add(message);
      print('Sent: $message');
    } else {
      print('Cannot send message: not connected');
    }
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    _setStatus(ConnectionStatus.disconnected);
  }
}
