import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme.dart';
import 'system_button.dart';

/// A drafted exercise returned by the add sheet (not yet persisted).
class ExerciseDraft {
  final String name;
  final String icon;
  final ExerciseKind kind;
  final int target;
  ExerciseDraft(this.name, this.icon, this.kind, this.target);
}

const List<String> _icons = [
  '💪', '🔥', '⚡', '🏋️', '🤸', '🧘', '🦵', '🥊', '🏊', '🚴', '⏱️', '🎯'
];

/// Bottom sheet to define a custom exercise — reps or timed.
class AddExerciseSheet extends StatefulWidget {
  final String title;
  const AddExerciseSheet({super.key, this.title = 'ADD EXERCISE'});

  static Future<ExerciseDraft?> show(BuildContext context,
      {String title = 'ADD EXERCISE'}) {
    return showModalBottomSheet<ExerciseDraft>(
      context: context,
      backgroundColor: AppColors.bg2,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddExerciseSheet(title: title),
      ),
    );
  }

  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController(text: '10');
  String _icon = '⚡';
  ExerciseKind _kind = ExerciseKind.reps;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    var amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (_kind == ExerciseKind.time) {
      // Field is entered in seconds.
      amount = amount.clamp(5, 3600);
    } else {
      amount = amount.clamp(1, 1000);
    }
    Navigator.of(context).pop(ExerciseDraft(name, _icon, _kind, amount));
  }

  @override
  Widget build(BuildContext context) {
    final isTime = _kind == ExerciseKind.time;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text('◈ ${widget.title} ◈',
                style: monoStyle(size: 12, color: AppColors.purple, spacing: 3)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            style: const TextStyle(color: AppColors.textBright),
            decoration: const InputDecoration(hintText: 'Exercise name'),
          ),
          const SizedBox(height: 16),
          Text('ICON', style: monoStyle(size: 10, spacing: 2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _icons.map((ic) {
              final selected = ic == _icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = ic),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.purple.withValues(alpha: 0.15)
                        : AppColors.bg3,
                    border: Border.all(
                        color: selected
                            ? AppColors.purple
                            : AppColors.border),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(ic, style: const TextStyle(fontSize: 20)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('TYPE', style: monoStyle(size: 10, spacing: 2)),
          const SizedBox(height: 8),
          Row(
            children: [
              _typeChip('REPS', ExerciseKind.reps),
              const SizedBox(width: 8),
              _typeChip('TIMED', ExerciseKind.time),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textBright),
            decoration: InputDecoration(
              labelText: isTime ? 'Duration (seconds)' : 'Reps',
              suffixText: isTime ? 'sec' : 'reps',
            ),
          ),
          const SizedBox(height: 20),
          SystemButton(label: '◈ SAVE ◈', onPressed: _save),
        ],
      ),
    );
  }

  Widget _typeChip(String label, ExerciseKind kind) {
    final selected = _kind == kind;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _kind = kind;
          _amount.text = kind == ExerciseKind.time ? '60' : '10';
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.purple.withValues(alpha: 0.15)
                : AppColors.bg3,
            border: Border.all(
                color: selected ? AppColors.purple : AppColors.border),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(label,
              style: monoStyle(
                  size: 12,
                  color: selected ? AppColors.purple : AppColors.textDim,
                  spacing: 2)),
        ),
      ),
    );
  }
}
