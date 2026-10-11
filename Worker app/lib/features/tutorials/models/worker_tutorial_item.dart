class WorkerTutorialItem {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? youtubeVideoId;
  final String? thumbnailUrl;
  final String category;
  final String? tags;
  final String? duration;
  final int viewsCount;
  final int displayOrder;
  final DateTime? createdAt;

  WorkerTutorialItem({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.youtubeVideoId,
    this.thumbnailUrl,
    required this.category,
    this.tags,
    this.duration,
    this.viewsCount = 0,
    required this.displayOrder,
    this.createdAt,
  });

  factory WorkerTutorialItem.fromJson(Map<String, dynamic> json) {
    return WorkerTutorialItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      videoUrl: json['videoUrl']?.toString() ??
          json['video_url']?.toString() ??
          '',
      youtubeVideoId: json['youtubeVideoId']?.toString() ??
          json['youtube_video_id']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString() ??
          json['thumbnail_url']?.toString(),
      category: json['category']?.toString() ?? 'General',
      tags: json['tags']?.toString(),
      duration: json['duration']?.toString() ?? '2:30',
      viewsCount: int.tryParse(json['viewsCount']?.toString() ??
              json['views_count']?.toString() ??
              '0') ??
          0,
      displayOrder: int.tryParse(json['displayOrder']?.toString() ??
              json['display_order']?.toString() ??
              '0') ??
          0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  List<String> get tagList {
    if (tags == null || tags!.trim().isEmpty) return [];
    return tags!
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }
}
