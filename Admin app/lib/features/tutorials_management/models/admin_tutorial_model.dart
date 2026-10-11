class AdminTutorialModel {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? youtubeVideoId;
  final String? thumbnailUrl;
  final String category;
  final String? tags;
  final String targetAudience; // 'buyer', 'worker', 'all'
  final int displayOrder;
  final String? duration;
  final int viewsCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminTutorialModel({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.youtubeVideoId,
    this.thumbnailUrl,
    required this.category,
    this.tags,
    required this.targetAudience,
    required this.displayOrder,
    this.duration,
    this.viewsCount = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminTutorialModel.fromJson(Map<String, dynamic> json) {
    return AdminTutorialModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      videoUrl: json['videoUrl']?.toString() ?? json['video_url']?.toString() ?? '',
      youtubeVideoId: json['youtubeVideoId']?.toString() ?? json['youtube_video_id']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? json['thumbnail_url']?.toString(),
      category: json['category']?.toString() ?? 'General',
      tags: json['tags']?.toString(),
      targetAudience: json['targetAudience']?.toString() ?? json['target_audience']?.toString() ?? 'buyer',
      displayOrder: int.tryParse(json['displayOrder']?.toString() ?? json['display_order']?.toString() ?? '0') ?? 0,
      duration: json['duration']?.toString() ?? '2:30',
      viewsCount: int.tryParse(json['viewsCount']?.toString() ?? json['views_count']?.toString() ?? '0') ?? 0,
      isActive: json['isActive'] == true || json['is_active'] == 1 || json['isActive'] == 1 || json['isActive'] == 'true',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'youtubeVideoId': youtubeVideoId,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'tags': tags,
      'targetAudience': targetAudience,
      'displayOrder': displayOrder,
      'duration': duration,
      'viewsCount': viewsCount,
      'isActive': isActive,
    };
  }

  List<String> get tagList {
    if (tags == null || tags!.trim().isEmpty) return [];
    return tags!
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  AdminTutorialModel copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? youtubeVideoId,
    String? thumbnailUrl,
    String? category,
    String? tags,
    String? targetAudience,
    int? displayOrder,
    String? duration,
    int? viewsCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminTutorialModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      targetAudience: targetAudience ?? this.targetAudience,
      displayOrder: displayOrder ?? this.displayOrder,
      duration: duration ?? this.duration,
      viewsCount: viewsCount ?? this.viewsCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
