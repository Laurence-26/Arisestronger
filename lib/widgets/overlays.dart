import 'package:flutter/material.dart';

import '../models/level.dart';
import '../theme.dart';
import 'system_button.dart';

/// First-miss WARNING — the System forgives once, no progress lost.
Future<void> showMissWarningOverlay(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.bg.withValues(alpha: 0.92),
    pageBuilder: (ctx, a1, a2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('◈ SYSTEM WARNING ◈',
                  style: monoStyle(size: 11, color: AppColors.gold, spacing: 6)),
              const SizedBox(height: 16),
              const Text('⚠',
                  style: TextStyle(fontSize: 56, color: AppColors.gold)),
              const SizedBox(height: 12),
              const Text('FIRST WARNING',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: AppColors.gold)),
              const SizedBox(height: 14),
              const SizedBox(
                width: 320,
                child: Text(
                  'You missed a day. The System grants you ONE warning — no '
                  'progress lost this time. Miss again and the Penalty Zone '
                  'awaits. Do not falter, Hunter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textDim, height: 1.6),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: SystemButton(
                  label: 'UNDERSTOOD',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Full-screen LEVEL UP celebration.
Future<void> showLevelUpOverlay(BuildContext context, int levelIndex) {
  final lv = kLevels[levelIndex];
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.bg.withValues(alpha: 0.95),
    pageBuilder: (ctx, a1, a2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('◈ SYSTEM NOTIFICATION ◈',
                  style: monoStyle(size: 11, color: AppColors.gold, spacing: 6)),
              const SizedBox(height: 16),
              const Text('LEVEL UP',
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: AppColors.textBright)),
              const SizedBox(height: 8),
              Text(lv.rank,
                  style: TextStyle(
                    fontFamily: kMono,
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: lv.color,
                    shadows: [
                      Shadow(
                          color: lv.color.withValues(alpha: 0.6),
                          blurRadius: 40)
                    ],
                  )),
              const SizedBox(height: 12),
              Text(lv.name,
                  style: const TextStyle(
                      fontSize: 18,
                      letterSpacing: 3,
                      color: AppColors.textDim)),
              const SizedBox(height: 24),
              Text('NEW QUEST INTENSITY',
                  style: monoStyle(size: 11, spacing: 2)),
              const SizedBox(height: 8),
              Text('Suggested ${lv.reps} reps for core exercises',
                  style: const TextStyle(color: AppColors.text)),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: SystemButton(
                  label: 'CONFIRM',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Full-screen PENALTY ZONE confirmation. Returns true if accepted.
Future<bool> showPenaltyOverlay(
    BuildContext context, int missedDays, int currentTotal) {
  final missed = missedDays < 1 ? 1 : missedDays;
  final after = penalizedTotal(currentTotal, missed);
  final penalty = currentTotal - after;
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.bg.withValues(alpha: 0.92),
    pageBuilder: (ctx, a1, a2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('◈ PENALTY ZONE ◈',
                  style: monoStyle(size: 11, color: AppColors.red, spacing: 6)),
              const SizedBox(height: 16),
              const Text('QUEST FAILED',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: AppColors.red)),
              const SizedBox(height: 12),
              const SizedBox(
                width: 320,
                child: Text(
                  'You missed your daily quest. The System does not forgive the weak.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textDim, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
              Text('-$penalty DAYS PROGRESS',
                  style: TextStyle(
                      fontFamily: kMono,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                      shadows: [
                        Shadow(
                            color: AppColors.red.withValues(alpha: 0.5),
                            blurRadius: 20)
                      ])),
              const SizedBox(height: 6),
              Text('Progress: $currentTotal → $after days',
                  style: monoStyle(size: 12)),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: SystemButton(
                  label: 'ACCEPT PENALTY',
                  danger: true,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).then((v) => v ?? false);
}

/// 28-day completion history as colored dots.
class HistoryDots extends StatelessWidget {
  final Set<String> history;
  final Set<String> penalties;
  const HistoryDots(
      {super.key, required this.history, required this.penalties});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstCompleted = history.isEmpty
        ? null
        : history.reduce((a, b) => a.compareTo(b) < 0 ? a : b);

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List.generate(28, (i) {
        final d = today.subtract(Duration(days: 27 - i));
        final key = d.toIso8601String().substring(0, 10);
        Color color = Colors.transparent;
        Color border = AppColors.purple.withValues(alpha: 0.2);
        if (history.contains(key)) {
          color = AppColors.purple;
          border = AppColors.purple;
        } else if (penalties.contains(key)) {
          color = AppColors.red;
          border = AppColors.red;
        } else if (firstCompleted != null &&
            key.compareTo(today.toIso8601String().substring(0, 10)) < 0 &&
            key.compareTo(firstCompleted) >= 0) {
          color = AppColors.red.withValues(alpha: 0.15);
          border = AppColors.red.withValues(alpha: 0.3);
        }
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
        );
      }),
    );
  }
}
