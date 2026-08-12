import 'pricing_config.dart';
import 'template_element.dart';

class ServiceModel {
  final String id;
  final String code; // Immutable uppercase identifier e.g. YT_SUB, TELEGRAM_JOIN
  final String name;
  final String description;
  final String icon;
  final bool isActive;
  final int currentVersion;
  final PricingConfig pricing;
  final List<TemplateElement> elements;
  final int minDurationSeconds;
  final int maxDurationSeconds;
  final bool requiresProofScreenshot;
  final bool requiresProofText;
  final String reviewMode; // 'AUTOMATIC' or 'MANUAL'
  final DateTime updatedAt;

  const ServiceModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    this.icon = 'stars_rounded',
    this.isActive = true,
    this.currentVersion = 1,
    required this.pricing,
    required this.elements,
    this.minDurationSeconds = 60,
    this.maxDurationSeconds = 86400,
    this.requiresProofScreenshot = true,
    this.requiresProofText = false,
    this.reviewMode = 'MANUAL',
    required this.updatedAt,
  });

  ServiceModel copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    String? icon,
    bool? isActive,
    int? currentVersion,
    PricingConfig? pricing,
    List<TemplateElement>? elements,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    bool? requiresProofScreenshot,
    bool? requiresProofText,
    String? reviewMode,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      currentVersion: currentVersion ?? this.currentVersion,
      pricing: pricing ?? this.pricing,
      elements: elements ?? this.elements,
      minDurationSeconds: minDurationSeconds ?? this.minDurationSeconds,
      maxDurationSeconds: maxDurationSeconds ?? this.maxDurationSeconds,
      requiresProofScreenshot: requiresProofScreenshot ?? this.requiresProofScreenshot,
      requiresProofText: requiresProofText ?? this.requiresProofText,
      reviewMode: reviewMode ?? this.reviewMode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'icon': icon,
      'isActive': isActive,
      'currentVersion': currentVersion,
      'pricing': pricing.toJson(),
      'elements': elements.map((e) => e.toJson()).toList(),
      'minDurationSeconds': minDurationSeconds,
      'maxDurationSeconds': maxDurationSeconds,
      'requiresProofScreenshot': requiresProofScreenshot,
      'requiresProofText': requiresProofText,
      'reviewMode': reviewMode,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'stars_rounded',
      isActive: json['isActive'] ?? true,
      currentVersion: json['currentVersion'] ?? 1,
      pricing: PricingConfig.fromJson(Map<String, dynamic>.from(json['pricing'] ?? {})),
      elements: (json['elements'] as List? ?? [])
          .map((e) => TemplateElement.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      minDurationSeconds: json['minDurationSeconds'] ?? 60,
      maxDurationSeconds: json['maxDurationSeconds'] ?? 86400,
      requiresProofScreenshot: json['requiresProofScreenshot'] ?? true,
      requiresProofText: json['requiresProofText'] ?? false,
      reviewMode: json['reviewMode'] ?? 'MANUAL',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
