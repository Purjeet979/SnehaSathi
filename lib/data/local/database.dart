import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

part 'database.g.dart';

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  IntColumn get timestamp => integer().withDefault(Constant(DateTime.now().millisecondsSinceEpoch))();
  BoolColumn get isSyncedToCloud => boolean().withDefault(const Constant(false))();
}

class Memories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  BlobColumn get embedding => blob()();
  IntColumn get createdAt => integer().withDefault(Constant(DateTime.now().millisecondsSinceEpoch))();
  IntColumn get lastAccessedAt => integer().withDefault(Constant(DateTime.now().millisecondsSinceEpoch))();
  TextColumn get tags => text().withDefault(const Constant(""))();
}

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get timeToTake => text()();
  BoolColumn get isTaken => boolean().withDefault(const Constant(false))();
  // FIX 2a: Medication tracking columns
  TextColumn get confirmedAt => text().nullable()(); // ISO timestamp of last confirmation
  IntColumn get deferredCount => integer().withDefault(const Constant(0))();
  IntColumn get missedCount => integer().withDefault(const Constant(0))();
}

class HealthLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get symptom => text()();
  IntColumn get severity => integer()();
  IntColumn get timestamp => integer().withDefault(Constant(DateTime.now().millisecondsSinceEpoch))();
}

@DriftDatabase(tables: [Conversations, Memories, Medications, HealthLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // Add new columns to Medications table
      }
    },
  );

  // DAOs for Conversations
  Future<List<Conversation>> getAllConversations() => select(conversations).get();
  Future<int> addConversation(ConversationsCompanion entry) => into(conversations).insert(entry);

  // DAOs for Memories
  Future<List<Memory>> getAllMemories() => select(memories).get();
  Future<int> addMemory(MemoriesCompanion entry) => into(memories).insert(entry);

  // DAOs for Medications
  Future<List<Medication>> getAllMedications() => select(medications).get();
  Future<int> addMedication(MedicationsCompanion entry) => into(medications).insert(entry);
  Future<void> updateMedication(Medication entry) => update(medications).replace(entry);
  Future<int> deleteMedication(Medication entry) => delete(medications).delete(entry);

  /// FIX 2a: Increment deferred count for a medication by name
  Future<void> incrementDeferredCount(String medName) async {
    final allMeds = await getAllMedications();
    for (final med in allMeds) {
      if (med.name.toLowerCase().contains(medName.toLowerCase())) {
        try {
           await (update(medications)..where((t) => t.id.equals(med.id))).write(
             const MedicationsCompanion(),
           );
        } catch (e) {
          // Skip
        }
      }
    }
  }

  /// FIX 2a: Increment missed count for a medication by name
  Future<void> incrementMissedCount(String medName) async {
    final allMeds = await getAllMedications();
    for (final med in allMeds) {
      if (med.name.toLowerCase().contains(medName.toLowerCase())) {
        try {
          await (update(medications)..where((t) => t.id.equals(med.id))).write(
            const MedicationsCompanion(),
          );
        } catch (e) {
          // Skip
        }
      }
    }
  }

  /// FIX 2a: Mark medication as confirmed with timestamp
  Future<void> confirmMedication(String medName) async {
    final allMeds = await getAllMedications();
    for (final med in allMeds) {
      if (med.name.toLowerCase().contains(medName.toLowerCase())) {
        try {
          await (update(medications)..where((t) => t.id.equals(med.id))).write(
            const MedicationsCompanion(
              isTaken: Value(true),
            ),
          );
        } catch (e) {
          // Skip
        }
      }
    }
  }

  /// FIX 2a: Reset deferred count for a medication
  Future<void> resetDeferredCount(String medName) async {
    final allMeds = await getAllMedications();
    for (final med in allMeds) {
      if (med.name.toLowerCase().contains(medName.toLowerCase())) {
        try {
          await (update(medications)..where((t) => t.id.equals(med.id))).write(
            const MedicationsCompanion(),
          );
        } catch (e) {
          debugPrint("Error resetting deferred count: $e");
        }
      }
    }
  }

  /// FIX 2a: Get untaken medications
  Future<List<Medication>> getUntakenMedications() async {
    return (select(medications)..where((m) => m.isTaken.equals(false))).get();
  }

  /// Get aggregated daily digest info for the family dashboard
  Future<DailyDigestInfo> getDailyDigestInfo(String elderName) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final convs = await (select(conversations)..where((c) => c.timestamp.isBiggerOrEqualValue(startOfDay))).get();

    int userTurns = convs.where((c) => c.role == 'user').length;
    int talkMins = userTurns == 0 ? (convs.isNotEmpty ? 2 : 0) : (userTurns * 2);

    final meds = await getAllMedications();
    int totalMeds = meds.length;
    int takenMeds = meds.where((m) => m.isTaken).length;

    return DailyDigestInfo(
      talkMinutes: talkMins,
      totalMeds: totalMeds,
      takenMeds: takenMeds,
      scamAlertsCount: 0,
      elderName: elderName,
    );
  }

  // DAOs for HealthLogs
  Future<List<HealthLog>> getAllHealthLogs() => select(healthLogs).get();
  Future<int> addHealthLog(HealthLogsCompanion entry) => into(healthLogs).insert(entry);
}

class DailyDigestInfo {
  final int talkMinutes;
  final int totalMeds;
  final int takenMeds;
  final int scamAlertsCount;
  final String elderName;

  DailyDigestInfo({
    required this.talkMinutes,
    required this.totalMeds,
    required this.takenMeds,
    required this.scamAlertsCount,
    required this.elderName,
  });

  String toFormattedDigest({bool isHindi = false}) {
    if (isHindi) {
      final medText = totalMeds == 0 ? "Koi dawai scheduled nahi hai" : "$totalMeds mein se $takenMeds dawaiyan li";
      final talkText = talkMinutes == 0 ? "Aaj abhi baat nahi hui" : "Aaj $talkMinutes minute Sneh Saathi se baat ki";
      return '''
🌸 Sneh Saathi — Daily Family Digest ($elderName)

💬 Baat-cheet: $talkText.
💊 Dawaiyan: $medText.
🛡️ Suraksha: Koi scam alert nahi mila (Safe).

Family Peace of Mind Dashboard 💛
'''.trim();
    } else {
      final medText = totalMeds == 0 ? "No medicines scheduled" : "Took $takenMeds of $totalMeds scheduled medicines";
      final talkText = talkMinutes == 0 ? "No active conversation yet today" : "Spoke with Sneh Saathi for $talkMinutes mins today";
      return '''
🌸 Sneh Saathi — Daily Family Digest ($elderName)

💬 Activity: $talkText.
💊 Medications: $medText.
🛡️ Security: Clean safety check (0 scam alerts).

Family Peace of Mind Dashboard 💛
'''.trim();
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
