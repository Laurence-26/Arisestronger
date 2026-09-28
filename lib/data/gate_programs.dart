import '../models/exercise.dart';
import '../models/level.dart';
import '../services/local_database.dart';

/// Compact weekly Gate raid — harder than the daily set, short enough to finish
/// in one session. Targets scale from the Hunter's current rank reps (~1.4x).
List<Exercise> gateExercisesFor(int levelIndex, {DateTime? onDate}) {
  final i = levelIndex.clamp(0, kLevels.length - 1);
  final reps = kLevels[i].reps;
  final core = (reps * 1.4).round();
  final plank = _plankSeconds(i);
  final week = isoWeekKey(onDate ?? DateTime.now());

  final drafts = <_GateDraft>[
    _GateDraft('Push-ups', '💪', ExerciseKind.reps, core),
    _GateDraft('Squats', '⚡', ExerciseKind.reps, core),
    _GateDraft('Plank', '🧘', ExerciseKind.time, plank),
  ];

  if (i >= 2) {
    drafts.add(_GateDraft('Burpees', '🥵', ExerciseKind.reps, (reps * 0.75).round().clamp(8, 60)));
  }
  if (i >= 4) {
    drafts.add(_GateDraft(
        'Mountain Climbers', '🏔️', ExerciseKind.reps, (reps * 1.1).round()));
  }
  if (i >= 6) {
    // Replace mountain climbers with a higher-skill boss move at B+.
    drafts.removeWhere((d) => d.name == 'Mountain Climbers');
    if (i >= 7) {
      drafts.add(_GateDraft(
          'Pistol Squats', '🦵', ExerciseKind.reps, (reps * 0.2).round().clamp(6, 24)));
    } else {
      drafts.add(_GateDraft(
          'Pull-ups', '🏋️', ExerciseKind.reps, (reps * 0.2).round().clamp(6, 25)));
    }
  }
  if (i >= 9) {
    drafts.add(const _GateDraft('Handstand Hold', '🤸', ExerciseKind.time, 40));
  }

  // Cap at 5 rows so the raid stays focused.
  final sliced = drafts.take(5).toList();
  return [
    for (var n = 0; n < sliced.length; n++)
      Exercise(
        id: 'gate_${i}_${n}_$week',
        name: sliced[n].name,
        icon: sliced[n].icon,
        kind: sliced[n].kind,
        target: sliced[n].target,
        forDate: null,
        active: true,
        sortOrder: n,
      ),
  ];
}

int _plankSeconds(int levelIndex) {
  const base = [40, 55, 70, 85, 105, 125, 160, 200, 240, 300];
  return base[levelIndex.clamp(0, base.length - 1)];
}

class _GateDraft {
  final String name;
  final String icon;
  final ExerciseKind kind;
  final int target;
  const _GateDraft(this.name, this.icon, this.kind, this.target);
}

const List<String> kWeekdayLabels = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String weekdayLabel(int weekday) {
  final i = weekday.clamp(1, 7) - 1;
  return kWeekdayLabels[i];
}

String weekdayShort(int weekday) {
  const shorts = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return shorts[weekday.clamp(1, 7) - 1];
}
