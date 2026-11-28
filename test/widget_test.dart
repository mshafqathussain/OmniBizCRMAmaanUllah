import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnibizcrm/main.dart';

void main() {
  testWidgets('OmniBizCRM application starts', (WidgetTester tester) async {
    await tester.pumpWidget(const OmniBizCRM());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
