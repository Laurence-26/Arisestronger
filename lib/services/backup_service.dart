import 'dart:convert';

import 'local_database.dart';

class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);
  @override
  String toString() => message;
}

class BackupPreview {
  final int hunters;
  final int days;
  final int exercises;
  const BackupPreview({
    required this.hunters,
    required this.days,
    required this.exercises,
  });
}

/// Export / import a JSON snapshot of the local database.
class BackupService {
  Future<String> exportJson() async {
    final snap = await LocalDatabase.instance.exportSnapshot();
    return const JsonEncoder.withIndent('  ').convert(snap);
  }

  String suggestedFileName() {
    final d = DateTime.now().toIso8601String().substring(0, 10);
    return 'arisestronger-backup-$d.json';
  }

  Future<BackupPreview> inspect(String json) async {
    final data = _parse(json);
    return BackupPreview(
      hunters: ((data['hunters'] as List?) ?? const []).length,
      days: ((data['quest_history'] as List?) ?? const []).length,
      exercises: ((data['exercises'] as List?) ?? const []).length,
    );
  }

  Future<BackupRestoreResult> restore(String json) {
    return LocalDatabase.instance.restoreSnapshot(_parse(json));
  }

  Map<String, dynamic> _parse(String json) {
    late final dynamic data;
    try {
      data = jsonDecode(json);
    } catch (_) {
      throw const BackupFormatException('That file is not valid JSON.');
    }
    if (data is! Map<String, dynamic> || data['hunters'] is! List) {
      throw const BackupFormatException(
          'This is not an AriseStronger backup file.');
    }
    return data;
  }
}
