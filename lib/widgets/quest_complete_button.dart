import 'package:flutter/material.dart';

import '../theme.dart';

/// Modern primary CTA for finishing today's quest.
class QuestCompleteButton extends StatelessWidget {
  final bool completed;
  final bool enabled;
  final VoidCallback? onPressed;

  const QuestCompleteButton({
    super.key,
    required this.completed,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !completed && onPressed != null;
    final accent = completed ? AppColors.green : AppColors.purple;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: completed || active ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: active || completed
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: active ? onPressed : null,
            borderRadius: BorderRadius.circular(4),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: completed
                    ? LinearGradient(colors: [
                        AppColors.green.withValues(alpha: 0.22),
                        AppColors.cyan.withValues(alpha: 0.12),
                      ])
                    : active
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8B6CFF),
                              AppColors.purple,
                              AppColors.blue,
                            ],
                          )
                        : null,
                color: active || completed ? null : AppColors.bg3,
                border: Border.all(
                  color: completed
                      ? AppColors.green.withValues(alpha: 0.45)
                      : active
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppColors.border,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: (completed ? AppColors.green : AppColors.cyan)
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        completed
                            ? Icons.check_rounded
                            : Icons.bolt_rounded,
                        color: completed ? AppColors.green : Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            completed ? 'QUEST COMPLETE' : 'COMPLETE QUEST',
                            style: TextStyle(
                              fontFamily: kSans,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                              color: completed
                                  ? AppColors.green
                                  : AppColors.textBright,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            completed
                                ? 'Well done, Hunter. Rest and return tomorrow.'
                                : active
                                    ? 'Lock in today\'s progress and keep the streak.'
                                    : 'Check every exercise to unlock this.',
                            style: monoStyle(
                              size: 11,
                              color: completed
                                  ? AppColors.green.withValues(alpha: 0.85)
                                  : AppColors.textDim,
                              spacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      completed
                          ? Icons.verified_rounded
                          : Icons.arrow_forward_rounded,
                      color: completed
                          ? AppColors.green
                          : active
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppColors.textDim,
                      size: 22,
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
