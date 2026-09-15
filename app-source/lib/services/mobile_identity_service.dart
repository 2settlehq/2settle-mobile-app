import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class MobileIdentityService {
  static const mobileIdKey = '2settle_mobile_id';
  static const phoneKey = '2settle_user_phone';
  static const fallbackPhone = '2348067426882';
  static const loginChannelKey = '2settle_login_channel';
  static const loginIdentifierKey = '2settle_login_identifier';

  static Future<String> getOrCreateMobileId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(mobileIdKey)?.trim();
    if (existing != null &&
        existing.isNotEmpty &&
        RegExp(r'^\d{12,18}$').hasMatch(existing)) {
      return existing;
    }

    final random = Random.secure();
    final mobileId =
        '9${List.generate(14, (_) => random.nextInt(10).toString()).join()}';
    await prefs.setString(mobileIdKey, mobileId);
    return mobileId;
  }

  static Future<void> savePhone(String rawPhone,
      {String dialCode = '+234'}) async {
    final normalized = normalizePhone(rawPhone, dialCode: dialCode);
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(phoneKey, normalized);
  }

  static Future<String> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(phoneKey)?.trim();
    return stored == null || stored.isEmpty ? fallbackPhone : stored;
  }

  /// Remembers which channel/identifier a login OTP was requested for, so
  /// the confirm-code screen knows what to verify against.
  static Future<void> saveLoginIdentifier(String channel, String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(loginChannelKey, channel);
    await prefs.setString(loginIdentifierKey, identifier);
  }

  static Future<({String channel, String identifier})> getLoginIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    final channel = prefs.getString(loginChannelKey);
    final identifier = prefs.getString(loginIdentifierKey);
    if (channel == null || identifier == null || identifier.isEmpty) {
      return (channel: 'phone', identifier: fallbackPhone);
    }
    return (channel: channel, identifier: identifier);
  }

  /// Clears the previous account's phone/login identifier on sign-out.
  /// Deliberately keeps [mobileIdKey] — that's a stable per-device
  /// identifier, not account-identifying data, and losing it would change
  /// the chat/device id gift flows key off of.
  static Future<void> clearIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(phoneKey);
    await prefs.remove(loginChannelKey);
    await prefs.remove(loginIdentifierKey);
  }

  static String normalizePhone(String rawPhone, {String dialCode = '+234'}) {
    var phone = rawPhone.replaceAll(RegExp(r'\D'), '');
    final code = dialCode.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) return '';
    if (phone.startsWith('00')) phone = phone.substring(2);
    if (phone.startsWith(code)) return phone;
    if (phone.startsWith('0') && code.isNotEmpty) {
      return '$code${phone.substring(1)}';
    }
    if (code.isNotEmpty && phone.length <= 11) return '$code$phone';
    return phone;
  }
}
