import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme.dart';

/// A single quest row: check box, icon, name, target, optional timer / delete.
class QuestTile extends StatelessWidget {
  final Exercise exercise;
  final bool checked;
  final bool locked;
  final VoidCallback onToggle;
  final VoidCallback? onStartTimer;
  final VoidCallback? onDelete;

  const QuestTile({
    super.key,
    required this.exercise,
    required this.checked,
    required this.locked,
    required this.onToggle,
    this.onStartTimer,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isTime = exercise.kind == ExerciseKind.time;
    return InkWell(
      onTap: locked ? null : onToggle,
      child: Opacity(
        opacity: checked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Color(0x147C5CFC))),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: checked ? AppColors.purple : Colors.transparent,
                  border: Border.all(
                      color: checked
                          ? AppColors.purple
                          : AppColors.borderBright,
                      width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: checked
                      ? [
                          BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.4),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: checked
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Text(exercise.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: checked ? AppColors.textDim : AppColors.text,
                        decoration: checked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (exercise.isOneOff)
                      Text('TOMORROW\'S EXTRA',
                          style: monoStyle(
                              size: 9, color: AppColors.gold, spacing: 2)),
                  ],
                ),
              ),
              if (isTime && onStartTimer != null && !checked && !locked)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.play_circle_outline,
                      color: AppColors.cyan, size: 22),
                  onPressed: onStartTimer,
                ),
              Text(exercise.targetLabel,
                  style: monoStyle(
                      size: 13,
                      color: checked ? AppColors.green : AppColors.purple,
                      weight: FontWeight.w600,
                      spacing: 0)),
              if (onDelete != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close,
                      color: AppColors.textDim, size: 18),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
