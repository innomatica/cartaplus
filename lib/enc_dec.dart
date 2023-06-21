import 'package:encrypt/encrypt.dart' as enc;

const keyString = 'G3mm4DzB3/qqlLT07q+KRR9SX4fxfdCBwfn/XjJ5Opw=';

String encrypt(String value) {
  final key = enc.Key.fromBase64(keyString);
  final iv = enc.IV.fromLength(16);
  final encrypter = enc.Encrypter(enc.AES(key));

  return encrypter.encrypt(value, iv: iv).base64;
}

String decrypt(String value) {
  final key = enc.Key.fromBase64(keyString);
  final iv = enc.IV.fromLength(16);
  final encrypter = enc.Encrypter(enc.AES(key));

  return encrypter.decrypt(enc.Encrypted.fromBase64(value), iv: iv);
}
