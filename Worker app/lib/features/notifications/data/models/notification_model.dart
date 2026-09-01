class WorkerNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? data;

  WorkerNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.entityType,
    this.entityId,
    this.data,
  });

  factory WorkerNotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      if (json['createdAt'] != null) {
        if (json['createdAt'] is String) {
          parsedDate = DateTime.parse(json['createdAt']);
        } else if (json['createdAt'] is Map && json['createdAt']['_seconds'] != null) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(
              json['createdAt']['_seconds'] * 1000);
        } else {
          parsedDate = DateTime.now();
        }
      } else if (json['created_at'] != null) {
        parsedDate = DateTime.parse(json['created_at'].toString());
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return WorkerNotificationModel(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      isRead: json['isRead'] == true || json['is_read'] == true,
      createdAt: parsedDate,
      entityType: json['entityType']?.toString() ?? json['entity_type']?.toString(),
      entityId: json['entityId']?.toString() ?? json['entity_id']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : (json['data'] is String ? {} : null),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

class UniqueKey {
  static int _c = 0;
  @override
  String toString() => 'notif_${DateTime.now().millisecondsSinceEpoch}_${++_c}';
}
