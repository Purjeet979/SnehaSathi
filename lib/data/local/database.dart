import 'dart:io';
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
  int get schemaVersion => 1;

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

  // DAOs for HealthLogs
  Future<List<HealthLog>> getAllHealthLogs() => select(healthLogs).get();
  Future<int> addHealthLog(HealthLogsCompanion entry) => into(healthLogs).insert(entry);
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
