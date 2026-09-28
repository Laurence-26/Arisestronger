import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:daily_quest/models/exercise.dart';
import 'package:daily_quest/models/level.dart';
import 'package:daily_quest/screens/hunter_select_screen.dart';
import 'package:daily_quest/screens/main_shell.dart';
import 'package:daily_quest/services/local_database.dart';
import 'package:daily_quest/services/quest_service.dart';
import 'package:daily_quest/state/app_state.dart';
import 'package:daily_quest/theme.dart';
import 'package:daily_quest/widgets/brand_wordmark.dart';
import 'package:daily_quest/widgets/overlays.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  AppState.skipSideEffects = true;

  testWidgets('capture Play Store assets from real Flutter UI', (tester) async {
    final tmp = await Directory.systemTemp.createTemp('arise_shot_');
    addTearDown(() async {
      await LocalDatabase.instance.close();
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
    await LocalDatabase.instance.close();
    await LocalDatabase.instance.open(path: '${tmp.path}/arise.db');

    Directory('store/screenshots').createSync(recursive: true);
    Directory('store').createSync(recursive: true);

    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final laurenceId = await _seedHunter(
      name: 'Laurence',
      totalDays: kRankThresholds[2] + 3,
      streak: 6,
      reminderHour: 9,
      custom: true,
    );
    await _seedHunter(
      name: 'Sung Jin-Woo',
      totalDays: 4,
      streak: 4,
      reminderHour: 8,
    );

    debugPrint('shot: hunters');
    await tester.pumpWidget(_phone(HunterSelectScreen(onSelected: (_) {})));
    await _settle(tester);
    expect(find.textContaining('SELECT HUNTER'), findsOneWidget);
    await _save(tester, 'store/screenshots/05_hunters.png');

    final awakenId = await _seedHunter(
      name: 'Laurence',
      totalDays: 0,
      streak: 0,
      onboarded: false,
    );

    final state = AppState(QuestService(laurenceId));
    await state.load();
    await state.toggleCheck('sys_2_0');
    await state.toggleCheck('sys_2_1');
    await state.toggleCheck('sys_2_2');

    debugPrint('shot: quest');
    await tester.pumpWidget(_phone(
      ChangeNotifierProvider.value(value: state, child: const MainShell()),
    ));
    await _settle(tester);
    await _save(tester, 'store/screenshots/01_quest.png');

    debugPrint('shot: levelup');
    showLevelUpOverlay(tester.element(find.byType(MainShell)), 2);
    await _settle(tester);
    await _save(tester, 'store/screenshots/02_levelup.png');
    Navigator.of(tester.element(find.byType(MainShell)), rootNavigator: true)
        .pop();
    await _settle(tester);

    debugPrint('shot: profile');
    await tester.pumpWidget(_phone(
      ChangeNotifierProvider.value(
        value: state,
        child: const MainShell(),
      ),
    ));
    await _settle(tester);
    await tester.tap(find.text('PROFILE'));
    await _settle(tester);
    expect(find.textContaining('HUNTER PROFILE'), findsOneWidget);
    expect(find.text('SWITCH HUNTER'), findsOneWidget);
    await _save(tester, 'store/screenshots/07_profile.png');

    debugPrint('shot: program');
    await tester.tap(find.text('PROGRAM'));
    await _settle(tester);
    expect(find.textContaining('TRAINING PROGRAM'), findsOneWidget);
    await _save(tester, 'store/screenshots/03_program.png');

    debugPrint('shot: progress');
    await tester.tap(find.text('PROGRESS'));
    await _settle(tester);
    expect(find.textContaining('HUNTER PROGRESS'), findsOneWidget);
    await _save(tester, 'store/screenshots/04_progress.png');

    debugPrint('shot: penalty');
    await tester.tap(find.text('QUEST'));
    await _settle(tester);
    showPenaltyOverlay(tester.element(find.byType(MainShell)), 2, 17);
    await _settle(tester);
    expect(find.textContaining('PENALTY ZONE'), findsOneWidget);
    expect(find.textContaining('QUEST FAILED'), findsOneWidget);
    await _save(tester, 'store/screenshots/06_penalty.png');
    Navigator.of(tester.element(find.byType(MainShell)), rootNavigator: true)
        .pop();
    await _settle(tester);

    debugPrint('shot: awaken');
    final awaken = AppState(QuestService(awakenId));
    await awaken.load();
    await tester.pumpWidget(_phone(
      ChangeNotifierProvider.value(value: awaken, child: const MainShell()),
    ));
    await _settle(tester);
    final dChip = find.text('D');
    if (dChip.evaluate().isNotEmpty) {
      await tester.ensureVisible(dChip.first);
      await tester.tap(dChip.first);
      await _settle(tester);
    }
    await _save(tester, 'store/screenshots/08_awaken.png');

    debugPrint('shot: feature graphic');
    await tester.binding.setSurfaceSize(const Size(1024, 500));
    await tester.pumpWidget(_featureGraphic());
    await _settle(tester);
    await _save(tester, 'store/feature_graphic.png');

    debugPrint('shots done');
  }, timeout: const Timeout(Duration(minutes: 8)));
}

Future<String> _seedHunter({
  required String name,
  required int totalDays,
  required int streak,
  int reminderHour = 9,
  bool onboarded = true,
  bool custom = false,
}) async {
  final id = await LocalDatabase.instance.createHunter(name);
  final svc = QuestService(id);
  var profile = await svc.fetchProfile();
  final today = DateTime.now();
  profile = profile.copyWith(
    displayName: name,
    totalDays: totalDays,
    streak: streak,
    lastDate: DateTime(today.year, today.month, today.day),
    reminderHour: reminderHour,
    reminderMinute: 0,
    onboarded: onboarded,
  );
  await svc.saveProfile(profile);

  if (onboarded) {
    for (var i = 1; i <= 14; i++) {
      final d = today.subtract(Duration(days: i));
      final key = d.toIso8601String().substring(0, 10);
      if (i == 5) {
        await svc.addPenalty(key, 3);
      } else {
        await svc.addHistory(key);
      }
    }
  }
  if (custom) {
    await svc.addExercise(const Exercise(
      id: 'temp',
      name: 'Diamond Push-ups',
      icon: '💎',
      kind: ExerciseKind.reps,
      target: 15,
      forDate: null,
      active: true,
      sortOrder: 10,
    ));
  }
  return id;
}

Widget _phone(Widget home) {
  return RepaintBoundary(
    key: const ValueKey('shot'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(1080, 1920),
          devicePixelRatio: 1,
          alwaysUse24HourFormat: true,
          textScaler: TextScaler.noScaling,
          padding: EdgeInsets.only(top: 36, bottom: 24),
        ),
        child: ColoredBox(color: AppColors.bg, child: home),
      ),
    ),
  );
}

Widget _featureGraphic() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: RepaintBoundary(
      key: const ValueKey('shot'),
      child: ColoredBox(
        color: AppColors.bg,
        child: SizedBox(
          width: 1024,
          height: 500,
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -60,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.purple.withValues(alpha: 0.28),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 56, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BrandWordmark(size: 54, center: false),
                          const SizedBox(height: 18),
                          Container(
                            width: 120,
                            height: 2,
                            color: AppColors.gold.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'OFFLINE DAILY FITNESS QUESTS',
                            style: monoStyle(
                                size: 16,
                                color: AppColors.textBright,
                                spacing: 2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'RANK UP FROM E TO S',
                            style: monoStyle(
                                size: 16, color: AppColors.purple, spacing: 2),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/icon/icon.png',
                      width: 220,
                      height: 220,
                      filterQuality: FilterQuality.high,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Future<void> _save(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot')),
  );
  await Future<void>.delayed(const Duration(milliseconds: 100));
  final image = await boundary.toImage(pixelRatio: 1.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
  debugPrint('wrote $path');
}
