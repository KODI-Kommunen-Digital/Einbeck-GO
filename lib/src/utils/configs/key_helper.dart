import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:encrypt/encrypt.dart';

class KeyHelper {
  static const _storage = FlutterSecureStorage();

  // Store public key
  static Future<void> storePublicKey(String publicKey) async {
    await _storage.write(key: 'publicKey', value: publicKey);
  }

  // Store private key
  static Future<void> storePrivateKey(String privateKey) async {
    await _storage.write(key: 'privateKey', value: privateKey);
  }

  // Retrieve public key
  static Future<RSAPublicKey> getPublicKey() async {
    final publicKeyPem = await _storage.read(key: 'publicKey');
    if (publicKeyPem == null) {
      throw Exception("Public key not found");
    }
    return RsaKeyHelper().parsePublicKeyFromPem(publicKeyPem);
  }

  // Retrieve private key
  static Future<RSAPrivateKey> getPrivateKey() async {
    final privateKeyPem = await _storage.read(key: 'privateKey');
    if (privateKeyPem == null) {
      throw Exception("Private key not found");
    }
    return RsaKeyHelper().parsePrivateKeyFromPem(privateKeyPem);
  }

  // Store forum private key
  static Future<void> storeForumPrivateKey(String forumPrivateKey) async {
    await _storage.write(key: 'forumPrivateKey', value: forumPrivateKey);
  }

  // Retrieve forum private key
  static Future<RSAPrivateKey> getStoredForumPrivateKey() async {
    final privateKeyPem = await _storage.read(key: 'forumPrivateKey');
    if (privateKeyPem == null) {
      throw Exception("Forum private key not found");
    }
    return RsaKeyHelper().parsePrivateKeyFromPem(privateKeyPem);
  }

  // Decrypt AES key using user's private key
  static String decryptAESKey(
      String encryptedAESKey, RSAPrivateKey userPrivateKey) {
    final encrypter = Encrypter(RSA(privateKey: userPrivateKey));
    return encrypter.decrypt(Encrypted.fromBase64(encryptedAESKey));
  }

  // Decrypt forum private key using AES key
  static String decryptForumPrivateKey(
      String encryptedForumPrivateKey, String aesKey) {
    final encrypter = Encrypter(AES(Key.fromUtf8(aesKey)));
    return encrypter.decrypt(Encrypted.fromBase64(encryptedForumPrivateKey),
        iv: IV.fromLength(16));
  }
}
