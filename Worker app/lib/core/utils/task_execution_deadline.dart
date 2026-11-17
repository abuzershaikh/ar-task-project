DateTime? taskExecutionDeadline(Map task) {
  DateTime? parse(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());
  final accepted = parse(task['acceptedAt'] ?? task['accepted_at']) ??
      parse(task['startedAt'] ?? task['started_at']) ??
      parse(task['assignedAt'] ?? task['assigned_at']);
  final deadline = parse(task['deadline']);
  final cap = accepted?.add(const Duration(minutes: 30));
  if (deadline == null) return cap;
  if (cap == null) return deadline;
  return deadline.isBefore(cap) ? deadline : cap;
}

int taskExecutionSecondsRemaining(DateTime deadline, DateTime now) {
  final milliseconds = deadline.difference(now).inMilliseconds;
  return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
}
