import 'package:flutter_test/flutter_test.dart';
import 'package:earnpost/main.dart';

void main() {
  testWidgets('Task Admin app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskAdminApp());
    expect(find.text('Task Admin'), findsWidgets);
  });
}
