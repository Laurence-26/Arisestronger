import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme.dart';
import 'add_exercise_sheet.dart';
import 'system_button.dart';

/// After finishing today's quest, the System asks what EXTRA workout the
/// Hunter will take on tomorrow. Returns the drafted extras (or empty/null).
class TomorrowPlanSheet extends StatefulWidget {
  const TomorrowPlanSheet({super.key});

  static Future<List<ExerciseDraft>?> show(BuildContext context) {
    return showModalBottomSheet<List<ExerciseDraft>>(
      context: context,
      backgroundColor: AppColors.bg2,
      isScrollControlled: true,
      builder: (_) => const TomorrowPlanSheet(),
    );
  }

  @override
  State<TomorrowPlanSheet> createState() => _TomorrowPlanSheetState();
}

class _TomorrowPlanSheetState extends State<TomorrowPlanSheet> {
  final List<ExerciseDraft> _drafts = [];

  Future<void> _add() async {
    final draft =
        await AddExerciseSheet.show(context, title: 'TOMORROW\'S EXTRA');
    if (draft != null) setState(() => _drafts.add(draft));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text('◈ QUEST COMPLETE ◈',
                style: monoStyle(size: 12, color: AppColors.green, spacing: 3)),
          ),
          const SizedBox(height: 12),
          const Text('What extra will you conquer tomorrow?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBright)),
          const SizedBox(height: 6),
          Text(
            'Commit now, Hunter. The strong plan their next battle before they rest.',
            textAlign: TextAlign.center,
            style: monoStyle(size: 11, spacing: 1),
          ),
          const SizedBox(height: 18),
          if (_drafts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No extra planned yet.',
                  textAlign: TextAlign.center,
                  style: monoStyle(size: 12)),
            )
          else
            ..._drafts.asMap().entries.map((e) {
              final d = e.value;
              final label = d.kind == ExerciseKind.time
                  ? '${d.target}s'
                  : '${d.target} reps';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: panelDecoration(),
                child: Row(
                  children: [
                    Text(d.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(d.name,
                            style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w600))),
                    Text(label,
                        style: monoStyle(
                            size: 12, color: AppColors.gold, spacing: 0)),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.textDim),
                      onPressed: () =>
                          setState(() => _drafts.removeAt(e.key)),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 4),
          SystemButton(
              label: '＋ ADD EXTRA EXERCISE', ghost: true, onPressed: _add),
          const SizedBox(height: 14),
          SystemButton(
            label: _drafts.isEmpty ? 'SKIP FOR NOW' : '◈ LOCK IN TOMORROW ◈',
            onPressed: () => Navigator.of(context).pop(_drafts),
          ),
        ],
      ),
    );
  }
}
