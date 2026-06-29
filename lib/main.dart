import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/caregiver_setup_screen.dart';
import 'features/security/security_screen.dart';
import 'data/local/user_preferences_repository.dart';
import 'core/workers/work_manager_helper.dart';
import 'core/notifications/security_notification_manager.dart';
import 'debug/api_test_screen.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  developer.log('App main started', name: 'SnehSaathi');
  WidgetsFlutterBinding.ensureInitialized();
  developer.log('WidgetsBinding initialized', name: 'SnehSaathi');
  
  SharedPreferences? prefs;
  try {
    developer.log('Fetching SharedPreferences', name: 'SnehSaathi');
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    developer.log(
      'SharedPreferences initialization failed',
      name: 'SnehSaathi',
      error: e,
    );
  }

  final bool onboardingComplete = prefs?.getBool('onboarding_complete') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MyApp(onboardingComplete: onboardingComplete),
    ),
  );

  // Background Initializations (Don't block the UI)
  _initBackgroundServices(prefs);
}

Future<void> _initBackgroundServices(SharedPreferences? prefs) async {
  try {
    developer.log('Initializing WorkManager', name: 'SnehSaathi');
    await WorkManagerHelper.initialize();
    await WorkManagerHelper.scheduleGhostwriterWorker();
    await WorkManagerHelper.scheduleMedicationWorker();
    
    developer.log('Initializing notifications', name: 'SnehSaathi');
    await SecurityNotificationManager.initialize(onSecurityTap: () {
      appNavigatorKey.currentState?.pushNamed('/security');
    });
    
    if (prefs != null) {
      final secHour = prefs.getInt('securityReminderHour') ?? 21;
      final secMin = prefs.getInt('securityReminderMinute') ?? 0;
      developer.log(
        'Scheduling security reminder at $secHour:$secMin',
        name: 'SnehSaathi',
      );
      await SecurityNotificationManager.scheduleDailySecurityReminder(TimeOfDay(hour: secHour, minute: secMin));
    }
    developer.log(
      'Background services initialized successfully',
      name: 'SnehSaathi',
    );
  } catch (e, stack) {
    developer.log(
      'Background service initialization failed',
      name: 'SnehSaathi',
      error: e,
      stackTrace: stack,
    );
  }
}

class MyApp extends StatelessWidget {
  final bool onboardingComplete;
  const MyApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sneh Saathi',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: AppTheme.lightTheme,
      routes: {
        '/security': (_) => const SecurityScreen(),
        '/__api_test': (_) => const ApiTestScreen(),
      },
      home: onboardingComplete ? const HomeScreen() : const CaregiverSetupScreen(),
    );
  }
}
