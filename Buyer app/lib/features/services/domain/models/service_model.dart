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
  final int minAcceptHours;
  final int maxAcceptHours;
  final int minCompleteHours;
  final int maxCompleteHours;
  final int watchtimeSeconds;
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
    this.minAcceptHours = 1,
    this.maxAcceptHours = 72,
    this.minCompleteHours = 1,
    this.maxCompleteHours = 168,
    this.watchtimeSeconds = 0,
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
    int? minAcceptHours,
    int? maxAcceptHours,
    int? minCompleteHours,
    int? maxCompleteHours,
    int? watchtimeSeconds,
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
      minAcceptHours: minAcceptHours ?? this.minAcceptHours,
      maxAcceptHours: maxAcceptHours ?? this.maxAcceptHours,
      minCompleteHours: minCompleteHours ?? this.minCompleteHours,
      maxCompleteHours: maxCompleteHours ?? this.maxCompleteHours,
      watchtimeSeconds: watchtimeSeconds ?? this.watchtimeSeconds,
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
      'minAcceptHours': minAcceptHours,
      'maxAcceptHours': maxAcceptHours,
      'minCompleteHours': minCompleteHours,
      'maxCompleteHours': maxCompleteHours,
      'watchtimeSeconds': watchtimeSeconds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v, double def) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? def;
      return def;
    }
    int parseI(dynamic v, int def) {
      if (v == null) return def;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    final rawElements = json['elements'] as List<dynamic>?;
    final parsedElements = rawElements != null
        ? rawElements.map((e) => TemplateElement.fromJson(e as Map<String, dynamic>)).toList()
        : <TemplateElement>[];

    final double buyerUnitPrice = parseD(
      json['buyerUnitPrice'] ?? json['pricing']?['buyerUnitPrice'] ?? json['pricing']?['buyerPrice'],
      50.0,
    );

    return ServiceModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isActive: json['isActive'] as bool? ?? true,
      currentVersion: parseI(json['currentVersion'] ?? json['version'], 1),
      pricing: json['pricing'] != null
          ? PricingConfig.fromJson(Map<String, dynamic>.from(json['pricing'] as Map))
          : PricingConfig.calculate(buyerPrice: buyerUnitPrice, adminMarginPercent: 20),
      elements: parsedElements,
      minAcceptHours: parseI(json['minAcceptHours'], 1),
      maxAcceptHours: parseI(json['maxAcceptHours'], 72),
      minCompleteHours: parseI(json['minCompleteHours'], 1),
      maxCompleteHours: parseI(json['maxCompleteHours'], 168),
      watchtimeSeconds: parseI(json['watchtimeSeconds'], 0),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

