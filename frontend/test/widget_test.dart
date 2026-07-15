import 'package:flutter_test/flutter_test.dart';
import 'package:mschool/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the app starts successfully without throwing errors
    expect(find.byType(MyApp), findsOneWidget);
  });
}
