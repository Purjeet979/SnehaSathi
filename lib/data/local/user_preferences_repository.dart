import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in ProviderScope');
});

final userPreferencesProvider = Provider<UserPreferencesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserPreferencesRepository(prefs);
});

class UserPreferencesRepository {
  final SharedPreferences _prefs;

  UserPreferencesRepository(this._prefs);

  static const String _dadiNameKey = 'dadi_name';
  static const String _voiceSpeedKey = 'voice_speed';
  static const String _fontSizeScaleKey = 'font_size_scale';
  static const String _emergencyContactKey = 'emergency_contact';
  static const String _medRemindersEnabledKey = 'med_reminders';

  String get dadiName => _prefs.getString(_dadiNameKey) ?? 'Dadi';
  double get voiceSpeed => _prefs.getDouble(_voiceSpeedKey) ?? 1.1;
  double get fontSizeScale => _prefs.getDouble(_fontSizeScaleKey) ?? 1.0;
  String? get emergencyContact => _prefs.getString(_emergencyContactKey);
  bool get medRemindersEnabled => _prefs.getBool(_medRemindersEnabledKey) ?? true;

  Future<void> setDadiName(String name) async {
    await _prefs.setString(_dadiNameKey, name);
  }

  Future<void> setVoiceSpeed(double speed) async {
    await _prefs.setDouble(_voiceSpeedKey, speed);
  }

  Future<void> setEmergencyContact(String phone) async {
    await _prefs.setString(_emergencyContactKey, phone);
  }

  Future<void> setMedRemindersEnabled(bool enabled) async {
    await _prefs.setBool(_medRemindersEnabledKey, enabled);
  }
}
