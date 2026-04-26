import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../config/app_config.dart';

enum ConnectionQuality { excellent, good, poor, disconnected }

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  ConnectionQuality _quality = ConnectionQuality.disconnected;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  bool _isConnecting = false;
  String? _authToken;

  // Callback для новых сообщений
  Function(Map<String, dynamic>)? onNewMessage;

  ConnectionQuality get quality => _quality;
  bool get isConnected => _quality != ConnectionQuality.disconnected;
  bool get isConnecting => _isConnecting;

  Future<void> connect(String token) async {
    _authToken = token;
    await _connect();
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    if (_authToken == null) return;

    _isConnecting = true;
    // Убираем notifyListeners() здесь

    try {
      final wsUrl = Uri.parse('${AppConfig.wsBaseUrl}/ws?token=$_authToken');
      _channel = IOWebSocketChannel.connect(wsUrl);

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _quality = ConnectionQuality.good;
      _reconnectAttempts = 0;
      _startPing();

      debugPrint('WebSocket connected');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _quality = ConnectionQuality.disconnected;
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
      // Убираем notifyListeners() здесь
    }
  }

  void _handleMessage(dynamic message) {
    // Пропускаем ping/pong
    if (message is String && (message == 'ping' || message == 'pong')) {
      debugPrint('Heartbeat: $message');
      _quality = ConnectionQuality.excellent;
      notifyListeners();
      return;
    }

    debugPrint('Received: $message');

    try {
      final data = jsonDecode(message);
      final type = data['type'];

      if (type == 'new_message' && onNewMessage != null) {
        onNewMessage!(data['data']);
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }

    _quality = ConnectionQuality.excellent;
    notifyListeners();
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _quality = ConnectionQuality.poor;
    notifyListeners();
  }

  void _handleDisconnect() {
    debugPrint('WebSocket disconnected');
    _quality = ConnectionQuality.disconnected;
    notifyListeners();
    _scheduleReconnect();
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null && _quality != ConnectionQuality.disconnected) {
        _sendPing();
      } else {
        timer.cancel();
      }
    });
  }

  void _sendPing() {
    try {
      _channel?.sink.add('ping');
    } catch (e) {
      _quality = ConnectionQuality.poor;
      notifyListeners();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: min(_reconnectAttempts * 2 + 1, 30));

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _connect();
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_quality == ConnectionQuality.disconnected) {
      debugPrint('Cannot send message: not connected');
      return;
    }

    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Send error: $e');
      _quality = ConnectionQuality.poor;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _quality = ConnectionQuality.disconnected;
    _authToken = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
