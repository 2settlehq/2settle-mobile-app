import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class MobileIdentityService {
  static const mobileIdKey = '2settle_mobile_id';
  static const phoneKey = '2settle_user_phone';
  static const fallbackPhone = '2348067426882';

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
