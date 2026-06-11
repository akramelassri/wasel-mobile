import 'package:flutter_test/flutter_test.dart';
import 'package:wasel/main.dart';

void main() {
  testWidgets('App displays Hello World!', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MainApp());

    // Verify "Hello World!" is displayed
    expect(find.text('Hello World!'), findsOneWidget);
  });
}
