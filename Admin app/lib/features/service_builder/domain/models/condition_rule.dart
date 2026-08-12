class ConditionRule {
  final String targetFieldKey;
  final String operator; // equals, notEquals, contains, isNotEmpty
  final dynamic expectedValue;

  const ConditionRule({
    required this.targetFieldKey,
    required this.operator,
    required this.expectedValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'targetFieldKey': targetFieldKey,
      'operator': operator,
      'expectedValue': expectedValue,
    };
  }

  factory ConditionRule.fromJson(Map<String, dynamic> json) {
    return ConditionRule(
      targetFieldKey: json['targetFieldKey'] ?? '',
      operator: json['operator'] ?? 'equals',
      expectedValue: json['expectedValue'],
    );
  }
}
