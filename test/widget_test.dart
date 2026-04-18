import 'package:flutter_test/flutter_test.dart';
import 'package:blissfruitz/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Just verify the app can be instantiated
    expect(const BlissFruitzApp(), isNotNull);
  });
}
