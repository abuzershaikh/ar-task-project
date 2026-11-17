import 'package:flutter_test/flutter_test.dart';
import 'package:task_reward_app/core/utils/task_execution_deadline.dart';

void main() {
  final accepted = DateTime.utc(2026, 11, 12, 10);
  test('timer is anchored to acceptance and capped at 30 minutes', () {
    final deadline = taskExecutionDeadline({
      'acceptedAt': accepted.toIso8601String(),
      'startedAt': accepted.add(const Duration(minutes: 20)).toIso8601String(),
      'deadline': accepted.add(const Duration(hours: 2)).toIso8601String(),
    })!;
    expect(taskExecutionSecondsRemaining(deadline, accepted), 1800);
    expect(taskExecutionSecondsRemaining(deadline, accepted.add(const Duration(minutes: 20))), 600);
  });
  test('reopening or backgrounding cannot restart the countdown', () {
    final task = {'accepted_at': accepted.toIso8601String()};
    expect(taskExecutionDeadline(task), accepted.add(const Duration(minutes: 30)));
    expect(taskExecutionSecondsRemaining(taskExecutionDeadline(task)!, accepted.add(const Duration(minutes: 30))), 0);
    expect(taskExecutionSecondsRemaining(taskExecutionDeadline(task)!, accepted.add(const Duration(minutes: 31))), 0);
  });
  test('an earlier server deadline is respected', () {
    final early = accepted.add(const Duration(minutes: 15));
    expect(taskExecutionDeadline({'acceptedAt': accepted.toIso8601String(), 'deadline': early.toIso8601String()}), early);
  });
}
