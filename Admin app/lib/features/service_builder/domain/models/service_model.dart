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
      'minAcceptHours': minAcceptHours,
      'maxAcceptHours': maxAcceptHours,
      'minCompleteHours': minCompleteHours,
      'maxCompleteHours': maxCompleteHours,
      'watchtimeSeconds': watchtimeSeconds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    int parseI(dynamic v, int def) {
      if (v == null) return def;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    return ServiceModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'stars_rounded',
      isActive: json['isActive'] as bool? ?? true,
      currentVersion: parseI(json['currentVersion'] ?? json['version'], 1),
      pricing: PricingConfig.fromJson(Map<String, dynamic>.from(json['pricing'] ?? json['activePricing'] ?? {})),
      elements: (json['elements'] as List? ?? [])
          .map((e) => TemplateElement.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      minDurationSeconds: parseI(json['minDurationSeconds'], 60),
      maxDurationSeconds: parseI(json['maxDurationSeconds'], 86400),
      requiresProofScreenshot: json['requiresProofScreenshot'] as bool? ?? true,
      requiresProofText: json['requiresProofText'] as bool? ?? false,
      reviewMode: json['reviewMode']?.toString() ?? 'MANUAL',
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
