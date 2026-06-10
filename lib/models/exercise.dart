/// A user-defined workout exercise. Mirrors the `exercises` table.
///
/// [kind] == ExerciseKind.reps  -> [target] is a rep count.
/// [kind] == ExerciseKind.time  -> [target] is seconds to hold/perform.
///
/// [forDate] == null            -> a permanent daily exercise.
/// [forDate] set                -> a one-off planned ONLY for that date
///                                 (e.g. "tomorrow's extra workout").
enum ExerciseKind { reps, time }

class Exercise {
  final String id;
  final String name;
  final String icon;
  final ExerciseKind kind;
  final int target;
  final DateTime? forDate;
  final bool active;
  final int sortOrder;

  const Exercise({
    required this.id,
    required this.name,
    required this.icon,
    required this.kind,
    required this.target,
    required this.forDate,
    required this.active,
    required this.sortOrder,
  });

  bool get isOneOff => forDate != null;

  /// Human label for the target, e.g. "30 reps" or "01:00".
  String get targetLabel {
    if (kind == ExerciseKind.reps) return '$target reps';
    final m = target ~/ 60;
    final s = target % 60;
    if (m == 0) return '${s}s';
    return '$m:${s.toString().padLeft(2, '0')} min';
  }

  factory Exercise.fromMap(Map<String, dynamic> m) {
    return Exercise(
      id: m['id'] as String,
      name: m['name'] as String,
      icon: (m['icon'] as String?) ?? '⚡',
      kind: (m['kind'] as String?) == 'time'
          ? ExerciseKind.time
          : ExerciseKind.reps,
      target: (m['target'] as num?)?.toInt() ?? 10,
      forDate: m['for_date'] == null
          ? null
          : DateTime.parse(m['for_date'].toString()),
      active: (m['active'] as bool?) ?? true,
      sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'name': name,
        'icon': icon,
        'kind': kind == ExerciseKind.time ? 'time' : 'reps',
        'target': target,
        'for_date': forDate?.toIso8601String().substring(0, 10),
        'active': active,
        'sort_order': sortOrder,
      };
}
