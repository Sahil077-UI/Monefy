import 'package:flutter_test/flutter_test.dart';

import 'package:expense_monitor/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseMonitorApp());
    expect(find.text('Expense Monitor'), findsOneWidget);
  });
}