import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/shared/widgets/primary_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders label', (tester) async {
    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Hello', onPressed: () {})),
    );
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('fires onPressed on tap when enabled', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Tap me', onPressed: () => tapped++)),
    );
    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });

  testWidgets('disabled when onPressed is null', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(wrap(const PrimaryButton(label: 'Off')));
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(tapped, 0);
  });

  testWidgets('shows CircularProgressIndicator when loading', (tester) async {
    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Saving', loading: true, onPressed: () {})),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Saving'), findsNothing);
  });

  testWidgets('shows icon when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        PrimaryButton(
          label: 'Go',
          icon: Icons.arrow_forward_rounded,
          onPressed: () {},
        ),
      ),
    );
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });
}
