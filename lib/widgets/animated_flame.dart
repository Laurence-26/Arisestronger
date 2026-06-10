import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A living flame for the streak banner — gently breathes (scale + flicker)
/// with a warm glow so an active streak always feels alive and worth keeping.
class AnimatedFlame extends StatefulWidget {
  final double size;
  final bool active;
  const AnimatedFlame({super.key, this.size = 30, this.active = true});

  @override
  State<AnimatedFlame> createState() => _AnimatedFlameState();
}

class _AnimatedFlameState extends State<AnimatedFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AnimatedFlame old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Text('✦',
          style: TextStyle(fontSize: widget.size, color: AppColors.purple));
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Eased breathing plus a tiny higher-frequency flicker.
        final t = Curves.easeInOut.transform(_c.value);
        final flicker = math.sin(_c.value * math.pi * 6) * 0.02;
        final scale = 0.92 + t * 0.16 + flicker;
        final glow = 8 + t * 16;
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.35 + t * 0.35),
                  blurRadius: glow,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.red.withValues(alpha: 0.18 + t * 0.18),
                  blurRadius: glow * 1.6,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Text('🔥', style: TextStyle(fontSize: widget.size)),
    );
  }
}
