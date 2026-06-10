import 'package:flutter/material.dart';

import '../theme.dart';

/// The "ARISE / STRONGER" wordmark with a neon gradient on STRONGER.
class BrandWordmark extends StatelessWidget {
  final double size;
  final bool center;
  const BrandWordmark({super.key, this.size = 30, this.center = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ARISE',
          style: TextStyle(
            fontSize: size,
            height: 1.0,
            fontWeight: FontWeight.w700,
            letterSpacing: size * 0.18,
            color: AppColors.textBright,
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [AppColors.cyan, AppColors.purple, AppColors.blue],
          ).createShader(rect),
          child: Text(
            'STRONGER',
            style: TextStyle(
              fontSize: size,
              height: 1.0,
              fontWeight: FontWeight.w700,
              letterSpacing: size * 0.18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
