import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:daily_quest/models/level.dart';
import 'package:daily_quest/services/backup_service.dart';
import 'package:daily_quest/services/local_database.dart';
import 'package:daily_quest/services/quest_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tmp;
  late LocalDatabase db;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('arise_test_');
    db = LocalDatabase.instance;
    await db.close();
    await db.open(path: '${tmp.path}/test.db');
  });

  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('create hunter, persist profile, complete a day', () async {
    final id = await db.createHunter('Jin-Woo');
    final svc = QuestService(id);
    var profile = await svc.fetchProfile();
    expect(profile.displayName, 'Jin-Woo');
    expect(profile.onboarded, isFalse);
    expect(levelIndexOf(profile.totalDays), 0);

    profile = profile.copyWith(onboarded: true, totalDays: 1, streak: 1);
    await svc.saveProfile(profile);
    await svc.addHistory('2026-09-14');
    await svc.saveChecks('2026-09-14', {'push': true}, completed: true);

    final loaded = await svc.fetchProfile();
    expect(loaded.onboarded, isTrue);
    expect(loaded.totalDays, 1);
    expect(await svc.isDayCompleted('2026-09-14'), isTrue);
    expect(await svc.fetchHistory(), contains('2026-09-14'));
  });

  test('backup round-trip restores hunters', () async {
    await db.createHunter('A');
    await db.createHunter('B');
    final json = await BackupService().exportJson();
    await db.deleteHunter((await db.listHunters()).first.id);
    expect((await db.listHunters()).length, 1);

    final result = await BackupService().restore(json);
    expect(result.hunters, 2);
    expect((await db.listHunters()).length, 2);
  });

  test('fetchProfile creates hunter row when id is missing', () async {
    const ghost = 'stale-prefs-id';
    final profile = await QuestService(ghost).fetchProfile();
    expect(profile.id, ghost);
    expect(await db.hunterExists(ghost), isTrue);
  });
}
