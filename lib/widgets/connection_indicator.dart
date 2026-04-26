import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class ConnectionIndicator extends StatelessWidget {
  final WebSocketService webSocketService;

  const ConnectionIndicator({super.key, required this.webSocketService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: webSocketService,
      builder: (context, _) {
        final color = _getColor(webSocketService.quality);
        return Tooltip(
          message: _getTooltipMessage(webSocketService.quality),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getColor(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.orange;
      case ConnectionQuality.poor:
        return Colors.red;
      case ConnectionQuality.disconnected:
        return Colors.grey;
    }
  }

  String _getTooltipMessage(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 'Отличное соединение';
      case ConnectionQuality.good:
        return 'Хорошее соединение';
      case ConnectionQuality.poor:
        return 'Плохое соединение';
      case ConnectionQuality.disconnected:
        return 'Нет подключения к серверу';
    }
  }
}
