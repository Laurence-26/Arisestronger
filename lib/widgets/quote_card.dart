import 'package:flutter/material.dart';

import '../data/quotes.dart';
import '../theme.dart';

/// Daily motivation card — scripture, wisdom, or Solo Leveling fire.
class QuoteCard extends StatelessWidget {
  final Quote quote;
  const QuoteCard({super.key, required this.quote});

  Color get _accent {
    switch (quote.source) {
      case QuoteSource.bible:
        return AppColors.gold;
      case QuoteSource.wisdom:
        return AppColors.cyan;
      case QuoteSource.soloLeveling:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              border: Border(
                  bottom: BorderSide(color: accent.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Text('◈ ${quote.sourceLabel} ◈',
                    style: monoStyle(size: 10, color: accent, spacing: 3)),
                const Spacer(),
                Text('DAILY', style: monoStyle(size: 9, spacing: 2)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${quote.text}"',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBright,
                  ),
                ),
                const SizedBox(height: 10),
                Text('— ${quote.author}',
                    style: monoStyle(size: 12, color: accent, spacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
