import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/theme.dart';

void main() {
  test('theme palette stays offline-system dark', () {
    expect(AppColors.bg, const Color(0xFF07070F));
    expect(AppColors.purple, const Color(0xFF7C5CFC));
  });
}
