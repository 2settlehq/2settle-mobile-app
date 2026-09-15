import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum PinVerifyStatus { success, incorrect, lockedOut, notSet }

class PinVerifyResult {
  const PinVerifyResult(
    this.status, {
    this.remainingAttempts,
    this.lockoutSeconds,
  });

  final PinVerifyStatus status;
  final int? remainingAttempts;
  final int? lockoutSeconds;

  bool get isSuccess => status == PinVerifyStatus.success;
}

/// Local device-unlock PIN, stored as a salted PBKDF2 hash in Keystore/
/// Keychain-backed secure storage rather than as a raw digit string in
/// SharedPreferences. Also enforces attempt lockout since a short numeric
/// PIN has very little brute-force resistance on its own.
class PinService {
  PinService._();

  static const _storage = FlutterSecureStorage();

  static const _hashKey = '2settle_app_passcode_hash';
  static const _saltKey = '2settle_app_passcode_salt';
  static const _lengthKey = '2settle_app_passcode_length';
  static const _attemptsKey = '2settle_app_passcode_attempts';
  static const _lockoutUntilKey = '2settle_app_passcode_lockout_until';

  static const _pbkdf2Iterations = 10000;
  static const _maxAttemptsBeforeLockout = 5;
  static const _baseLockoutSeconds = 30;
  static const _maxLockoutSeconds = 300;

  static Future<bool> hasPin() async {
    final hash = await _storage.read(key: _hashKey);
    return hash != null && hash.isNotEmpty;
  }

  static Future<int> getPinLength() async {
    final raw = await _storage.read(key: _lengthKey);
    return int.tryParse(raw ?? '') ?? 6;
  }

  /// Persists a chosen length even before a PIN of that length is set, so
  /// the Set/Change Passcode screen can default to the user's last choice.
  static Future<void> setPreferredPinLength(int length) async {
    await _storage.write(key: _lengthKey, value: length.toString());
  }

  static Future<void> setPin(String pin) async {
    final salt = _randomBytes(16);
    final hash = _deriveHash(pin, salt);
    await _storage.write(key: _hashKey, value: base64Encode(hash));
    await _storage.write(key: _saltKey, value: base64Encode(salt));
    await _storage.write(key: _lengthKey, value: pin.length.toString());
    await _storage.delete(key: _attemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  static Future<PinVerifyResult> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _hashKey);
    final storedSalt = await _storage.read(key: _saltKey);
    if (storedHash == null || storedSalt == null) {
      return const PinVerifyResult(PinVerifyStatus.notSet);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final lockoutUntil =
        int.tryParse(await _storage.read(key: _lockoutUntilKey) ?? '') ?? 0;
    if (lockoutUntil > now) {
      return PinVerifyResult(
        PinVerifyStatus.lockedOut,
        lockoutSeconds: ((lockoutUntil - now) / 1000).ceil(),
      );
    }

    final candidateHash =
        base64Encode(_deriveHash(pin, base64Decode(storedSalt)));
    if (_constantTimeEquals(candidateHash, storedHash)) {
      await _storage.delete(key: _attemptsKey);
      await _storage.delete(key: _lockoutUntilKey);
      return const PinVerifyResult(PinVerifyStatus.success);
    }

    final attempts =
        (int.tryParse(await _storage.read(key: _attemptsKey) ?? '') ?? 0) + 1;
    await _storage.write(key: _attemptsKey, value: attempts.toString());

    if (attempts >= _maxAttemptsBeforeLockout) {
      final overflow = attempts - _maxAttemptsBeforeLockout;
      final lockoutSeconds =
          min(_baseLockoutSeconds * (1 << overflow), _maxLockoutSeconds);
      await _storage.write(
        key: _lockoutUntilKey,
        value: (now + lockoutSeconds * 1000).toString(),
      );
      return PinVerifyResult(
        PinVerifyStatus.lockedOut,
        lockoutSeconds: lockoutSeconds,
      );
    }

    return PinVerifyResult(
      PinVerifyStatus.incorrect,
      remainingAttempts: _maxAttemptsBeforeLockout - attempts,
    );
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _lengthKey);
    await _storage.delete(key: _attemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  // PBKDF2-HMAC-SHA256. A single block is sufficient since the 32-byte
  // derived-key length matches SHA-256's output size.
  static Uint8List _deriveHash(String pin, Uint8List salt) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < _pbkdf2Iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return Uint8List.fromList(result);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
