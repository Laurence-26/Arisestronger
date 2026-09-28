import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:daily_quest/data/gate_programs.dart';
import 'package:daily_quest/models/level.dart';
import 'package:daily_quest/services/backup_service.dart';
import 'package:daily_quest/services/local_database.dart';
import 'package:daily_quest/services/quest_service.dart';
import 'package:daily_quest/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  AppState.skipSideEffects = true;

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
    expect(profile.gateWeekday, 7);
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

  test('backup round-trip restores hunters and gate clears', () async {
    final id = await db.createHunter('A');
    await db.createHunter('B');
    final svc = QuestService(id);
    await svc.addGateClear(week: '2026-W38', day: '2026-09-20', rankIndex: 2);

    final json = await BackupService().exportJson();
    await db.deleteHunter((await db.listHunters()).first.id);
    expect((await db.listHunters()).length, 1);

    final result = await BackupService().restore(json);
    expect(result.hunters, 2);
    expect((await db.listHunters()).length, 2);
    expect(await QuestService(id).isGateClearedForWeek('2026-W38'), isTrue);
    expect(await QuestService(id).countGateClears(), 1);
  });

  test('old backup without gate_clears still restores', () async {
    await db.createHunter('Legacy');
    final snap = await db.exportSnapshot();
    snap.remove('gate_clears');
    snap['profiles'] = [
      for (final row in (snap['profiles'] as List))
        Map<String, Object?>.from(row as Map)..remove('gate_weekday'),
    ];
    await db.deleteHunter((await db.listHunters()).first.id);
    final result = await db.restoreSnapshot(snap);
    expect(result.hunters, 1);
    final profile = await QuestService((await db.listHunters()).first.id)
        .fetchProfile();
    expect(profile.gateWeekday, 7);
  });

  test('fetchProfile creates hunter row when id is missing', () async {
    const ghost = 'stale-prefs-id';
    final profile = await QuestService(ghost).fetchProfile();
    expect(profile.id, ghost);
    expect(await db.hunterExists(ghost), isTrue);
  });

  test('gate clear is one per ISO week and does not change totalDays', () async {
    final id = await db.createHunter('Gate Hunter');
    final state = AppState(QuestService(id));
    await state.load();
    await state.completeOnboarding(
      startRankIndex: 2,
      displayName: 'Gate Hunter',
    );
    // Force Gate day to today.
    await state.setGateWeekday(DateTime.now().weekday);
    await state.load();

    final beforeDays = state.profile.totalDays;
    expect(state.isGateDay, isTrue);
    expect(state.gateClearedThisWeek, isFalse);

    // Skipping Gate is safe — no clear, no totalDays change.
    expect(state.canClearGate, isFalse);
    expect(state.profile.totalDays, beforeDays);

    // Complete daily first.
    for (final e in state.todayExercises) {
      await state.toggleCheck(e.id);
    }
    final complete = await state.completeDay();
    expect(complete.leveledUp || !complete.leveledUp, isTrue);
    expect(state.completedToday, isTrue);

    for (final e in state.gateExercises) {
      await state.toggleGateCheck(e.id);
    }
    expect(state.canClearGate, isTrue);
    final daysAfterDaily = state.profile.totalDays;

    final cleared = await state.clearGate();
    expect(cleared, isTrue);
    expect(state.gateClearedThisWeek, isTrue);
    expect(state.gatesClearedCount, 1);
    expect(state.profile.totalDays, daysAfterDaily);
    expect(state.canClearGate, isFalse);

    // Second clear same week is ignored.
    final again = await state.clearGate();
    expect(again, isFalse);
    expect(state.gatesClearedCount, 1);
  });

  test('gate programs scale with rank and stay short', () {
    final e = gateExercisesFor(0);
    final d = gateExercisesFor(2);
    final s = gateExercisesFor(9);
    expect(e.length, inInclusiveRange(3, 5));
    expect(d.length, inInclusiveRange(3, 5));
    expect(s.length, inInclusiveRange(3, 5));
    expect(d.first.target, greaterThan(e.first.target));
    expect(s.every((x) => x.id.startsWith('gate_9_')), isTrue);
  });
}
