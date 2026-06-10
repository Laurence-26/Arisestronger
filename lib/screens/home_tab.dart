import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/level.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/add_exercise_sheet.dart';
import '../widgets/animated_flame.dart';
import '../widgets/overlays.dart';
import '../widgets/quest_tile.dart';
import '../widgets/quote_card.dart';
import '../widgets/rank_card.dart';
import '../widgets/system_button.dart';
import '../widgets/timer_sheet.dart';
import '../widgets/tomorrow_plan_sheet.dart';

/// The QUEST tab — today's workout, streak, quote, rank, and completion.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final dateLabel =
        DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()).toUpperCase();
    final exercises = s.todayExercises;
    final completed = s.completedToday;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('◈ ${_greeting()} ◈',
                    style:
                        monoStyle(size: 11, color: AppColors.purple, spacing: 4)),
                const SizedBox(height: 4),
                Text(s.profile.displayName.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: AppColors.textBright)),
                const SizedBox(height: 2),
                Text(dateLabel, style: monoStyle(size: 11, spacing: 1)),
              ],
            ),
            const SizedBox(height: 16),

            _StreakBanner(state: s),
            QuoteCard(quote: s.todayQuote),
            RankCard(state: s),
            const SizedBox(height: 14),

            // Today's quest panel
            Container(
              decoration: panelDecoration(),
              child: Column(
                children: [
                  _panelHeader('◈ TODAY\'S QUEST',
                      '${s.checkedCount} / ${s.totalCount}'),
                  ...exercises.map((e) => QuestTile(
                        exercise: e,
                        checked: completed || s.isChecked(e.id),
                        locked: completed || s.profile.pendingPenalty,
                        onToggle: () => s.toggleCheck(e.id),
                        onStartTimer: e.kind == ExerciseKind.time
                            ? () => _runTimer(context, s, e)
                            : null,
                      )),
                  if (!completed && !s.profile.pendingPenalty)
                    InkWell(
                      onTap: () => _addExercise(context, s),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        alignment: Alignment.center,
                        child: Text('＋ ADD YOUR OWN EXERCISE',
                            style: monoStyle(
                                size: 12, color: AppColors.cyan, spacing: 2)),
                      ),
                    ),
                  _completionBar(s),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (s.profile.pendingPenalty)
              _PenaltySection(state: s)
            else
              SystemButton(
                label: completed
                    ? '✓ QUEST COMPLETE — WELL DONE, HUNTER'
                    : '◈ QUEST COMPLETE ◈',
                onPressed: (completed || !s.allCheckedToday)
                    ? null
                    : () => _complete(context, s),
              ),
            if (!completed &&
                !s.allCheckedToday &&
                !s.profile.pendingPenalty &&
                exercises.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Complete all exercises to finish your quest.',
                    textAlign: TextAlign.center, style: monoStyle(size: 11)),
              ),
            const SizedBox(height: 18),
            Center(child: Text('◈ ARISE ◈', style: monoStyle(size: 11, spacing: 3))),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'GOOD MORNING, HUNTER';
    if (h < 17) return 'RISE AND GRIND, HUNTER';
    return 'GOOD EVENING, HUNTER';
  }

  Widget _panelHeader(String title, String badge) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.06),
          border: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Text(title,
                style:
                    monoStyle(size: 11, color: AppColors.purple, spacing: 4)),
            const Spacer(),
            Text(badge, style: monoStyle(size: 10)),
          ],
        ),
      );

  Widget _completionBar(AppState s) {
    final pct = s.totalCount == 0 ? 0.0 : s.checkedCount / s.totalCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0x33000000),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('COMPLETION', style: monoStyle(size: 11)),
              const Spacer(),
              Text('${(pct * 100).round()}%',
                  style: monoStyle(size: 11, color: AppColors.green)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: Container(
              height: 4,
              color: Colors.white.withValues(alpha: 0.06),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppColors.green, AppColors.blue]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _complete(BuildContext context, AppState s) async {
    final result = await s.completeDay();
    if (!context.mounted) return;
    if (result.leveledUp) {
      await showLevelUpOverlay(context, result.newLevelIndex);
    }
    if (!context.mounted) return;
    final extras = await TomorrowPlanSheet.show(context);
    if (extras != null && extras.isNotEmpty) {
      await s.planTomorrow(extras
          .map((d) => Exercise(
                id: 'temp',
                name: d.name,
                icon: d.icon,
                kind: d.kind,
                target: d.target,
                forDate: DateTime.now().add(const Duration(days: 1)),
                active: true,
                sortOrder: 0,
              ))
          .toList());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tomorrow\'s extra quest locked in. Arise, Hunter.'),
          backgroundColor: AppColors.bg3,
        ));
      }
    }
  }

  Future<void> _addExercise(BuildContext context, AppState s) async {
    final draft = await AddExerciseSheet.show(context);
    if (draft != null) {
      await s.addExercise(
        name: draft.name,
        icon: draft.icon,
        kind: draft.kind,
        target: draft.target,
      );
    }
  }

  Future<void> _runTimer(BuildContext context, AppState s, Exercise e) async {
    final done = await TimerSheet.show(context, e);
    if (done == true && !s.isChecked(e.id)) {
      await s.toggleCheck(e.id);
    }
  }
}

/// Streak hero — the single biggest reason to come back tomorrow.
class _StreakBanner extends StatelessWidget {
  final AppState state;
  const _StreakBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final streak = state.profile.streak;
    final completed = state.completedToday;
    final hasStreak = streak >= 1;
    final accent = hasStreak ? AppColors.gold : AppColors.purple;
    final title = hasStreak ? '$streak DAY STREAK' : 'IGNITE YOUR STREAK';
    final String subtitle;
    if (!hasStreak) {
      subtitle = 'Complete today\'s quest to light the flame.';
    } else if (completed) {
      subtitle = 'Secured. Return tomorrow to keep the flame alive.';
    } else {
      subtitle = 'Finish today\'s quest to extend it. Don\'t break the chain.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [accent.withValues(alpha: 0.16), AppColors.bg2]),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 18),
        ],
      ),
      child: Row(
        children: [
          AnimatedFlame(size: 30, active: hasStreak),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontFamily: kMono,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(subtitle, style: monoStyle(size: 11, spacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PenaltySection extends StatelessWidget {
  final AppState state;
  const _PenaltySection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠ PENALTY ZONE WARNING',
              style: monoStyle(size: 11, color: AppColors.red, spacing: 3)),
          const SizedBox(height: 8),
          Text(
            'You missed ${state.profile.missedDays} day(s). At ${state.level.rank}-Rank '
            'the System deducts -${penaltyPerDayFor(state.profile.totalDays)} days per missed day.',
            style: const TextStyle(color: AppColors.textDim, height: 1.5),
          ),
          const SizedBox(height: 12),
          SystemButton(
            label: 'ACCEPT PENALTY',
            danger: true,
            onPressed: () async {
              final ok = await showPenaltyOverlay(
                  context, state.profile.missedDays, state.profile.totalDays);
              if (ok) await state.acceptPenalty();
            },
          ),
        ],
      ),
    );
  }
}
