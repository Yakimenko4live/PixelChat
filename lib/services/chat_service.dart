import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'encryption_service.dart';
import 'crypto_service.dart';
import 'api_service.dart';

class ChatService extends ChangeNotifier {
  final ApiService _apiService;

  ChatService(this._apiService);

  Future<String?> createEncryptedChat(String otherUserId) async {
    try {
      final result = await _apiService.createDirectChat(otherUserId);
      if (!result['success']) {
        throw Exception(result['error']);
      }

      final chatId = result['chat_id'];

      final otherPublicKey = await _apiService.getUserPublicKey(otherUserId);
      if (otherPublicKey == null) {
        throw Exception('Не удалось получить публичный ключ пользователя');
      }

      final sharedSecret =
          await CryptoService.computeSharedSecret(otherPublicKey);
      await CryptoService.saveChatSharedSecret(chatId, sharedSecret);

      return chatId;
    } catch (e) {
      debugPrint('Create encrypted chat error: $e');
      rethrow;
    }
  }

  Future<List<int>> getSharedSecretForChat(String chatId) async {
    final secret = await CryptoService.getChatSharedSecret(chatId);
    if (secret != null) return secret;
    throw Exception('Ключ чата не найден');
  }

  Future<String> encryptMessageForChat(String chatId, String plainText) async {
    final sharedSecret = await getSharedSecretForChat(chatId);
    return EncryptionService.encryptMessage(plainText, sharedSecret);
  }

  Future<String> decryptMessageForChat(
      String chatId, String encryptedMessage) async {
    final sharedSecret = await getSharedSecretForChat(chatId);
    return EncryptionService.decryptMessage(encryptedMessage, sharedSecret);
  }
}
