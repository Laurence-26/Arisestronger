import 'package:flutter/material.dart';

import '../theme.dart';

/// The glowing gradient "System" action button used across the app.
class SystemButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool danger;
  final bool ghost;

  const SystemButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.danger = false,
    this.ghost = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || busy;

    if (ghost) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(label,
              style: monoStyle(size: 12, color: AppColors.textDim, spacing: 2)),
        ),
      );
    }

    final gradient = danger
        ? null
        : const LinearGradient(colors: [AppColors.purple, AppColors.blue]);
    final glow = danger ? AppColors.red : AppColors.purple;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          color: danger ? AppColors.red.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(2),
          border: danger
              ? Border.all(color: AppColors.red.withValues(alpha: 0.4))
              : null,
          boxShadow: disabled
              ? null
              : [BoxShadow(color: glow.withValues(alpha: 0.4), blurRadius: 20)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      label,
                      style: TextStyle(
                        fontFamily: kSans,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: danger ? AppColors.red : Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
