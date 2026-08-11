import 'package:flutter_test/flutter_test.dart';
import 'package:task_reward_app/main.dart';

void main() {
  testWidgets('TaskRewardApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TaskRewardApp());
    expect(find.byType(TaskRewardApp), findsOneWidget);
  });
}
