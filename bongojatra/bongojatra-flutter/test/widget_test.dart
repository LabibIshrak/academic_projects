import 'package:flutter_test/flutter_test.dart';

import 'package:bongojatra_flutter/theme/app_theme.dart';

void main() {
  test('theme uses Bangladesh flag colors', () {
    expect(AppTheme.primary.toARGB32(), 0xFF006A4E);
    expect(AppTheme.secondary.toARGB32(), 0xFFF42A41);
  });
}
