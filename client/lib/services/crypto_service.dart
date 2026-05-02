import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/random/fortuna_random.dart';
// КРИТИЧЕСКИЕ ИМПОРТЫ ДЛЯ РАБОТЫ ГЕНЕРАТОРА
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';

import 'secure_storage_service.dart';

class CryptoService {
  static const String _privateKeyKey = 'private_key';
  static const String _publicKeyKey = 'public_key';
  final _storage = SecureStorageService();

  Future<void> generateAndSaveKeys() async {
    final keyPair = _generateRSAKeyPair();

    await _storage.write(
      key: _privateKeyKey,
      value: _encodePrivateKey(keyPair.privateKey as RSAPrivateKey),
    );
    await _storage.write(
      key: _publicKeyKey,
      value: _encodePublicKey(keyPair.publicKey as RSAPublicKey),
    );
  }

  Future<void> deleteExistingKey() async {
    await _storage.delete(key: _privateKeyKey);
    await _storage.delete(key: _publicKeyKey);
  }

  Future<bool> hasPrivateKey() async {
    return await _storage.containsKey(key: _privateKeyKey);
  }

  Future<String> getPublicKey() async {
    final publicKey = await _storage.read(key: _publicKeyKey);
    if (publicKey != null) return publicKey;

    await generateAndSaveKeys();
    return await _storage.read(key: _publicKeyKey) ?? '';
  }

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRSAKeyPair() {
    final secureRandom = FortunaRandom();

    // Random.secure() работает и в Android, и в iOS PWA (через crypto.getRandomValues)
    final random = Random.secure();
    final seeds = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      seeds[i] = random.nextInt(256);
    }
    secureRandom.seed(KeyParameter(seeds));

    final keyParams = RSAKeyGeneratorParameters(
      BigInt.parse('65537'), // Стандартная экспонента
      2048, // Длина ключа
      64, // Число проверок на простоту
    );

    final parameters = ParametersWithRandom(keyParams, secureRandom);
    final keyGenerator = RSAKeyGenerator();
    keyGenerator.init(parameters);

    final pair = keyGenerator.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  // Твой формат кодирования (modulus,exponent)
  String _encodePublicKey(RSAPublicKey publicKey) {
    return '${publicKey.modulus},${publicKey.exponent}';
  }

  String _encodePrivateKey(RSAPrivateKey privateKey) {
    return '${privateKey.modulus},${privateKey.privateExponent}';
  }
}
