import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/level.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/overlays.dart';

/// The PROGRESS tab — streak, totals, rank progress, and 28-day history.
class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lv = s.level;
    final isMax = s.levelIndex == kLevels.length - 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('◈ HUNTER PROGRESS ◈',
                style: monoStyle(size: 11, color: AppColors.purple, spacing: 4)),
            const SizedBox(height: 14),

            // Stat grid
            Row(
              children: [
                _stat('${s.profile.streak}', 'STREAK', AppColors.gold),
                const SizedBox(width: 8),
                _stat('${s.profile.totalDays}', 'TOTAL DAYS', AppColors.purple),
                const SizedBox(width: 8),
                _stat('${s.levelIndex + 1}', 'LEVEL', AppColors.cyan),
              ],
            ),
            const SizedBox(height: 14),

            // Rank progress card
            Container(
              decoration: panelDecoration(),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: lv.color.withValues(alpha: 0.12),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: lv.color)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lv.name,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textBright)),
                            Text(
                              isMax
                                  ? '▸ MAXIMUM RANK ACHIEVED'
                                  : '▸ ${s.daysToNextLevel} days to ${kLevels[s.levelIndex + 1].rank}-Rank',
                              style: monoStyle(
                                  size: 11, color: AppColors.purple, spacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('RANK PROGRESS', style: monoStyle(size: 11)),
                      const Spacer(),
                      Text('${(s.levelProgress * 100).round()}%',
                          style: monoStyle(size: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: Container(
                      height: 6,
                      color: Colors.white.withValues(alpha: 0.06),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: s.levelProgress,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [AppColors.purple, AppColors.blue]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // History
            Container(
              decoration: panelDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.06),
                      border: const Border(
                          bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Text('◈ QUEST HISTORY',
                            style: monoStyle(
                                size: 11,
                                color: AppColors.purple,
                                spacing: 4)),
                        const Spacer(),
                        Text('LAST 28 DAYS', style: monoStyle(size: 9)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: HistoryDots(
                        history: s.history, penalties: s.penalties),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _legend(AppColors.purple, 'Complete'),
                        _legend(AppColors.red, 'Penalty'),
                        _legend(
                            AppColors.red.withValues(alpha: 0.2), 'Missed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Container(
          decoration: panelDecoration(),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontFamily: kMono,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(height: 4),
              Text(label, style: monoStyle(size: 9, spacing: 1)),
            ],
          ),
        ),
      );

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: monoStyle(size: 10)),
        ],
      );
}
