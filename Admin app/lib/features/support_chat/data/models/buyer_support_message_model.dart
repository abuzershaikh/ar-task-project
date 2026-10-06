class BuyerSupportMessageModel {
  final String id;
  final String conversationId;
  final String buyerId;
  final String senderType; // 'BUYER' | 'ADMIN'
  final String messageType; // 'TEXT' | 'IMAGE' | 'AUDIO' | 'YOUTUBE'
  final String content;
  final String? mediaUrl;
  final String? youtubeId;
  final int durationSeconds;
  final bool isRead;
  final DateTime createdAt;

  const BuyerSupportMessageModel({
    required this.id,
    required this.conversationId,
    required this.buyerId,
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
  bool get isBuyer => senderType == 'BUYER';
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

  /// Formatted in 12-hour Indian Standard Time (IST, e.g. "07:22 PM")
  String get formattedIstTime {
    final ist = istTime;
    final hour = ist.hour;
    final minute = ist.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final hourStr = displayHour.toString().padLeft(2, '0');
    return '$hourStr:$minute $period';
  }

  static DateTime parseServerDateTime(dynamic val) {
    if (val == null) return DateTime.now().toUtc();
    if (val is DateTime) return val.toUtc();
    final str = val.toString().trim();
    if (str.isEmpty) return DateTime.now().toUtc();

    DateTime? parsed = DateTime.tryParse(str);
    if (parsed == null) {
      try {
        final normalized = str.replaceAll(' ', 'T');
        parsed = DateTime.tryParse(normalized);
      } catch (_) {}
    }

    if (parsed != null) {
      if (!str.endsWith('Z') && !str.contains('+') && !str.contains('-')) {
        return DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
      }
      return parsed.toUtc();
    }
    return DateTime.now().toUtc();
  }

  factory BuyerSupportMessageModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawCreated = json['created_at'] ?? json['createdAt'];
    return BuyerSupportMessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? json['conversationId']?.toString() ?? '',
      buyerId: json['buyer_id']?.toString() ?? json['buyerId']?.toString() ?? '',
      senderType: json['sender_type']?.toString().toUpperCase() ?? json['senderType']?.toString().toUpperCase() ?? 'ADMIN',
      messageType: json['message_type']?.toString().toUpperCase() ?? json['messageType']?.toString().toUpperCase() ?? 'TEXT',
      content: json['content']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? json['mediaUrl']?.toString(),
      youtubeId: json['youtube_id']?.toString() ?? json['youtubeId']?.toString(),
      durationSeconds: int.tryParse(json['duration_seconds']?.toString() ?? json['durationSeconds']?.toString() ?? '0') ?? 0,
      isRead: json['is_read'] == 1 || json['is_read'] == true || json['isRead'] == 1 || json['isRead'] == true,
      createdAt: parseServerDateTime(rawCreated),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'buyer_id': buyerId,
    'sender_type': senderType,
    'message_type': messageType,
    'content': content,
    'media_url': mediaUrl,
    'youtube_id': youtubeId,
    'duration_seconds': durationSeconds,
    'is_read': isRead ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  BuyerSupportMessageModel copyWith({
    bool? isRead,
    String? content,
  }) {
    return BuyerSupportMessageModel(
      id: id,
      conversationId: conversationId,
      buyerId: buyerId,
      senderType: senderType,
      messageType: messageType,
      content: content ?? this.content,
      mediaUrl: mediaUrl,
      youtubeId: youtubeId,
      durationSeconds: durationSeconds,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
