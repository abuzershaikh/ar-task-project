import 'pricing_config.dart';
import 'template_element.dart';

class ServiceModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final String category;
  final String serviceType;
  final bool isActive;
  final bool aiGeneratorEnabled;
  final Map<String, dynamic>? aiGeneratorConfig;
  final int currentVersion;
  final PricingConfig pricing;
  final List<TemplateElement> elements;
  final int minAcceptHours;
  final int maxAcceptHours;
  final int minCompleteHours;
  final int maxCompleteHours;
  final int workerLimit;
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
    this.category = 'YouTube',
    this.serviceType = 'like',
    required this.isActive,
    this.aiGeneratorEnabled = false,
    this.aiGeneratorConfig,
    required this.currentVersion,
    required this.pricing,
    required this.elements,
    this.minAcceptHours = 1,
    this.maxAcceptHours = 72,
    this.minCompleteHours = 1,
    this.maxCompleteHours = 168,
    this.workerLimit = 1,
    this.watchtimeSeconds = 0,
    this.videoTutorialUrl,
    this.audioGuideUrl,
    this.adminInstructions,
    this.linkFieldLabel = 'Target Link / URL',
    this.linkFieldPlaceholder = 'https://...',
    this.textFieldLabel = 'Custom Text / Instructions',
    this.textFieldPlaceholder = 'Enter comments, text, or instructions...',
    this.watchTimeOptions,
    required this.updatedAt,
  });

  ServiceModel copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    String? category,
    String? serviceType,
    bool? isActive,
    bool? aiGeneratorEnabled,
    Map<String, dynamic>? aiGeneratorConfig,
    int? currentVersion,
    PricingConfig? pricing,
    List<TemplateElement>? elements,
    int? minAcceptHours,
    int? maxAcceptHours,
    int? minCompleteHours,
    int? maxCompleteHours,
    int? workerLimit,
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
      category: category ?? this.category,
      serviceType: serviceType ?? this.serviceType,
      isActive: isActive ?? this.isActive,
      aiGeneratorEnabled: aiGeneratorEnabled ?? this.aiGeneratorEnabled,
      aiGeneratorConfig: aiGeneratorConfig ?? this.aiGeneratorConfig,
      currentVersion: currentVersion ?? this.currentVersion,
      pricing: pricing ?? this.pricing,
      elements: elements ?? this.elements,
      minAcceptHours: minAcceptHours ?? this.minAcceptHours,
      maxAcceptHours: maxAcceptHours ?? this.maxAcceptHours,
      minCompleteHours: minCompleteHours ?? this.minCompleteHours,
      maxCompleteHours: maxCompleteHours ?? this.maxCompleteHours,
      workerLimit: workerLimit ?? this.workerLimit,
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
      'category': category,
      'serviceType': serviceType,
      'isActive': isActive,
      'aiGeneratorEnabled': aiGeneratorEnabled,
      'aiGeneratorConfig': aiGeneratorConfig,
      'currentVersion': currentVersion,
      'pricing': pricing.toJson(),
      'elements': elements.map((e) => e.toJson()).toList(),
      'minAcceptHours': minAcceptHours,
      'maxAcceptHours': maxAcceptHours,
      'minCompleteHours': minCompleteHours,
      'maxCompleteHours': maxCompleteHours,
      'workerLimit': workerLimit,
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
      5.0,
    );

    final rawAiConfig = json['aiGeneratorConfig'] ?? json['ai_generator_config'];
    Map<String, dynamic>? parsedAiConfig;
    if (rawAiConfig is Map) {
      parsedAiConfig = Map<String, dynamic>.from(rawAiConfig);
    }

    final String codeStr = (json['code'] ?? '').toString().toUpperCase();
    final String nameStr = (json['name'] ?? json['title'] ?? '').toString().toUpperCase();
    final String descStr = (json['description'] ?? '').toString().toUpperCase();
    final String typeStr = (json['serviceType'] ?? json['service_type'] ?? '').toString().toUpperCase();

    final bool aiEnabled = (json['aiGeneratorEnabled'] ?? json['ai_generator_enabled']) as bool? ??
        (codeStr.contains('COMMENT') ||
         codeStr.contains('COMBO') ||
         codeStr.contains('REVIEW') ||
         nameStr.contains('COMMENT') ||
         nameStr.contains('COMBO') ||
         nameStr.contains('REVIEW') ||
         descStr.contains('COMMENT') ||
         typeStr.contains('COMMENT') ||
         typeStr.contains('COMBO'));

    String derivedCategory = json['category']?.toString() ?? 'YouTube';
    final codeUpper = (json['code'] ?? '').toString().toUpperCase();
    if (codeUpper.startsWith('YOUTUBE') || codeUpper.startsWith('YT')) {
      derivedCategory = 'YouTube';
    } else if (codeUpper.startsWith('TELEGRAM') || codeUpper.startsWith('TG')) {
      derivedCategory = 'Telegram';
    } else if (codeUpper.startsWith('INSTA')) {
      derivedCategory = 'Instagram';
    } else if (codeUpper.startsWith('APP')) {
      derivedCategory = 'App Install & Review';
    }

    return ServiceModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: derivedCategory,
      serviceType: (json['serviceType'] ?? json['service_type'] ?? 'general').toString(),
      isActive: json['isActive'] as bool? ?? true,
      aiGeneratorEnabled: aiEnabled,
      aiGeneratorConfig: parsedAiConfig,
      currentVersion: parseI(json['currentVersion'] ?? json['version'], 1),
      pricing: json['pricing'] != null
          ? PricingConfig.fromJson(Map<String, dynamic>.from(json['pricing'] as Map))
          : PricingConfig.calculate(buyerPrice: buyerUnitPrice, adminMarginPercent: 20),
      elements: parsedElements,
      minAcceptHours: parseI(json['minAcceptHours'] ?? json['min_accept_hours'], 1),
      maxAcceptHours: parseI(json['maxAcceptHours'] ?? json['max_accept_hours'], 72),
      minCompleteHours: parseI(json['minCompleteHours'] ?? json['min_complete_hours'], 24),
      maxCompleteHours: parseI(json['maxCompleteHours'] ?? json['max_complete_hours'], 168),
      workerLimit: parseI(json['workerLimit'] ?? json['worker_limit'], 1),
      watchtimeSeconds: parseI(json['watchtimeSeconds'] ?? json['watchtime_seconds'], 0),
      videoTutorialUrl: json['videoTutorialUrl']?.toString() ?? json['video_tutorial_url']?.toString(),
      audioGuideUrl: json['audioGuideUrl']?.toString() ?? json['audio_guide_url']?.toString(),
      adminInstructions: json['adminInstructions']?.toString() ?? json['admin_instructions']?.toString(),
      linkFieldLabel: json['linkFieldLabel']?.toString() ?? json['link_field_label']?.toString() ?? 'Target Link / URL',
      linkFieldPlaceholder: json['linkFieldPlaceholder']?.toString() ?? json['link_field_placeholder']?.toString() ?? 'https://...',
      textFieldLabel: json['textFieldLabel']?.toString() ?? json['text_field_label']?.toString() ?? 'Custom Text / Instructions',
      textFieldPlaceholder: json['textFieldPlaceholder']?.toString() ?? json['text_field_placeholder']?.toString() ?? 'Enter comments, text, or instructions...',
      watchTimeOptions: (json['watchTimeOptions'] ?? json['watch_time_options']) is List
          ? (json['watchTimeOptions'] ?? json['watch_time_options'] as List).map((e) => parseI(e, 0)).toList()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
