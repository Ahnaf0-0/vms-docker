import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/registration/presentation/visitor_registration_screen.dart';
import 'package:flutter_app/core/theme/glass_theme.dart';

void main() {
  testWidgets('VisitorRegistrationScreen renders correctly and shows validation', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: VisitorRegistrationScreen(),
    ));

    // Verify GlassContainer is present
    expect(find.byType(GlassContainer), findsOneWidget);

    // Verify TextFields are present (7 fields now)
    expect(find.text('Visitor Registration'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(7));

    // Tap the Next button without filling fields
    await tester.ensureVisible(find.text('Next: Face Setup'));
    await tester.tap(find.text('Next: Face Setup'));
    await tester.pump();

    // Verify validation messages
    // Full Name, Phone, NID are 'Required' (3 total)
    expect(find.text('Required'), findsNWidgets(3));
    expect(find.text('Invalid email'), findsOneWidget);
    expect(find.text('Too short'), findsOneWidget);
  });
}
