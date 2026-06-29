import 'package:flutter/services.dart';

/// Native SMS sender using Android's SmsManager via MethodChannel.
/// This sends SMS silently without opening the compose UI — critical for SOS
/// where an elderly user in distress shouldn't have to navigate the SMS app.
///
/// Requires SEND_SMS permission in AndroidManifest.xml.
class NativeSmsSender {
  static const _channel = MethodChannel('com.snehsaathi/sms');

  /// Send an SMS silently via Android's native SmsManager.
  /// Returns true on success, throws PlatformException on failure.
  static Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    try {
      final result = await _channel.invokeMethod('sendSms', {
        'phone': phone,
        'message': message,
      });
      return result == true;
    } catch (e) {
      // Log but don't crash — return false so caller falls back to composer
      // ignore: avoid_print
      print('NativeSmsSender failed: $e');
      return false;
    }
  }
}
