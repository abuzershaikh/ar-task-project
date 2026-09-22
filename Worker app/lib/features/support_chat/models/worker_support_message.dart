class WorkerSupportMessage {
  final String id;
  final String conversationId;
  final String workerId;
  final String senderType; // 'WORKER' | 'ADMIN'
  final String messageType; // 'TEXT' | 'IMAGE' | 'AUDIO' | 'YOUTUBE'
  final String content;
  final String? mediaUrl;
  final String? youtubeId;
  final int durationSeconds;
  final bool isRead;
  final DateTime createdAt;

  const WorkerSupportMessage({
    required this.id,
    required this.conversationId,
    required this.workerId,
    required this.senderType,
    required this.messageType,
    required this.content,
    this.mediaUrl,
    this.youtubeId,
    this.durationSeconds = 0,
    required this.isRead,
    required this.createdAt,
  });

  bool get isAdmin => senderType == 'ADMIN';
  bool get isWorker => senderType == 'WORKER';
  bool get isYoutube => messageType == 'YOUTUBE' || youtubeId != null;
  bool get isAudio => messageType == 'AUDIO';
  bool get isImage => messageType == 'IMAGE';

  String? get youtubeThumbnailUrl {
    if (youtubeId != null && youtubeId!.isNotEmpty) {
      return 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
    }
    return null;
  }

  /// Indian Standard Time (IST = UTC + 05:30)
  DateTime get istTime {
    final utc = createdAt.toUtc();
    return utc.add(const Duration(hours: 5, minutes: 30));
  }

  /// Returns the message time formatted in 12-hour Indian Standard Time (IST, e.g. "07:22 PM")
  String get formattedIstTime {
    final ist = istTime;
    final hour = ist.hour;
    final minute = ist.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final hourStr = displayHour.toString().padLeft(2, '0');
    return '$hourStr:$minute $period';
  }

  /// Safely parses server timestamps into UTC DateTime
  static DateTime parseServerDateTime(dynamic val) {
    if (val == null) return DateTime.now().toUtc();
    if (val is DateTime) return val.toUtc();
    String s = val.toString().trim();
    if (s.isEmpty) return DateTime.now().toUtc();

    try {
      s = s.replaceAll(' ', 'T');
      // If no timezone indicator (+, -, or Z), append 'Z' so it is treated as UTC
      if (!s.endsWith('Z') && !RegExp(r'[+-]\d{2}(:\d{2})?$').hasMatch(s)) {
        s = '${s}Z';
      }
      final dt = DateTime.tryParse(s);
      if (dt != null) {
        return dt.toUtc();
      }
    } catch (_) {}
    return DateTime.now().toUtc();
  }

  factory WorkerSupportMessage.fromJson(Map<String, dynamic> json) {
    return WorkerSupportMessage(
      id: json['id']?.toString() ?? '',
      conversationId: (json['conversation_id'] ?? json['conversationId'])?.toString() ?? '',
      workerId: (json['worker_id'] ?? json['workerId'])?.toString() ?? '',
      senderType: (json['sender_type'] ?? json['senderType'])?.toString().toUpperCase() ?? 'ADMIN',
      messageType: (json['message_type'] ?? json['messageType'])?.toString().toUpperCase() ?? 'TEXT',
      content: json['content']?.toString() ?? '',
      mediaUrl: (json['media_url'] ?? json['mediaUrl'])?.toString(),
      youtubeId: (json['youtube_id'] ?? json['youtubeId'])?.toString(),
      durationSeconds: int.tryParse((json['duration_seconds'] ?? json['durationSeconds'])?.toString() ?? '0') ?? 0,
      isRead: json['is_read'] == 1 || json['is_read'] == true || json['is_read'] == '1' ||
          json['isRead'] == 1 || json['isRead'] == true,
      createdAt: parseServerDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'conversationId': conversationId,
      'worker_id': workerId,
      'workerId': workerId,
      'sender_type': senderType,
      'senderType': senderType,
      'message_type': messageType,
      'messageType': messageType,
      'content': content,
      'media_url': mediaUrl,
      'mediaUrl': mediaUrl,
      'youtube_id': youtubeId,
      'youtubeId': youtubeId,
      'duration_seconds': durationSeconds,
      'durationSeconds': durationSeconds,
      'is_read': isRead,
      'isRead': isRead,
      'created_at': createdAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
