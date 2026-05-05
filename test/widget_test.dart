import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:magic_fix/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );

    expect(find.text('Magic Fix'), findsOneWidget);
    expect(find.text('Create New Board'), findsOneWidget);
    expect(find.text('Join Board'), findsOneWidget);
  });
}
