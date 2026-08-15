import 'pricing_config.dart';
import 'template_element.dart';

class ServiceModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final bool isActive;
  final int currentVersion;
  final PricingConfig pricing;
  final List<TemplateElement> elements;
  final DateTime updatedAt;

  const ServiceModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.isActive,
    required this.currentVersion,
    required this.pricing,
    required this.elements,
    required this.updatedAt,
  });

  ServiceModel copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    bool? isActive,
    int? currentVersion,
    PricingConfig? pricing,
    List<TemplateElement>? elements,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      currentVersion: currentVersion ?? this.currentVersion,
      pricing: pricing ?? this.pricing,
      elements: elements ?? this.elements,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'isActive': isActive,
      'currentVersion': currentVersion,
      'pricing': pricing.toJson(),
      'elements': elements.map((e) => e.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawElements = json['elements'] as List<dynamic>?;
    final parsedElements = rawElements != null
        ? rawElements.map((e) => TemplateElement.fromJson(e as Map<String, dynamic>)).toList()
        : <TemplateElement>[];

    final double buyerUnitPrice = (json['buyerUnitPrice'] as num?)?.toDouble() ??
        ((json['pricing']?['buyerUnitPrice'] ?? json['pricing']?['buyerPrice'] as num?)?.toDouble() ?? 50.0);

    return ServiceModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isActive: json['isActive'] as bool? ?? true,
      currentVersion: (json['currentVersion'] as num?)?.toInt() ?? 1,
      pricing: json['pricing'] != null
          ? PricingConfig.fromJson(json['pricing'] as Map<String, dynamic>)
          : PricingConfig.calculate(buyerPrice: buyerUnitPrice, adminMarginPercent: 20),
      elements: parsedElements,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

