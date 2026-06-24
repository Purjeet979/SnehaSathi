import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SecurityNotificationManager {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static VoidCallback? _onSecurityTap;

  static Future<void> initialize({VoidCallback? onSecurityTap}) async {
    _onSecurityTap = onSecurityTap;
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Currently we only set up Android. Add iOS here if needed.
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'security') {
          _onSecurityTap?.call();
        }
      },
    );
  }

  static Future<void> scheduleDailySecurityReminder(TimeOfDay time) async {
    await _notificationsPlugin.cancel(id: 0); // Cancel any existing security reminder

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'security_channel',
      'Security Reminders',
      channelDescription: 'Daily reminders for night security checks',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Raat Ki Safety Check',
      body: 'Dadi, kya aapne darwaza aur gas band kar diya hai?',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the exact time
      payload: 'security',
    );
  }

  static Future<void> scheduleOneShotTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'security_channel',
      'Security Reminders',
      channelDescription: 'Daily reminders for night security checks',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notificationsPlugin.zonedSchedule(
      id: 99,
      title: 'SnehSaathi Test Notification',
      body: 'Tap should open the Security screen.',
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'security',
    );
  }
}
