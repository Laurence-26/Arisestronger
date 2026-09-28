import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/level.dart';
import '../theme.dart';
import 'system_button.dart';

/// First-miss WARNING — the System forgives once, no progress lost.
Future<void> showMissWarningOverlay(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.bg.withValues(alpha: 0.88),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: _fadeScale,
    pageBuilder: (ctx, a1, a2) {
      return _SystemOverlayScaffold(
        accent: AppColors.gold,
        eyebrow: 'SYSTEM WARNING',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlowBadge(
              accent: AppColors.gold,
              child: const Icon(Icons.warning_amber_rounded,
                  size: 36, color: AppColors.gold),
            ),
            const SizedBox(height: 20),
            const Text(
              'FIRST WARNING',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You missed a day. The System grants you ONE warning — no '
              'progress lost this time. Miss again and the Penalty Zone '
              'awaits.',
              textAlign: TextAlign.center,
              style: monoStyle(size: 12, spacing: 0.4).copyWith(height: 1.55),
            ),
            const SizedBox(height: 28),
            SystemButton(
              label: 'UNDERSTOOD',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
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
    barrierColor: AppColors.bg.withValues(alpha: 0.9),
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: _fadeScale,
    pageBuilder: (ctx, a1, a2) {
      return _SystemOverlayScaffold(
        accent: lv.color,
        eyebrow: 'SYSTEM NOTIFICATION',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LEVEL UP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: AppColors.textBright,
                shadows: [
                  Shadow(
                      color: lv.color.withValues(alpha: 0.45), blurRadius: 24),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _RankHero(rank: lv.rank, color: lv.color),
            const SizedBox(height: 18),
            Text(
              lv.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: lv.color,
              ),
            ),
            const SizedBox(height: 22),
            _StatStrip(children: [
              _StatChip(
                label: 'RANK',
                value: lv.rank,
                color: lv.color,
              ),
              _StatChip(
                label: 'CORE REPS',
                value: '${lv.reps}',
                color: AppColors.cyan,
              ),
              _StatChip(
                label: 'STATUS',
                value: 'ACTIVE',
                color: AppColors.green,
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text('NEW QUEST INTENSITY',
                      style: monoStyle(
                          size: 10, color: AppColors.purple, spacing: 2)),
                  const SizedBox(height: 6),
                  Text(
                    'Suggested ${lv.reps} reps for core exercises',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: kSans,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBright,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SystemButton(
              label: 'CONFIRM',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
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
    barrierColor: AppColors.bg.withValues(alpha: 0.9),
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: _fadeScale,
    pageBuilder: (ctx, a1, a2) {
      return _SystemOverlayScaffold(
        accent: AppColors.red,
        eyebrow: 'PENALTY ZONE',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlowBadge(
              accent: AppColors.red,
              child: const Icon(Icons.gpp_maybe_outlined,
                  size: 34, color: AppColors.red),
            ),
            const SizedBox(height: 18),
            const Text(
              'QUEST FAILED',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You missed your daily quest. The System does not forgive the weak.',
              textAlign: TextAlign.center,
              style: monoStyle(size: 12, spacing: 0.4).copyWith(height: 1.55),
            ),
            const SizedBox(height: 22),
            _StatStrip(children: [
              _StatChip(
                label: 'MISSED',
                value: '$missed',
                color: AppColors.gold,
              ),
              _StatChip(
                label: 'PENALTY',
                value: '-$penalty',
                color: AppColors.red,
              ),
              _StatChip(
                label: 'AFTER',
                value: '$after',
                color: AppColors.cyan,
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.red.withValues(alpha: 0.14),
                    AppColors.bg3,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  Text(
                    '-$penalty DAYS PROGRESS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kMono,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.red,
                      shadows: [
                        Shadow(
                            color: AppColors.red.withValues(alpha: 0.45),
                            blurRadius: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Progress  $currentTotal  →  $after days',
                    style: monoStyle(size: 12, spacing: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SystemButton(
              label: 'ACCEPT PENALTY',
              danger: true,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );
    },
  ).then((v) => v ?? false);
}

Widget _fadeScale(BuildContext context, Animation<double> anim,
    Animation<double> secondary, Widget child) {
  final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
      child: child,
    ),
  );
}

class _SystemOverlayScaffold extends StatelessWidget {
  final Color accent;
  final String eyebrow;
  final Widget child;

  const _SystemOverlayScaffold({
    required this.accent,
    required this.eyebrow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: accent.withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 36,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -80,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                accent.withValues(alpha: 0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '◈ $eyebrow ◈',
                            textAlign: TextAlign.center,
                            style: monoStyle(
                                size: 11, color: accent, spacing: 3),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 48,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                accent,
                                Colors.transparent,
                              ]),
                            ),
                          ),
                          const SizedBox(height: 20),
                          child,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankHero extends StatelessWidget {
  final String rank;
  final Color color;
  const _RankHero({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                color.withValues(alpha: 0.28),
                Colors.transparent,
              ]),
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 28),
                ],
              ),
            ),
          ),
          Text(
            rank,
            style: TextStyle(
              fontFamily: kMono,
              fontSize: rank.length > 1 ? 36 : 44,
              fontWeight: FontWeight.w700,
              color: color,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.7), blurRadius: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBadge extends StatelessWidget {
  final Color accent;
  final Widget child;
  const _GlowBadge({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 22),
        ],
      ),
      child: child,
    );
  }
}

class _StatStrip extends StatelessWidget {
  final List<Widget> children;
  const _StatStrip({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          const SizedBox(height: 4),
          Text(label, style: monoStyle(size: 9, spacing: 1)),
        ],
      ),
    );
  }
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
