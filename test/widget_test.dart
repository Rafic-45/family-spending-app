import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_spend/format.dart';
import 'package:family_spend/services/auth_service.dart';

void main() {
  group('AuthService.emailForName', () {
    test('slugifies a simple name', () {
      expect(AuthService.emailForName('Karim'), 'karim@familyspend.local');
    });

    test('collapses spaces and strips symbols', () {
      expect(
        AuthService.emailForName('  Rafic  Hariri!! '),
        'rafic.hariri@familyspend.local',
      );
    });

    test('falls back for empty-ish input', () {
      expect(AuthService.emailForName('   '), 'member@familyspend.local');
    });
  });

  group('formatting', () {
    test('amount has a currency symbol and two decimals', () {
      expect(formatAmount(45), r'$45.00');
      expect(formatAmount(100.5), r'$100.50');
    });

    test('date is short month + day', () {
      expect(formatDate(DateTime(2026, 9, 18)), 'Sep 18');
      expect(formatDateFull(DateTime(2026, 9, 18)), 'Sep 18, 2026');
    });
  });

  testWidgets('renders a trivial widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('ok'))),
    );
    expect(find.text('ok'), findsOneWidget);
  });
}
