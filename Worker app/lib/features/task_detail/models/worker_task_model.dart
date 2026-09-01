/// WorkerTaskElement - Task instructions and media element model for Worker App
class WorkerTaskElement {
  final String id;
  final String key;
  final String label;
  final String category; // display, input, media, action, system
  final String type; // heading, text, youtube, audio, actionButton, systemProof, systemTimer
  final String? contentValue; // URL / Instruction text / Default value
  final bool isRequired;

  const WorkerTaskElement({
    required this.id,
    required this.key,
    required this.label,
    required this.category,
    required this.type,
    this.contentValue,
    this.isRequired = false,
  });

  factory WorkerTaskElement.fromJson(Map<String, dynamic> json) {
    return WorkerTaskElement(
      id: json['id'] ?? '',
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      category: json['category'] ?? 'display',
      type: json['type'] ?? 'text',
      contentValue: json['contentValue'] ?? json['defaultValue'],
      isRequired: json['isRequired'] ?? false,
    );
  }
}

/// WorkerTaskModel - Available Task Model for Worker App
class WorkerTaskModel {
  final String id;
  final String title;
  final String serviceCode; // YOUTUBE_SUBSCRIBE, INSTAGRAM_FOLLOW, WEBSITE_VISITS, AUDIO_LISTEN
  final String description;
  final double workerReward;
  final int executionTimeSeconds;
  final String status; // AVAILABLE, ACCEPTED, COMPLETED
  final List<WorkerTaskElement> elements;
  final DateTime createdAt;

  const WorkerTaskModel({
    required this.id,
    required this.title,
    required this.serviceCode,
    required this.description,
    required this.workerReward,
    required this.executionTimeSeconds,
    required this.status,
    required this.elements,
    required this.createdAt,
  });

  factory WorkerTaskModel.fromJson(Map<String, dynamic> json) {
    return WorkerTaskModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? json['name'] ?? 'Task',
      serviceCode: json['serviceCode'] ?? json['serviceType'] ?? 'GENERAL',
      description: json['description'] ?? '',
      workerReward: (json['workerReward'] ?? json['rewardPerTask'] ?? json['reward'] ?? 15.0).toDouble(),
      executionTimeSeconds: json['executionTimeSeconds'] ?? 60,
      status: json['status'] ?? 'AVAILABLE',
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) => WorkerTaskElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
