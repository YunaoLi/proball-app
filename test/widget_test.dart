// Basic Flutter widget test for Wicked Rolling Ball Pro.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proballdev/app/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(WickedRollingBallApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('Wicked Rolling Ball Pro'), findsWidgets);
  });
}
