import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:letmesendu/main.dart';

void main() {
  testWidgets('LetMeSendU app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const LetMeSendUApp());

    // Verify the app title is shown
    expect(find.text('LetMeSendU'), findsOneWidget);
  });
}
