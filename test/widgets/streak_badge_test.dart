import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/shared/widgets/streak_badge.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders singular "1 day"', (tester) async {
    await tester.pumpWidget(wrap(const StreakBadge(days: 1)));
    expect(find.text('1 day'), findsOneWidget);
  });

  testWidgets('renders plural "5 days"', (tester) async {
    await tester.pumpWidget(wrap(const StreakBadge(days: 5)));
    expect(find.text('5 days'), findsOneWidget);
  });

  testWidgets('renders zero correctly', (tester) async {
    await tester.pumpWidget(wrap(const StreakBadge(days: 0)));
    expect(find.text('0 days'), findsOneWidget);
  });

  testWidgets('includes fire icon', (tester) async {
    await tester.pumpWidget(wrap(const StreakBadge(days: 7)));
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
  });

  testWidgets('compact mode renders smaller icon', (tester) async {
    await tester.pumpWidget(wrap(const StreakBadge(days: 3, compact: true)));
    final icon = tester.widget<Icon>(
        find.byIcon(Icons.local_fire_department_rounded));
    expect(icon.size, 18);
  });
}
