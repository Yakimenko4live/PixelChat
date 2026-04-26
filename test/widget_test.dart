import 'package:flutter_test/flutter_test.dart';
import 'package:client/main.dart';

void main() {
  testWidgets('PixelChat app displays auth screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PixelChatApp());
    expect(find.text('PixelChat'), findsOneWidget);
  });
}
