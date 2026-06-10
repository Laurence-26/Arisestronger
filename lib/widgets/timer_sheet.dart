import 'dart:async';

import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme.dart';
import 'system_button.dart';

/// Countdown timer for a time-based exercise (e.g. Plank 60s).
/// Returns true via [onComplete] when the full duration elapses.
class TimerSheet extends StatefulWidget {
  final Exercise exercise;
  const TimerSheet({super.key, required this.exercise});

  static Future<bool?> show(BuildContext context, Exercise e) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.bg2,
      isDismissible: true,
      builder: (_) => TimerSheet(exercise: e),
    );
  }

  @override
  State<TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<TimerSheet> {
  late int _remaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.exercise.target;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  String get _label {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.exercise.target == 0
        ? 0.0
        : 1 - (_remaining / widget.exercise.target);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('◈ ${widget.exercise.name.toUpperCase()} ◈',
              style: monoStyle(size: 12, color: AppColors.cyan, spacing: 3)),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: pct.clamp(0, 1),
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.cyan),
                  ),
                ),
                Text(_label,
                    style: const TextStyle(
                        fontFamily: kMono,
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textBright)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SystemButton(
            label: _running ? '⏸ PAUSE' : '▶ START',
            onPressed: _toggle,
          ),
          const SizedBox(height: 8),
          SystemButton(
            label: 'MARK DONE',
            ghost: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}
