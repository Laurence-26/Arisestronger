import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/rank_programs.dart';
import '../models/exercise.dart';
import '../models/level.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/add_exercise_sheet.dart';

/// The PROGRAM tab — the System's prescribed workout for the current rank,
/// the Hunter's own custom exercises, and a roadmap of every rank.
class ProgramTab extends StatelessWidget {
  const ProgramTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lv = s.level;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('◈ TRAINING PROGRAM ◈',
                style: monoStyle(size: 11, color: AppColors.purple, spacing: 4)),
            const SizedBox(height: 6),
            Row(
              children: [
                _rankBadge(lv.rank, lv.color, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lv.name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textBright)),
                      Text('SYSTEM-PRESCRIBED DAILY SET',
                          style: monoStyle(size: 10, spacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Prescribed program
            Container(
              decoration: panelDecoration(),
              child: Column(
                children: [
                  for (final e in s.rankProgram) _readonlyRow(e, lv.color),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Custom exercises
            Row(
              children: [
                Text('◈ YOUR EXERCISES',
                    style:
                        monoStyle(size: 11, color: AppColors.cyan, spacing: 3)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _add(context, s),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.cyan),
                  label: Text('ADD',
                      style:
                          monoStyle(size: 11, color: AppColors.cyan, spacing: 1)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (s.customExercises.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: panelDecoration(),
                child: Text(
                    'Add your own exercises on top of the System\'s program. '
                    'They appear in your daily quest.',
                    style: monoStyle(size: 12, spacing: 0.3)),
              )
            else
              Container(
                decoration: panelDecoration(),
                child: Column(
                  children: [
                    for (final e in s.customExercises)
                      _readonlyRow(e, AppColors.cyan, onDelete: () {
                        s.deleteExercise(e.id);
                      }),
                  ],
                ),
              ),
            const SizedBox(height: 18),

            // Rank roadmap
            Text('◈ RANK ROADMAP',
                style: monoStyle(size: 11, color: AppColors.purple, spacing: 3)),
            const SizedBox(height: 8),
            ...List.generate(kLevels.length, (i) => _roadmapTile(s, i)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, AppState s) async {
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

  Widget _rankBadge(String rank, Color color, double size) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(rank,
            style: TextStyle(
                fontFamily: kMono,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
                color: color)),
      );

  Widget _readonlyRow(Exercise e, Color accent, {VoidCallback? onDelete}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x147C5CFC))),
      ),
      child: Row(
        children: [
          Text(e.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(e.name,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
          Text(e.targetLabel,
              style: monoStyle(
                  size: 13, color: accent, weight: FontWeight.w600, spacing: 0)),
          if (onDelete != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.textDim),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  Widget _roadmapTile(AppState s, int i) {
    final lv = kLevels[i];
    final program = kRankPrograms[i];
    final isCurrent = i == s.levelIndex;
    final reached = i <= s.levelIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
            color: isCurrent ? lv.color : AppColors.border,
            width: isCurrent ? 1.5 : 1),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: _rankBadge(lv.rank, lv.color, 38),
          title: Text(lv.name,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: reached ? AppColors.textBright : AppColors.textDim)),
          subtitle: Text(
              isCurrent
                  ? 'CURRENT RANK'
                  : reached
                      ? 'UNLOCKED'
                      : '${program.length} exercises',
              style: monoStyle(
                  size: 10,
                  color: isCurrent ? lv.color : AppColors.textDim,
                  spacing: 1)),
          iconColor: lv.color,
          collapsedIconColor: AppColors.textDim,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: [
            for (final p in program)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                child: Row(
                  children: [
                    Text(p.icon, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(p.name,
                            style: const TextStyle(
                                color: AppColors.text, fontSize: 14))),
                    Text(
                      p.kind == ExerciseKind.time
                          ? _timeLabel(p.target)
                          : '${p.target} reps',
                      style: monoStyle(size: 12, color: lv.color, spacing: 0),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(int seconds) {
    final m = seconds ~/ 60;
    final sec = seconds % 60;
    if (m == 0) return '${sec}s';
    return '$m:${sec.toString().padLeft(2, '0')} min';
  }
}
