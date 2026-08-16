import 'element_category.dart';
import 'element_type.dart';
import 'visibility_context.dart';
import 'editability_mode.dart';
import 'action_type.dart';
import 'condition_rule.dart';

class TemplateElement {
  final String id;
  final String key; // Unique machine name e.g., "youtube_channel_url"
  final String label; // User-facing label e.g., "Paste YouTube Channel Link"
  final ElementCategory category;
  final ElementType type;
  final VisibilityContext visibility;
  final EditabilityMode editability;
  final bool isRequired;
  final Map<String, dynamic> properties; // Custom config (e.g. placeholder, defaultValue, options)
  final ActionType? actionType;
  final ConditionRule? condition;
  final int orderIndex;

  const TemplateElement({
    required this.id,
    required this.key,
    required this.label,
    required this.category,
    required this.type,
    this.visibility = VisibilityContext.both,
    this.editability = EditabilityMode.buyerInput,
    this.isRequired = true,
    this.properties = const {},
    this.actionType,
    this.condition,
    this.orderIndex = 0,
  });

  TemplateElement copyWith({
    String? id,
    String? key,
    String? label,
    ElementCategory? category,
    ElementType? type,
    VisibilityContext? visibility,
    EditabilityMode? editability,
    bool? isRequired,
    Map<String, dynamic>? properties,
    ActionType? actionType,
    ConditionRule? condition,
    int? orderIndex,
  }) {
    return TemplateElement(
      id: id ?? this.id,
      key: key ?? this.key,
      label: label ?? this.label,
      category: category ?? this.category,
      type: type ?? this.type,
      visibility: visibility ?? this.visibility,
      editability: editability ?? this.editability,
      isRequired: isRequired ?? this.isRequired,
      properties: properties ?? this.properties,
      actionType: actionType ?? this.actionType,
      condition: condition ?? this.condition,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'label': label,
      'category': category.name,
      'type': type.name,
      'visibility': visibility.name,
      'editability': editability.name,
      'isRequired': isRequired,
      'properties': properties,
      'actionType': actionType?.name,
      'condition': condition?.toJson(),
      'orderIndex': orderIndex,
    };
  }

  factory TemplateElement.fromJson(Map<String, dynamic> json) {
    int parseI(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return TemplateElement(
      id: json['id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      category: ElementCategory.values.firstWhere(
        (e) => e.name == json['category']?.toString(),
        orElse: () => ElementCategory.content,
      ),
      type: ElementType.values.firstWhere(
        (e) => e.name == json['type']?.toString(),
        orElse: () => ElementType.paragraph,
      ),
      visibility: VisibilityContext.values.firstWhere(
        (e) => e.name == json['visibility']?.toString(),
        orElse: () => VisibilityContext.both,
      ),
      editability: EditabilityMode.values.firstWhere(
        (e) => e.name == json['editability']?.toString(),
        orElse: () => EditabilityMode.buyerInput,
      ),
      isRequired: json['isRequired'] as bool? ?? true,
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      actionType: json['actionType'] != null
          ? ActionType.values.firstWhere((e) => e.name == json['actionType']?.toString(), orElse: () => ActionType.openUrl)
          : null,
      condition: json['condition'] != null
          ? ConditionRule.fromJson(Map<String, dynamic>.from(json['condition']))
          : null,
      orderIndex: parseI(json['orderIndex']),
    );
  }
}
