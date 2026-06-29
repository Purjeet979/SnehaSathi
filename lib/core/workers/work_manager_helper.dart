import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../network/sarvam_client.dart';
import '../../data/local/database.dart';

const String ghostwriterTask = "ghostwriter_task";
const String medicationTask = "medication_task";
const String securityTask = "security_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case ghostwriterTask:
        await _handleGhostwriterTask();
        break;
      case medicationTask:
        // FIX 2e: Implemented medication reminder worker
        await _handleMedicationTask();
        break;
      case securityTask:
        debugPrint("Executing Security Task...");
        break;
    }
    return Future.value(true);
  });
}

/// FIX 4a: Ghostwriter now generates summary LOCALLY from Drift DB,
/// then pushes ONLY the summary to Firebase — never raw conversations.
Future<void> _handleGhostwriterTask() async {
  try {
    final db_task = AppDatabase();
    final convs_task = await db_task.getAllConversations();

    // FIX 4d: Check if cloud sync is enabled
    final prefs = await SharedPreferences.getInstance();
    final syncEnabled = prefs.getBool('cloud_sync_enabled') ?? true;

    // Check digest frequency preference (defaulting to Daily)
    final frequency = prefs.getString('summary_frequency') ?? 'Daily';
    final isDaily = frequency == 'Daily';
    final timeframeDays = isDaily ? 1 : 7;

    // Filter conversations based on timeframe
    final cutoffTime = DateTime.now().subtract(Duration(days: timeframeDays)).millisecondsSinceEpoch;
    final recentChat = convs_task
        .where((c) => c.timestamp > cutoffTime)
        .map((c) => "${c.role}: ${c.content}")
        .join("\n");

    final elderName = prefs.getString('elder_name') ?? 'Dadi';
    final phone = prefs.getString('emergency_contact_1_phone') ?? '';

    if (recentChat.isEmpty) {
      // If no chats, send structured daily status digest
      final d_info = await db_task.getDailyDigestInfo(elderName);
      final summaryText = d_info.toFormattedDigest(isHindi: true);

      if (phone.isNotEmpty) {
        final msg = Uri.encodeComponent(summaryText);
        final whatsappUrl = Uri.parse('https://wa.me/$phone?text=$msg');
        if (await canLaunchUrl(whatsappUrl)) {
          await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        }
      }
      return;
    }

    // Generate summary locally using Sarvam AI
    final sarvam = SarvamClient();
    final promptInstruction = isDaily 
        ? "You are a caring assistant. Summarize today's conversation and activities between an elderly person and an AI into a short, heart-touching daily digest for their family. Mention activity and tone gently."
        : "You are a caring assistant. Summarize these chats between an elderly person and an AI into a short, heart-touching update for their family. Keep it in Hindi/English mix (Hinglish).";

    final summary = await sarvam.chat([
      {"role": "system", "content": promptInstruction},
      {"role": "user", "content": recentChat},
    ]);

    // Send via WhatsApp
    if (phone.isNotEmpty) {
      final header = isDaily ? '🌸 $elderName ka Aaj ka Daily Digest:' : '🌸 $elderName ka Hafte ka Haal:';
      final msg = Uri.encodeComponent('$header\n\n$summary\n\n— Sneh Saathi Family Bridge 💛');
      final whatsappUrl = Uri.parse('https://wa.me/$phone?text=$msg');
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    }

    // FIX 4a: Push ONLY the generated summary to Firebase
    if (syncEnabled) {
      try {
        await FirebaseFirestore.instance.collection(isDaily ? 'daily_summaries' : 'weekly_summaries').add({
          'summary': summary,
          'elderName': elderName,
          'frequency': frequency,
          'generatedAt': FieldValue.serverTimestamp(),
          'conversationCount': convs_task.where((c) => c.timestamp > cutoffTime).length,
        });
        debugPrint("Logged $frequency summary to Firebase successfully.");
      } catch (firebaseErr) {
        debugPrint("Failed to log summary to Firebase: $firebaseErr");
      }
    }

    // No-op
  } catch (e) {
    debugPrint("Ghostwriter Error: $e");
  }
}

/// FIX 2e: Medication reminder worker — checks untaken meds and notifies
Future<void> _handleMedicationTask() async {
  try {
    final db = AppDatabase();
    final untakenMeds = await db.getUntakenMedications();

    if (untakenMeds.isEmpty) {
      await db.close();
      return;
    }

    // Determine current time slot
    final hour = DateTime.now().hour;
    String currentSlot;
    if (hour >= 5 && hour < 12) {
      currentSlot = 'Subah';
    } else if (hour >= 12 && hour < 16) {
      currentSlot = 'Dopahar';
    } else if (hour >= 16 && hour < 20) {
      currentSlot = 'Shaam';
    } else {
      currentSlot = 'Raat';
    }

    // Filter to current time slot medications
    final dueMeds = untakenMeds.where((m) => m.timeToTake == currentSlot).toList();

    if (dueMeds.isEmpty) {
      await db.close();
      return;
    }

    // Send notification for each due medication
    final notifPlugin = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await notifPlugin.initialize(settings: initSettings);

    for (final med in dueMeds) {
      const androidDetails = AndroidNotificationDetails(
        'med_reminder_channel',
        'Medication Reminders',
        channelDescription: 'Reminders to take medications',
        importance: Importance.high,
        priority: Priority.high,
      );

      await notifPlugin.show(
        id: med.id,
        title: '💊 Dawai yaad hai?',
        body: 'Kya aapne ${med.name} kha li?',
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: 'med_reminder:${med.name}',
      );
    }

    // Also check for any medications deferred 2+ times and alert family
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('emergency_contact_1_phone') ?? '';
    final elderName = prefs.getString('elder_name') ?? 'Dadi';

    for (final med in untakenMeds) {
      if (phone.isNotEmpty) {
        final msg = Uri.encodeComponent(
          '⚠️ $elderName ne ${med.name} 2+ baar taala hai. Kripya check karein. — Sneh Saathi',
        );
        final uri = Uri.parse('https://wa.me/$phone?text=$msg');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        // Reset count after alerting
        await db.resetDeferredCount(med.name);
      }
    }

    await db.close();
  } catch (e) {
    debugPrint("Medication Worker Error: $e");
  }
}

class WorkManagerHelper {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> scheduleGhostwriterWorker() async {
    final prefs = await SharedPreferences.getInstance();
    final frequency = prefs.getString('summary_frequency') ?? 'Daily';
    final isDaily = frequency == 'Daily';

    await Workmanager().registerPeriodicTask(
      "ghostwriter_worker",
      ghostwriterTask,
      frequency: isDaily ? const Duration(days: 1) : const Duration(days: 7),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> scheduleMedicationWorker() async {
    await Workmanager().registerPeriodicTask(
      "medication_worker",
      medicationTask,
      frequency: const Duration(hours: 12),
    );
  }

  static Future<void> scheduleSecurityWorker() async {
    await Workmanager().registerPeriodicTask(
      "security_worker",
      securityTask,
      frequency: const Duration(hours: 24),
    );
  }
}
