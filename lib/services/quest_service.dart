import 'package:sqflite/sqflite.dart';

import '../models/exercise.dart';
import '../models/profile.dart';
import 'local_database.dart';

/// Local data access for one Hunter. Same shape the UI used with Supabase,
/// backed only by the on-device SQLite file.
class QuestService {
  final String hunterId;
  QuestService(this.hunterId);

  LocalDatabase get _db => LocalDatabase.instance;

  Future<Profile> fetchProfile() async {
    final rows = await _db.db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [hunterId],
      limit: 1,
    );
    if (rows.isEmpty) {
      await _ensureHunterRow();
      final now = DateTime.now().toIso8601String();
      await _db.db.insert('profiles', {
        'id': hunterId,
        'display_name': 'Hunter',
        'total_days': 0,
        'streak': 0,
        'pending_penalty': 0,
        'missed_days': 0,
        'reminder_hour': 8,
        'reminder_minute': 0,
        'onboarded': 0,
        'grace_used': 0,
        'created_at': now,
        'updated_at': now,
      });
      return fetchProfile();
    }
    return Profile.fromMap(rows.first);
  }

  Future<void> _ensureHunterRow() async {
    if (await _db.hunterExists(hunterId)) return;
    final now = DateTime.now().toIso8601String();
    await _db.db.insert('hunters', {
      'id': hunterId,
      'name': 'Hunter',
      'created_at': now,
    });
  }

  Future<void> saveProfile(Profile p) async {
    final map = p.toUpdateMap();
    map['pending_penalty'] = p.pendingPenalty ? 1 : 0;
    map['onboarded'] = p.onboarded ? 1 : 0;
    map['grace_used'] = p.graceUsed ? 1 : 0;
    await _db.db.update(
      'profiles',
      map,
      where: 'id = ?',
      whereArgs: [p.id],
    );
    await _db.db.update(
      'hunters',
      {'name': p.displayName},
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<List<Exercise>> fetchExercises() async {
    final rows = await _db.db.query(
      'exercises',
      where: 'user_id = ? AND active = 1',
      whereArgs: [hunterId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(Exercise.fromMap).toList();
  }

  Future<Exercise> addExercise(Exercise e) async {
    final id = _db.newId();
    final now = DateTime.now().toIso8601String();
    final row = {
      'id': id,
      'user_id': hunterId,
      'name': e.name,
      'icon': e.icon,
      'kind': e.kind == ExerciseKind.time ? 'time' : 'reps',
      'target': e.target,
      'for_date': e.forDate?.toIso8601String().substring(0, 10),
      'active': e.active ? 1 : 0,
      'sort_order': e.sortOrder,
      'created_at': now,
    };
    await _db.db.insert('exercises', row);
    return Exercise.fromMap(row);
  }

  Future<void> deleteExercise(String id) async {
    await _db.db.update(
      'exercises',
      {'active': 0},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, hunterId],
    );
  }

  Future<Map<String, bool>> fetchChecks(String day) async {
    final rows = await _db.db.query(
      'daily_state',
      columns: ['checks'],
      where: 'user_id = ? AND day = ?',
      whereArgs: [hunterId, day],
      limit: 1,
    );
    if (rows.isEmpty) return {};
    return decodeChecks(rows.first['checks']);
  }

  Future<bool> isDayCompleted(String day) async {
    final rows = await _db.db.query(
      'daily_state',
      columns: ['completed'],
      where: 'user_id = ? AND day = ?',
      whereArgs: [hunterId, day],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['completed'] == 1 || rows.first['completed'] == true;
  }

  Future<void> saveChecks(String day, Map<String, bool> checks,
      {bool completed = false}) async {
    await _db.db.insert(
      'daily_state',
      {
        'user_id': hunterId,
        'day': day,
        'checks': encodeChecks(checks),
        'completed': completed ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Set<String>> fetchHistory({int lastDays = 60}) async {
    final from = DateTime.now()
        .subtract(Duration(days: lastDays))
        .toIso8601String()
        .substring(0, 10);
    final rows = await _db.db.query(
      'quest_history',
      columns: ['day'],
      where: 'user_id = ? AND day >= ?',
      whereArgs: [hunterId, from],
    );
    return rows.map((m) => m['day'].toString()).toSet();
  }

  Future<void> addHistory(String day) async {
    await _db.db.insert(
      'quest_history',
      {'user_id': hunterId, 'day': day},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Set<String>> fetchPenalties({int lastDays = 60}) async {
    final from = DateTime.now()
        .subtract(Duration(days: lastDays))
        .toIso8601String()
        .substring(0, 10);
    final rows = await _db.db.query(
      'penalties',
      columns: ['day'],
      where: 'user_id = ? AND day >= ?',
      whereArgs: [hunterId, from],
    );
    return rows.map((m) => m['day'].toString()).toSet();
  }

  Future<void> addPenalty(String day, int amount) async {
    await _db.db.insert(
      'penalties',
      {'user_id': hunterId, 'day': day, 'amount': amount},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
