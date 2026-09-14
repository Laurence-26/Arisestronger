import 'package:flutter/foundation.dart';

import '../data/quotes.dart';
import '../data/rank_programs.dart';
import '../models/exercise.dart';
import '../models/level.dart';
import '../models/profile.dart';
import '../services/notification_service.dart';
import '../services/quest_service.dart';

String _dayKey(DateTime d) => d.toIso8601String().substring(0, 10);
DateTime _todayDate() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

int _daysBetween(DateTime a, DateTime b) {
  final da = DateTime(a.year, a.month, a.day);
  final db = DateTime(b.year, b.month, b.day);
  return db.difference(da).inDays;
}

/// Result of completing a day, so the UI can fire the right celebration.
class CompleteResult {
  final bool leveledUp;
  final int newLevelIndex;
  const CompleteResult(this.leveledUp, this.newLevelIndex);
}

class AppState extends ChangeNotifier {
  final QuestService _svc;
  AppState(this._svc);

  bool loading = true;
  String? error;

  /// Set when the one-time "first miss" grace was just spent, so the UI can
  /// show a warning. Transient (not persisted); cleared once acknowledged.
  bool pendingMissWarning = false;

  late Profile profile;
  List<Exercise> _exercises = [];
  Map<String, bool> _checks = {};
  Set<String> _history = {};
  Set<String> _penalties = {};
  bool _completedToday = false;

  String get todayKey => _dayKey(_todayDate());

  // ---------------- DERIVED ----------------
  Level get level => kLevels[levelIndexOf(profile.totalDays)];
  int get levelIndex => levelIndexOf(profile.totalDays);
  int get daysIntoLevel => daysIntoLevelFor(profile.totalDays);
  int get daysToNextLevel => daysToNextLevelFor(profile.totalDays);
  double get levelProgress => levelProgressFor(profile.totalDays);

  Quote get todayQuote => quoteForDay(_todayDate());

  /// The System-prescribed exercises for the Hunter's current rank.
  List<Exercise> get rankProgram => rankExercises(levelIndex);

  /// Today's full quest = rank program + user's custom exercises + one-off
  /// extras planned for today (e.g. "tomorrow's extra workout").
  List<Exercise> get todayExercises {
    final tk = todayKey;
    final custom = _exercises.where((e) => e.forDate == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final extras = _exercises
        .where((e) => e.forDate != null && _dayKey(e.forDate!) == tk)
        .toList();
    return [...rankProgram, ...custom, ...extras];
  }

  /// The user's own custom permanent exercises (for the Program screen).
  List<Exercise> get customExercises =>
      _exercises.where((e) => e.forDate == null).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// One-off exercises planned for a future date (tomorrow's extra workout).
  List<Exercise> tomorrowExtras() {
    final tk = _dayKey(_todayDate().add(const Duration(days: 1)));
    return _exercises
        .where((e) => e.forDate != null && _dayKey(e.forDate!) == tk)
        .toList();
  }

  bool isChecked(String exerciseId) => _checks[exerciseId] == true;

  bool get allCheckedToday {
    final list = todayExercises;
    if (list.isEmpty) return false;
    return list.every((e) => _checks[e.id] == true);
  }

  bool get completedToday => _completedToday;
  int get checkedCount =>
      todayExercises.where((e) => _checks[e.id] == true).length;
  int get totalCount => todayExercises.length;

  Set<String> get history => _history;
  Set<String> get penalties => _penalties;

  // ---------------- LOAD ----------------
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      profile = await _svc.fetchProfile();
      _exercises = await _svc.fetchExercises();
      _checks = await _svc.fetchChecks(todayKey);
      _completedToday = await _svc.isDayCompleted(todayKey);
      _history = await _svc.fetchHistory();
      _penalties = await _svc.fetchPenalties();

      await _runMissedCheck();
      try {
        await _scheduleReminders();
      } catch (e) {
        debugPrint('Reminder schedule failed: $e');
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _scheduleReminders() async {
    await NotificationService.instance.scheduleDailyReminders(
      hour: profile.reminderHour,
      minute: profile.reminderMinute,
    );
  }

  /// Detect *fully* missed days. A day is only missed when an entire day passed
  /// with no completion — i.e. completing yesterday and opening the app today is
  /// NOT a miss (today is simply your fresh quest). So a miss needs a gap of ≥ 2
  /// days between the last completion and today; missedDays = gap − 1.
  ///
  /// The FIRST missed day ever is forgiven with a warning (no penalty); after
  /// the grace is spent, missed days flag a pending penalty.
  Future<void> _runMissedCheck() async {
    final last = profile.lastDate;
    if (last == null) return;
    final today = _todayDate();
    final gap = _daysBetween(last, today);
    if (gap < 2 || profile.pendingPenalty) return; // gap of 0/1 = nothing missed
    final missed = gap - 1;

    if (!profile.graceUsed) {
      // First miss → warning only. Spend the grace, reset the streak, and move
      // the clock to yesterday so today stays a fresh quest day (and a further
      // miss is still detected tomorrow).
      profile = profile.copyWith(
        graceUsed: true,
        streak: 0,
        lastDate: today.subtract(const Duration(days: 1)),
      );
      pendingMissWarning = true;
      await _svc.saveProfile(profile);
    } else {
      profile = profile.copyWith(
        pendingPenalty: true,
        missedDays: missed,
        streak: 0,
      );
      await _svc.saveProfile(profile);
    }
  }

  void acknowledgeMissWarning() {
    pendingMissWarning = false;
    notifyListeners();
  }

  // ---------------- CHECKS ----------------
  Future<void> toggleCheck(String exerciseId) async {
    if (profile.pendingPenalty || _completedToday) return;
    _checks[exerciseId] = !(_checks[exerciseId] ?? false);
    notifyListeners();
    await _svc.saveChecks(todayKey, _checks);
  }

  // ---------------- COMPLETE DAY ----------------
  Future<CompleteResult> completeDay() async {
    if (profile.pendingPenalty || _completedToday) {
      return CompleteResult(false, levelIndex);
    }
    final today = _todayDate();
    final prevLevel = levelIndexOf(profile.totalDays);

    // Mark every today exercise complete.
    for (final e in todayExercises) {
      _checks[e.id] = true;
    }
    final hadYesterday =
        _history.contains(_dayKey(today.subtract(const Duration(days: 1))));

    profile = profile.copyWith(
      totalDays: profile.totalDays + 1,
      streak: hadYesterday ? profile.streak + 1 : 1,
      lastDate: today,
    );
    _history.add(todayKey);
    _completedToday = true;
    final newLevel = levelIndexOf(profile.totalDays);

    notifyListeners();

    // Persist.
    await _svc.saveChecks(todayKey, _checks, completed: true);
    await _svc.addHistory(todayKey);
    await _svc.saveProfile(profile);
    await _scheduleReminders();

    return CompleteResult(newLevel > prevLevel, newLevel);
  }

  // ---------------- PENALTY ----------------
  Future<int> acceptPenalty() async {
    final missed = profile.missedDays < 1 ? 1 : profile.missedDays;
    final perDay = penaltyPerDayFor(profile.totalDays);
    final newTotal = penalizedTotal(profile.totalDays, missed);
    final amount = profile.totalDays - newTotal;
    final today = _todayDate();

    for (var i = 1; i <= missed; i++) {
      final d = _dayKey(today.subtract(Duration(days: i)));
      _penalties.add(d);
      await _svc.addPenalty(d, perDay);
    }

    profile = profile.copyWith(
      totalDays: newTotal,
      pendingPenalty: false,
      missedDays: 0,
      lastDate: today,
    );
    _checks = {};
    _completedToday = false;
    notifyListeners();

    await _svc.saveProfile(profile);
    await _svc.saveChecks(todayKey, _checks);
    return amount;
  }

  // ---------------- EXERCISE MANAGEMENT ----------------
  Future<void> addExercise({
    required String name,
    required String icon,
    required ExerciseKind kind,
    required int target,
    DateTime? forDate,
  }) async {
    final draft = Exercise(
      id: 'temp',
      name: name.trim(),
      icon: icon,
      kind: kind,
      target: target,
      forDate: forDate,
      active: true,
      sortOrder: _exercises.length,
    );
    final saved = await _svc.addExercise(draft);
    _exercises.add(saved);
    notifyListeners();
  }

  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
    _checks.remove(id);
    notifyListeners();
    await _svc.deleteExercise(id);
  }

  /// Plan one or more extra exercises for tomorrow only.
  Future<void> planTomorrow(List<Exercise> drafts) async {
    final tomorrow = _todayDate().add(const Duration(days: 1));
    for (final d in drafts) {
      final saved = await _svc.addExercise(Exercise(
        id: 'temp',
        name: d.name,
        icon: d.icon,
        kind: d.kind,
        target: d.target,
        forDate: tomorrow,
        active: true,
        sortOrder: _exercises.length,
      ));
      _exercises.add(saved);
    }
    notifyListeners();
  }

  // ---------------- ONBOARDING ----------------
  /// Set the starting rank and mark onboarded.
  Future<void> completeOnboarding({
    required int startRankIndex,
    required String displayName,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final i = startRankIndex.clamp(0, kLevels.length - 1);
    profile = profile.copyWith(
      displayName: displayName.trim().isEmpty ? 'Hunter' : displayName.trim(),
      totalDays: kRankThresholds[i],
      onboarded: true,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
    notifyListeners();
    await _svc.saveProfile(profile);
    await _scheduleReminders();
  }

  // ---------------- SETTINGS ----------------
  Future<void> setReminderTime(int hour, int minute) async {
    profile = profile.copyWith(reminderHour: hour, reminderMinute: minute);
    notifyListeners();
    await _svc.saveProfile(profile);
    await _scheduleReminders();
  }

  // ---------------- NEW DAY ----------------
  /// Called when the calendar day flips while the app is open.
  Future<void> refreshForNewDay() async {
    _checks = await _svc.fetchChecks(todayKey);
    _completedToday = await _svc.isDayCompleted(todayKey);
    await _runMissedCheck();
    notifyListeners();
  }
}
