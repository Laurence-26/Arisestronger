import '../models/exercise.dart';

/// A prescribed exercise the System assigns at a given rank.
class PrescribedExercise {
  final String name;
  final String icon;
  final ExerciseKind kind;
  final int target; // reps, or seconds for timed
  const PrescribedExercise(this.name, this.icon, this.kind, this.target);
}

const _r = ExerciseKind.reps;
const _t = ExerciseKind.time;

/// The full workout program for every rank, indexed by rank level (0 = E).
/// Each rank adds movements and raises targets so the Hunter keeps getting
/// stronger. Users may add their own exercises on top of these.
const List<List<PrescribedExercise>> kRankPrograms = [
  // 0 — E-Rank Hunter (foundation)
  [
    PrescribedExercise('Push-ups', '💪', _r, 10),
    PrescribedExercise('Sit-ups', '🔥', _r, 10),
    PrescribedExercise('Squats', '⚡', _r, 10),
    PrescribedExercise('Plank', '🧘', _t, 30),
  ],
  // 1 — E+ Awakened Hunter
  [
    PrescribedExercise('Push-ups', '💪', _r, 15),
    PrescribedExercise('Sit-ups', '🔥', _r, 15),
    PrescribedExercise('Squats', '⚡', _r, 15),
    PrescribedExercise('Plank', '🧘', _t, 40),
    PrescribedExercise('Jumping Jacks', '🤸', _r, 20),
  ],
  // 2 — D-Rank Hunter
  [
    PrescribedExercise('Push-ups', '💪', _r, 20),
    PrescribedExercise('Sit-ups', '🔥', _r, 20),
    PrescribedExercise('Squats', '⚡', _r, 20),
    PrescribedExercise('Plank', '🧘', _t, 50),
    PrescribedExercise('Jumping Jacks', '🤸', _r, 30),
    PrescribedExercise('Lunges', '🦵', _r, 20),
  ],
  // 3 — D+ Elite D-Rank Hunter
  [
    PrescribedExercise('Push-ups', '💪', _r, 30),
    PrescribedExercise('Sit-ups', '🔥', _r, 30),
    PrescribedExercise('Squats', '⚡', _r, 30),
    PrescribedExercise('Plank', '🧘', _t, 60),
    PrescribedExercise('Jumping Jacks', '🤸', _r, 40),
    PrescribedExercise('Lunges', '🦵', _r, 30),
    PrescribedExercise('Mountain Climbers', '🏔️', _r, 30),
  ],
  // 4 — C-Rank Hunter
  [
    PrescribedExercise('Push-ups', '💪', _r, 40),
    PrescribedExercise('Sit-ups', '🔥', _r, 40),
    PrescribedExercise('Squats', '⚡', _r, 40),
    PrescribedExercise('Plank', '🧘', _t, 75),
    PrescribedExercise('Burpees', '🥵', _r, 15),
    PrescribedExercise('Lunges', '🦵', _r, 40),
    PrescribedExercise('Mountain Climbers', '🏔️', _r, 40),
  ],
  // 5 — C+ Elite C-Rank Hunter
  [
    PrescribedExercise('Push-ups', '💪', _r, 50),
    PrescribedExercise('Sit-ups', '🔥', _r, 50),
    PrescribedExercise('Squats', '⚡', _r, 50),
    PrescribedExercise('Plank', '🧘', _t, 90),
    PrescribedExercise('Burpees', '🥵', _r, 20),
    PrescribedExercise('Lunges', '🦵', _r, 50),
    PrescribedExercise('Mountain Climbers', '🏔️', _r, 50),
    PrescribedExercise('High Knees', '🏃', _t, 60),
  ],
  // 6 — B-Rank Hunter
  [
    PrescribedExercise('Push-ups', '💪', _r, 60),
    PrescribedExercise('Sit-ups', '🔥', _r, 60),
    PrescribedExercise('Squats', '⚡', _r, 60),
    PrescribedExercise('Plank', '🧘', _t, 120),
    PrescribedExercise('Burpees', '🥵', _r, 25),
    PrescribedExercise('Pull-ups', '🏋️', _r, 10),
    PrescribedExercise('Mountain Climbers', '🏔️', _r, 60),
  ],
  // 7 — A-Rank Hunter
  [
    PrescribedExercise('Push-ups', '💪', _r, 75),
    PrescribedExercise('Sit-ups', '🔥', _r, 75),
    PrescribedExercise('Squats', '⚡', _r, 75),
    PrescribedExercise('Plank', '🧘', _t, 150),
    PrescribedExercise('Burpees', '🥵', _r, 30),
    PrescribedExercise('Pull-ups', '🏋️', _r, 15),
    PrescribedExercise('Pistol Squats', '🦵', _r, 10),
  ],
  // 8 — A+ Elite A-Rank Hunter
  [
    PrescribedExercise('Push-ups', '💪', _r, 90),
    PrescribedExercise('Sit-ups', '🔥', _r, 90),
    PrescribedExercise('Squats', '⚡', _r, 90),
    PrescribedExercise('Plank', '🧘', _t, 180),
    PrescribedExercise('Burpees', '🥵', _r, 40),
    PrescribedExercise('Pull-ups', '🏋️', _r, 20),
    PrescribedExercise('Pistol Squats', '🦵', _r, 16),
  ],
  // 9 — S-Rank Shadow Monarch (the canonical 100s)
  [
    PrescribedExercise('Push-ups', '💪', _r, 100),
    PrescribedExercise('Sit-ups', '🔥', _r, 100),
    PrescribedExercise('Squats', '⚡', _r, 100),
    PrescribedExercise('Plank', '🧘', _t, 240),
    PrescribedExercise('Burpees', '🥵', _r, 50),
    PrescribedExercise('Pull-ups', '🏋️', _r, 25),
    PrescribedExercise('Pistol Squats', '🦵', _r, 20),
    PrescribedExercise('Handstand Hold', '🤸', _t, 30),
  ],
];

/// Build the System-prescribed exercises for a rank as [Exercise] objects with
/// stable synthetic ids (so daily completion checks can key off them).
List<Exercise> rankExercises(int levelIndex) {
  final prog = kRankPrograms[levelIndex.clamp(0, kRankPrograms.length - 1)];
  return [
    for (var i = 0; i < prog.length; i++)
      Exercise(
        id: 'sys_${levelIndex}_$i',
        name: prog[i].name,
        icon: prog[i].icon,
        kind: prog[i].kind,
        target: prog[i].target,
        forDate: null,
        active: true,
        sortOrder: i,
      ),
  ];
}
