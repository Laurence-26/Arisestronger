import 'package:flutter/material.dart';

import '../models/level.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Player rank badge, progress to next rank, and the three stat boxes.
class RankCard extends StatelessWidget {
  final AppState state;
  const RankCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final lv = state.level;
    final isMax = state.levelIndex == kLevels.length - 1;
    final completed = state.completedToday;

    return Column(
      children: [
        Container(
          decoration: panelDecoration(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: lv.color.withValues(alpha: 0.1),
                      border: Border.all(color: lv.color, width: 2),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                            color: lv.color.withValues(alpha: 0.3),
                            blurRadius: 16),
                      ],
                    ),
                    child: Text(lv.rank,
                        style: TextStyle(
                            fontFamily: kMono,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: lv.color)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PLAYER RANK', style: monoStyle(size: 10, spacing: 3)),
                        const SizedBox(height: 2),
                        Text(lv.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textBright)),
                        const SizedBox(height: 2),
                        Text(
                          isMax
                              ? '▸ MAXIMUM RANK ACHIEVED'
                              : '▸ ${state.daysToNextLevel} days to ${kLevels[state.levelIndex + 1].rank}-Rank',
                          style: monoStyle(
                              size: 12, color: AppColors.purple, spacing: 1),
                        ),
                      ],
                    ),
                  ),
                  _statusTag(completed),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('RANK PROGRESS', style: monoStyle(size: 11)),
                  const Spacer(),
                  Text('${(state.levelProgress * 100).round()}%',
                      style: monoStyle(size: 11)),
                ],
              ),
              const SizedBox(height: 5),
              _bar(state.levelProgress,
                  const [AppColors.purple, AppColors.blue]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _stat('${state.profile.streak}', 'STREAK'),
            const SizedBox(width: 8),
            _stat('${state.profile.totalDays}', 'TOTAL DAYS'),
            const SizedBox(width: 8),
            _stat('${state.levelIndex + 1}', 'LEVEL'),
          ],
        ),
      ],
    );
  }

  Widget _statusTag(bool completed) {
    final color = completed ? AppColors.green : AppColors.purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(completed ? 'COMPLETE' : 'ACTIVE',
          style: monoStyle(size: 10, color: color, spacing: 2)),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Container(
          decoration: panelDecoration(),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontFamily: kMono,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBright)),
              const SizedBox(height: 4),
              Text(label, style: monoStyle(size: 10, spacing: 2)),
            ],
          ),
        ),
      );

  Widget _bar(double pct, List<Color> colors) => ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Container(
          height: 4,
          color: Colors.white.withValues(alpha: 0.06),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
              ),
            ),
          ),
        ),
      );
}
