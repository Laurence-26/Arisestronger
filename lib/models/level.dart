import 'package:flutter/material.dart';

/// A Hunter rank tier. Ported from the original Daily Quest System,
/// with running removed — base reps scale per rank and are applied to
/// the three classic starter exercises (Push-ups / Sit-ups / Squats).
class Level {
  final String rank;
  final String name;
  final int reps; // suggested rep target for starter exercises at this rank
  final Color color;

  const Level({
    required this.rank,
    required this.name,
    required this.reps,
    required this.color,
  });
}

const List<Level> kLevels = [
  Level(rank: 'E', name: 'E-Rank Hunter', reps: 10, color: Color(0xFFC8C8E8)),
  Level(rank: 'E+', name: 'Awakened Hunter', reps: 15, color: Color(0xFF7C5CFC)),
  Level(rank: 'D', name: 'D-Rank Hunter', reps: 20, color: Color(0xFF3D9BFF)),
  Level(rank: 'D+', name: 'Elite D-Rank Hunter', reps: 30, color: Color(0xFF2ED573)),
  Level(rank: 'C', name: 'C-Rank Hunter', reps: 40, color: Color(0xFFFFD32A)),
  Level(rank: 'C+', name: 'Elite C-Rank Hunter', reps: 50, color: Color(0xFFFF9F43)),
  Level(rank: 'B', name: 'B-Rank Hunter', reps: 60, color: Color(0xFFFF6B81)),
  Level(rank: 'A', name: 'A-Rank Hunter', reps: 75, color: Color(0xFFFF4757)),
  Level(rank: 'A+', name: 'Elite A-Rank Hunter', reps: 90, color: Color(0xFFE84393)),
  Level(rank: 'S', name: 'Shadow Monarch', reps: 100, color: Color(0xFFF0B429)),
];

// ---------------- PENALTY (scales with rank) ----------------
// Each missed day costs (kPenaltyBase + kPenaltyPerRank * rankIndex) days, so
// the penalty is gentle for beginners and a real threat at high ranks.
const int kPenaltyBase = 3;
const int kPenaltyPerRank = 2;

/// Days of progress lost per missed day at the Hunter's current rank.
int penaltyPerDayFor(int totalDays) =>
    kPenaltyBase + kPenaltyPerRank * levelIndexOf(totalDays);

/// New totalDays after a penalty, capped so a single event drops you at most
/// one rank (never below the previous rank's threshold).
int penalizedTotal(int totalDays, int missedDays) {
  final perDay = penaltyPerDayFor(totalDays);
  final raw = totalDays - missedDays * perDay;
  final i = levelIndexOf(totalDays);
  final floor = kRankThresholds[i == 0 ? 0 : i - 1];
  return raw < floor ? floor : raw;
}

/// Days required to advance OUT of each rank (index 0 = E … 9 = S).
/// Escalating curve: quick early wins, a real grind at the top, and ~2–3 weeks
/// per intensity jump in the harder ranks so the body can adapt. The final
/// entry is unused (Shadow Monarch is the ceiling). Total E→S ≈ 126 days.
const List<int> kRankDurations = [7, 7, 10, 10, 14, 14, 18, 21, 25, 0];

/// Cumulative totalDays needed to *reach* each rank (threshold[0] == 0).
final List<int> kRankThresholds = _buildThresholds();

List<int> _buildThresholds() {
  final out = <int>[0];
  for (var i = 1; i < kRankDurations.length; i++) {
    out.add(out[i - 1] + kRankDurations[i - 1]);
  }
  return out;
}

int levelIndexOf(int totalDays) {
  final d = totalDays < 0 ? 0 : totalDays;
  var idx = 0;
  for (var i = 0; i < kRankThresholds.length; i++) {
    if (d >= kRankThresholds[i]) {
      idx = i;
    } else {
      break;
    }
  }
  return idx;
}

/// Days completed within the current rank.
int daysIntoLevelFor(int totalDays) {
  final i = levelIndexOf(totalDays);
  return totalDays - kRankThresholds[i];
}

/// Days remaining until the next rank (0 at max rank).
int daysToNextLevelFor(int totalDays) {
  final i = levelIndexOf(totalDays);
  if (i >= kLevels.length - 1) return 0;
  return kRankThresholds[i + 1] - totalDays;
}

/// Progress through the current rank, 0–1 (1 at max rank).
double levelProgressFor(int totalDays) {
  final i = levelIndexOf(totalDays);
  if (i >= kLevels.length - 1) return 1.0;
  final dur = kRankDurations[i];
  return dur == 0 ? 1.0 : (totalDays - kRankThresholds[i]) / dur;
}

/// Self-reported fitness level chosen during onboarding, which sets the
/// starting rank. Beginner → E, Intermediate → C, Pro → B.
enum StartLevel { beginner, intermediate, pro }

extension StartLevelInfo on StartLevel {
  /// Rank index this level starts at.
  int get startLevelIndex {
    switch (this) {
      case StartLevel.beginner:
        return 0; // E-Rank
      case StartLevel.intermediate:
        return 4; // C-Rank
      case StartLevel.pro:
        return 6; // B-Rank
    }
  }

  /// totalDays needed to sit at the start of that rank.
  int get startTotalDays => kRankThresholds[startLevelIndex];

  String get title {
    switch (this) {
      case StartLevel.beginner:
        return 'BEGINNER';
      case StartLevel.intermediate:
        return 'INTERMEDIATE';
      case StartLevel.pro:
        return 'PRO';
    }
  }

  String get subtitle {
    switch (this) {
      case StartLevel.beginner:
        return 'New to training — start at E-Rank and build the foundation.';
      case StartLevel.intermediate:
        return 'Train regularly — begin at C-Rank with a tougher program.';
      case StartLevel.pro:
        return 'Seriously fit — enter at B-Rank and push toward Monarch.';
    }
  }

  String get rankLabel => kLevels[startLevelIndex].rank;
}
