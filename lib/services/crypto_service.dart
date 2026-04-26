import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';

class CryptoService {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Map<String, String>> generateAndSaveKeyPair() async {
    final keyPair = EncryptionService.generateKeyPair();
    await _storage.write(key: 'private_key', value: keyPair.privateKey);
    await _storage.write(key: 'public_key', value: keyPair.publicKey);
    return keyPair;
  }

  static Future<String?> getPrivateKey() async {
    return await _storage.read(key: 'private_key');
  }

  static Future<String?> getPublicKey() async {
    return await _storage.read(key: 'public_key');
  }

  static Future<void> deleteKeys() async {
    await _storage.delete(key: 'private_key');
    await _storage.delete(key: 'public_key');
  }
}
