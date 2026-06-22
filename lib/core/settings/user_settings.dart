import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notifications/security_notification_manager.dart';

class UserSettings {
  final int dayStartHour;
  final TimeOfDay securityReminderTime;

  UserSettings({
    this.dayStartHour = 4,
    this.securityReminderTime = const TimeOfDay(hour: 21, minute: 0),
  });

  UserSettings copyWith({
    int? dayStartHour,
    TimeOfDay? securityReminderTime,
  }) {
    return UserSettings(
      dayStartHour: dayStartHour ?? this.dayStartHour,
      securityReminderTime: securityReminderTime ?? this.securityReminderTime,
    );
  }
}

class UserSettingsNotifier extends Notifier<UserSettings> {
  SharedPreferences? _prefs;

  @override
  UserSettings build() {
    _initPrefs();
    return UserSettings();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final hour = _prefs?.getInt('dayStartHour') ?? 4;
    final secHour = _prefs?.getInt('securityReminderHour') ?? 21;
    final secMin = _prefs?.getInt('securityReminderMinute') ?? 0;
    
    state = UserSettings(
      dayStartHour: hour,
      securityReminderTime: TimeOfDay(hour: secHour, minute: secMin),
    );
  }

  Future<void> updateDayStartHour(int hour) async {
    state = state.copyWith(dayStartHour: hour);
    await _prefs?.setInt('dayStartHour', hour);
  }

  Future<void> updateSecurityReminderTime(TimeOfDay time) async {
    state = state.copyWith(securityReminderTime: time);
    await _prefs?.setInt('securityReminderHour', time.hour);
    await _prefs?.setInt('securityReminderMinute', time.minute);
    
    // Reschedule the exact notification for the new time
    await SecurityNotificationManager.scheduleDailySecurityReminder(time);
  }
}

final userSettingsProvider = NotifierProvider<UserSettingsNotifier, UserSettings>(UserSettingsNotifier.new);
