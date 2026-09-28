import 'package:flutter/material.dart';

import '../theme.dart';

/// Gold-accent CTA for clearing the weekly Gate raid.
class GateClearButton extends StatelessWidget {
  final bool cleared;
  final bool enabled;
  final VoidCallback? onPressed;

  const GateClearButton({
    super.key,
    required this.cleared,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !cleared && onPressed != null;
    final accent = cleared ? AppColors.gold : AppColors.gold;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: cleared || active ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: active || cleared
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
                gradient: cleared
                    ? LinearGradient(colors: [
                        AppColors.gold.withValues(alpha: 0.22),
                        AppColors.cyan.withValues(alpha: 0.1),
                      ])
                    : active
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF0B429),
                              Color(0xFFE8A317),
                              AppColors.cyan,
                            ],
                          )
                        : null,
                color: active || cleared ? null : AppColors.bg3,
                border: Border.all(
                  color: cleared
                      ? AppColors.gold.withValues(alpha: 0.45)
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
                          color: AppColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        cleared
                            ? Icons.verified_rounded
                            : Icons.shield_moon_outlined,
                        color: cleared ? AppColors.gold : Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cleared ? 'GATE CLEARED' : 'CLEAR GATE',
                            style: TextStyle(
                              fontFamily: kSans,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                              color: cleared
                                  ? AppColors.gold
                                  : AppColors.textBright,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cleared
                                ? 'Raid sealed for this week. Arise, Hunter.'
                                : active
                                    ? 'Finish the raid. Optional — skip freely.'
                                    : 'Complete today\'s quest, then every Gate set.',
                            style: monoStyle(
                              size: 11,
                              color: cleared
                                  ? AppColors.gold.withValues(alpha: 0.85)
                                  : AppColors.textDim,
                              spacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      cleared
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward_rounded,
                      color: cleared
                          ? AppColors.gold
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
