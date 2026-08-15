import 'element_category.dart';
import 'element_type.dart';
import 'visibility_context.dart';
import 'editability_mode.dart';
import 'action_type.dart';

class TemplateElement {
  final String id;
  final String key;
  final String label;
  final ElementCategory category;
  final ElementType type;
  final VisibilityContext visibility;
  final EditabilityMode editability;
  final bool isRequired;
  final ActionType? actionType;
  final int orderIndex;
  final Map<String, dynamic> properties;

  const TemplateElement({
    required this.id,
    required this.key,
    required this.label,
    required this.category,
    required this.type,
    required this.visibility,
    required this.editability,
    this.isRequired = false,
    this.actionType,
    this.orderIndex = 0,
    this.properties = const {},
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
    ActionType? actionType,
    int? orderIndex,
    Map<String, dynamic>? properties,
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
      actionType: actionType ?? this.actionType,
      orderIndex: orderIndex ?? this.orderIndex,
      properties: properties ?? this.properties,
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
      'actionType': actionType?.name,
      'orderIndex': orderIndex,
      'properties': properties,
    };
  }

  factory TemplateElement.fromJson(Map<String, dynamic> json) {
    return TemplateElement(
      id: json['id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      category: ElementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ElementCategory.display,
      ),
      type: ElementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ElementType.paragraph,
      ),
      visibility: VisibilityContext.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => VisibilityContext.both,
      ),
      editability: EditabilityMode.values.firstWhere(
        (e) => e.name == json['editability'],
        orElse: () => EditabilityMode.adminFixed,
      ),
      isRequired: json['isRequired'] as bool? ?? false,
      actionType: json['actionType'] != null
          ? ActionType.values.firstWhere(
              (e) => e.name == json['actionType'],
              orElse: () => ActionType.openUrl,
            )
          : null,
      orderIndex: json['orderIndex'] as int? ?? 0,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }
}
