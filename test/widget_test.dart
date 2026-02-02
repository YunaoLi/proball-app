// Basic Flutter widget test for Wicked Rolling Ball Pro.

import 'package:flutter_test/flutter_test.dart';
import 'package:proballdev/app/app.dart';

void main() {
  testWidgets('App loads and shows dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const WickedRollingBallApp());

    expect(find.text('Wicked Rolling Ball Pro'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
  });
}
