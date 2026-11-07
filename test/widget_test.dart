import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:discount_calc/main.dart';

void main() {
  testWidgets('calculates discount and tax', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DiscountApp());
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '200');
    await tester.enterText(fields.at(1), '25');
    await tester.enterText(fields.at(2), '15');
    await tester.pump();
    // 200 - 25% = 150, +15% tax = 172.5
    expect(find.text('150'), findsOneWidget);
    expect(find.text('172.50'), findsOneWidget);
  });
}
