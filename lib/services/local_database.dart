import 'dart:convert';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// On-device SQLite store for every Hunter. No network, no cloud.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _db;
  Database get db {
    final d = _db;
    if (d == null) {
      throw StateError('LocalDatabase.open() must run before use.');
    }
    return d;
  }

  Future<void> open({String? path}) async {
    if (_db != null) return;
    final dbPath = path ?? p.join(await getDatabasesPath(), 'arise_stronger.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (d, _) async => _create(d),
      onOpen: (d) async => d.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> _create(Database d) async {
    await d.execute('''
      CREATE TABLE hunters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await d.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        display_name TEXT,
        total_days INTEGER NOT NULL DEFAULT 0,
        streak INTEGER NOT NULL DEFAULT 0,
        last_date TEXT,
        pending_penalty INTEGER NOT NULL DEFAULT 0,
        missed_days INTEGER NOT NULL DEFAULT 0,
        reminder_hour INTEGER NOT NULL DEFAULT 8,
        reminder_minute INTEGER NOT NULL DEFAULT 0,
        onboarded INTEGER NOT NULL DEFAULT 0,
        grace_used INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (id) REFERENCES hunters(id) ON DELETE CASCADE
      )
    ''');
    await d.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT '⚡',
        kind TEXT NOT NULL DEFAULT 'reps',
        target INTEGER NOT NULL DEFAULT 10,
        for_date TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES hunters(id) ON DELETE CASCADE
      )
    ''');
    await d.execute('''
      CREATE TABLE daily_state (
        user_id TEXT NOT NULL,
        day TEXT NOT NULL,
        checks TEXT NOT NULL DEFAULT '{}',
        completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        PRIMARY KEY (user_id, day),
        FOREIGN KEY (user_id) REFERENCES hunters(id) ON DELETE CASCADE
      )
    ''');
    await d.execute('''
      CREATE TABLE quest_history (
        user_id TEXT NOT NULL,
        day TEXT NOT NULL,
        PRIMARY KEY (user_id, day),
        FOREIGN KEY (user_id) REFERENCES hunters(id) ON DELETE CASCADE
      )
    ''');
    await d.execute('''
      CREATE TABLE penalties (
        user_id TEXT NOT NULL,
        day TEXT NOT NULL,
        amount INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (user_id, day),
        FOREIGN KEY (user_id) REFERENCES hunters(id) ON DELETE CASCADE
      )
    ''');
  }

  String newId() {
    final n = DateTime.now().microsecondsSinceEpoch;
    final r = Random().nextInt(0x7fffffff);
    return '${n.toRadixString(36)}${r.toRadixString(36)}';
  }

  Future<List<HunterSummary>> listHunters() async {
    final rows = await db.rawQuery('''
      SELECT h.id, h.name, p.total_days, p.streak, p.onboarded
      FROM hunters h
      LEFT JOIN profiles p ON p.id = h.id
      ORDER BY h.created_at DESC
    ''');
    return rows
        .map((m) => HunterSummary(
              id: m['id'] as String,
              name: (m['name'] as String?) ?? 'Hunter',
              totalDays: (m['total_days'] as num?)?.toInt() ?? 0,
              streak: (m['streak'] as num?)?.toInt() ?? 0,
              onboarded: m['onboarded'] == 1 || m['onboarded'] == true,
            ))
        .toList();
  }

  Future<String> createHunter(String name) async {
    final id = newId();
    final now = DateTime.now().toIso8601String();
    final trimmed = name.trim().isEmpty ? 'Hunter' : name.trim();
    await db.transaction((txn) async {
      await txn.insert('hunters', {
        'id': id,
        'name': trimmed,
        'created_at': now,
      });
      await txn.insert('profiles', {
        'id': id,
        'display_name': trimmed,
        'total_days': 0,
        'streak': 0,
        'last_date': null,
        'pending_penalty': 0,
        'missed_days': 0,
        'reminder_hour': 8,
        'reminder_minute': 0,
        'onboarded': 0,
        'grace_used': 0,
        'created_at': now,
        'updated_at': now,
      });
    });
    return id;
  }

  Future<void> deleteHunter(String id) async {
    await db.delete('hunters', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hunterExists(String id) async {
    final rows = await db.query(
      'hunters',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<Map<String, dynamic>> exportSnapshot() async {
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'hunters': await db.query('hunters'),
      'profiles': await db.query('profiles'),
      'exercises': await db.query('exercises'),
      'daily_state': await db.query('daily_state'),
      'quest_history': await db.query('quest_history'),
      'penalties': await db.query('penalties'),
    };
  }

  Future<BackupRestoreResult> restoreSnapshot(Map<String, dynamic> data) async {
    final hunters = (data['hunters'] as List?) ?? const [];
    await db.transaction((txn) async {
      await txn.delete('penalties');
      await txn.delete('quest_history');
      await txn.delete('daily_state');
      await txn.delete('exercises');
      await txn.delete('profiles');
      await txn.delete('hunters');
      for (final row in hunters) {
        await txn.insert('hunters', Map<String, Object?>.from(row as Map));
      }
      for (final row in (data['profiles'] as List?) ?? const []) {
        await txn.insert('profiles', Map<String, Object?>.from(row as Map));
      }
      for (final row in (data['exercises'] as List?) ?? const []) {
        await txn.insert('exercises', Map<String, Object?>.from(row as Map));
      }
      for (final row in (data['daily_state'] as List?) ?? const []) {
        await txn.insert('daily_state', Map<String, Object?>.from(row as Map));
      }
      for (final row in (data['quest_history'] as List?) ?? const []) {
        await txn.insert('quest_history', Map<String, Object?>.from(row as Map));
      }
      for (final row in (data['penalties'] as List?) ?? const []) {
        await txn.insert('penalties', Map<String, Object?>.from(row as Map));
      }
    });
    return BackupRestoreResult(
      hunters: hunters.length,
      daysRestored: ((data['quest_history'] as List?) ?? const []).length,
      exercises: ((data['exercises'] as List?) ?? const []).length,
    );
  }
}

class HunterSummary {
  final String id;
  final String name;
  final int totalDays;
  final int streak;
  final bool onboarded;
  const HunterSummary({
    required this.id,
    required this.name,
    required this.totalDays,
    required this.streak,
    required this.onboarded,
  });
}

class BackupRestoreResult {
  final int hunters;
  final int daysRestored;
  final int exercises;
  const BackupRestoreResult({
    required this.hunters,
    required this.daysRestored,
    required this.exercises,
  });
}

String encodeChecks(Map<String, bool> checks) => jsonEncode(checks);

Map<String, bool> decodeChecks(dynamic raw) {
  if (raw == null) return {};
  final map = raw is String ? jsonDecode(raw) : raw;
  if (map is! Map) return {};
  return map.map((k, v) => MapEntry(k.toString(), v == true || v == 1));
}
