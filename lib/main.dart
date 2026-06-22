import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'data/local/user_preferences_repository.dart';
import 'core/workers/work_manager_helper.dart';
import 'core/notifications/security_notification_manager.dart';

void main() async {
  print("DEBUG: App Main Started");
  WidgetsFlutterBinding.ensureInitialized();
  print("DEBUG: WidgetsBinding Initialized");
  
  SharedPreferences? prefs;
  try {
    print("DEBUG: Fetching SharedPreferences...");
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    print("DEBUG: SharedPreferences Error: $e");
  }

  runApp(
    ProviderScope(
      overrides: [
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );

  // Background Initializations (Don't block the UI)
  _initBackgroundServices(prefs);
}

Future<void> _initBackgroundServices(SharedPreferences? prefs) async {
  try {
    print("DEBUG: Initializing WorkManager...");
    await WorkManagerHelper.initialize();
    await WorkManagerHelper.scheduleGhostwriterWorker();
    await WorkManagerHelper.scheduleMedicationWorker();
    
    print("DEBUG: Initializing Notifications...");
    await SecurityNotificationManager.initialize();
    
    if (prefs != null) {
      final secHour = prefs.getInt('securityReminderHour') ?? 21;
      final secMin = prefs.getInt('securityReminderMinute') ?? 0;
      print("DEBUG: Scheduling Security Reminder at $secHour:$secMin");
      await SecurityNotificationManager.scheduleDailySecurityReminder(TimeOfDay(hour: secHour, minute: secMin));
    }
    print("DEBUG: Background Services Initialized Successfully");
  } catch (e, stack) {
    print("DEBUG: Background Init Error: $e");
    print(stack);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sneh Saathi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
