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
  final int workerLimit; // Default workers to assign for flat rate
  final List<int> workerLimitOptions; // Options for Buyer to choose worker divide (e.g. [5, 10, 20, 25, 50])
  final int watchtimeSeconds;
  final String? videoTutorialUrl;
  final String? audioGuideUrl;
  final String? adminInstructions;
  final String? linkFieldLabel;
  final String? linkFieldPlaceholder;
  final String? textFieldLabel;
  final String? textFieldPlaceholder;
  final List<int>? watchTimeOptions;
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
    this.workerLimit = 10,
    this.workerLimitOptions = const [5, 10, 20, 25, 50],
    this.watchtimeSeconds = 0,
    this.videoTutorialUrl,
    this.audioGuideUrl,
    this.adminInstructions,
    this.linkFieldLabel = 'Target Link / URL',
    this.linkFieldPlaceholder = 'https://...',
    this.textFieldLabel = 'Custom Text / Instructions',
    this.textFieldPlaceholder = 'Enter text, comments or keywords...',
    this.watchTimeOptions,
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
    int? workerLimit,
    List<int>? workerLimitOptions,
    int? watchtimeSeconds,
    String? videoTutorialUrl,
    String? audioGuideUrl,
    String? adminInstructions,
    String? linkFieldLabel,
    String? linkFieldPlaceholder,
    String? textFieldLabel,
    String? textFieldPlaceholder,
    List<int>? watchTimeOptions,
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
      workerLimit: workerLimit ?? this.workerLimit,
      workerLimitOptions: workerLimitOptions ?? this.workerLimitOptions,
      watchtimeSeconds: watchtimeSeconds ?? this.watchtimeSeconds,
      videoTutorialUrl: videoTutorialUrl ?? this.videoTutorialUrl,
      audioGuideUrl: audioGuideUrl ?? this.audioGuideUrl,
      adminInstructions: adminInstructions ?? this.adminInstructions,
      linkFieldLabel: linkFieldLabel ?? this.linkFieldLabel,
      linkFieldPlaceholder: linkFieldPlaceholder ?? this.linkFieldPlaceholder,
      textFieldLabel: textFieldLabel ?? this.textFieldLabel,
      textFieldPlaceholder: textFieldPlaceholder ?? this.textFieldPlaceholder,
      watchTimeOptions: watchTimeOptions ?? this.watchTimeOptions,
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
      'workerLimit': workerLimit,
      'workerLimitOptions': workerLimitOptions,
      'watchtimeSeconds': watchtimeSeconds,
      'videoTutorialUrl': videoTutorialUrl,
      'audioGuideUrl': audioGuideUrl,
      'adminInstructions': adminInstructions,
      'linkFieldLabel': linkFieldLabel,
      'linkFieldPlaceholder': linkFieldPlaceholder,
      'textFieldLabel': textFieldLabel,
      'textFieldPlaceholder': textFieldPlaceholder,
      'watchTimeOptions': watchTimeOptions,
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

    final rawOptions = json['workerLimitOptions'] ?? json['worker_limit_options'];
    List<int> parsedOptions = const [5, 10, 20, 25, 50];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => parseI(e, 10)).where((e) => e > 0).toList();
      if (parsedOptions.isEmpty) parsedOptions = const [5, 10, 20, 25, 50];
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
      workerLimit: parseI(json['workerLimit'] ?? json['worker_limit'], 10),
      workerLimitOptions: parsedOptions,
      watchtimeSeconds: parseI(json['watchtimeSeconds'], 0),
      videoTutorialUrl: json['videoTutorialUrl']?.toString() ?? json['video_tutorial_url']?.toString(),
      audioGuideUrl: json['audioGuideUrl']?.toString() ?? json['audio_guide_url']?.toString(),
      adminInstructions: json['adminInstructions']?.toString() ?? json['admin_instructions']?.toString(),
      linkFieldLabel: json['linkFieldLabel']?.toString() ?? json['link_field_label']?.toString() ?? 'Target Link / URL',
      linkFieldPlaceholder: json['linkFieldPlaceholder']?.toString() ?? json['link_field_placeholder']?.toString() ?? 'https://...',
      textFieldLabel: json['textFieldLabel']?.toString() ?? json['text_field_label']?.toString() ?? 'Custom Text / Instructions',
      textFieldPlaceholder: json['textFieldPlaceholder']?.toString() ?? json['text_field_placeholder']?.toString() ?? 'Enter text, comments or keywords...',
      watchTimeOptions: (json['watchTimeOptions'] ?? json['watch_time_options']) is List
          ? (json['watchTimeOptions'] ?? json['watch_time_options'] as List).map((e) => parseI(e, 0)).toList()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
