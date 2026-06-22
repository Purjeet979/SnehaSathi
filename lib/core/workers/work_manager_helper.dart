import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/sarvam_client.dart';
import '../../data/local/database.dart';
import '../../data/repository/memory_repository.dart';
import '../../data/repository/local_embedding_engine.dart';

const String ghostwriterTask = "ghostwriter_task";
const String medicationTask = "medication_task";
const String securityTask = "security_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case ghostwriterTask:
        // Weekly Ghostwriter: Summarize and send WhatsApp
        await _handleGhostwriterTask();
        break;
      case medicationTask:
        // TODO: Implement Medication Reminder
        debugPrint("Executing Medication Reminder Task...");
        break;
      case securityTask:
        // TODO: Implement Security Check Reminder
        debugPrint("Executing Security Task...");
        break;
    }
    return Future.value(true);
  });
}

Future<void> _handleGhostwriterTask() async {
  try {
    final db = AppDatabase();
    final conversations = await db.getAllConversations();
    
    // Filter last 7 days (Simplified logic for now)
    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final recentChat = conversations
        .where((c) => c.timestamp > weekAgo)
        .map((c) => "${c.role}: ${c.content}")
        .join("\n");

    if (recentChat.isEmpty) return;

    final sarvam = SarvamClient();
    final summary = await sarvam.chat([
      {"role": "system", "content": "You are a caring assistant. Summarize these chats between an elderly person and an AI into a short, heart-touching update for their family. Keep it in Hindi/English mix (Hinglish)."},
      {"role": "user", "content": recentChat}
    ]);

    final whatsappUrl = Uri.parse("whatsapp://send?phone=&text=${Uri.encodeComponent(summary)}");
    if (await canLaunchUrl(whatsappUrl)) {
      // Note: This might not work in background on newer Androids without a notification tap, 
      // but it's the logic from the old version.
      await launchUrl(whatsappUrl);
    }
    
    await db.close();
  } catch (e) {
    debugPrint("Ghostwriter Error: $e");
  }
}

class WorkManagerHelper {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> scheduleGhostwriterWorker() async {
    await Workmanager().registerPeriodicTask(
      "ghostwriter_worker",
      ghostwriterTask,
      frequency: const Duration(days: 7),
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
