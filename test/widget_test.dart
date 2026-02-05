import 'package:flutter_test/flutter_test.dart';
import 'package:KOW/landing.dart';

void main() {
  testWidgets('App loads background screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Check title exists
  expect(find.text('KARUNUNGAN\nON WHEELS'), findsOneWidget);

    // Check tap text exists
    expect(find.text('Tap anywhere to start'), findsOneWidget);
  });
}
  