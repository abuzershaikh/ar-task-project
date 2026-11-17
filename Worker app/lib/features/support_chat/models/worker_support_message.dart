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

  static bool _isAudioUrl(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final url = extractFirstUrl(text) ?? text.trim();
    final lower = url.split('?').first.split('#').first.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.opus') ||
        lower.endsWith('.webm') ||
        lower.contains('/voice_') ||
        lower.contains('/audio_');
  }

  static bool _isImageUrl(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final url = extractFirstUrl(text) ?? text.trim();
    final lower = url.split('?').first.split('#').first.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  bool get isAdmin => senderType == 'ADMIN';
  bool get isWorker => senderType == 'WORKER';
  bool get isAudio =>
      messageType == 'AUDIO' ||
      messageType == 'VOICE' ||
      _isAudioUrl(mediaUrl) ||
      _isAudioUrl(content);
  bool get isImage =>
      messageType == 'IMAGE' || (!isAudio && _isImageUrl(mediaUrl));

  String? get effectiveAudioUrl {
    if (mediaUrl != null && mediaUrl!.trim().isNotEmpty) {
      return mediaUrl!.trim();
    }
    final urlInContent = extractFirstUrl(content);
    if (urlInContent != null && _isAudioUrl(urlInContent)) {
      return urlInContent;
    }
    return null;
  }

  static String? extractYouTubeId(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final regExp = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/|live\/))([\w-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(text);
    return match?.group(1);
  }

  static String? extractFirstUrl(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = RegExp(
      r'''(?:https?:\/\/|www\.)[^\s<>"']+''',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    var url = match.group(0)!;
    url = url.replaceFirst(RegExp(r'[\.,;:!\?\)\]\}]+$'), '');
    if (url.toLowerCase().startsWith('www.')) url = 'https://$url';
    return url;
  }

  /// Returns effective YouTube ID from explicit field, mediaUrl or content
  String? get effectiveYoutubeId {
    if (youtubeId != null && youtubeId!.isNotEmpty) return youtubeId;
    final fromMedia = extractYouTubeId(mediaUrl);
    if (fromMedia != null) return fromMedia;
    return extractYouTubeId(content);
  }

  bool get isYoutube => messageType == 'YOUTUBE' || effectiveYoutubeId != null;

  String? get youtubeThumbnailUrl {
    final ytId = effectiveYoutubeId;
    if (ytId != null && ytId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
    }
    return null;
  }

  /// Returns first web URL in content or mediaUrl (if any)
  String? get effectiveWebUrl {
    final fromMedia = extractFirstUrl(mediaUrl);
    if (fromMedia != null) return fromMedia;
    return extractFirstUrl(content);
  }

  /// True if message contains a non-YouTube, non-media web link
  bool get hasWebLink =>
      !isYoutube && !isAudio && !isImage && effectiveWebUrl != null;

  /// Returns text content with extracted link removed for clean caption display
  String get textWithoutLink {
    final match = RegExp(
      r'''(?:https?:\/\/|www\.)[^\s<>"']+''',
      caseSensitive: false,
    ).firstMatch(content);
    if (match == null) return content.trim();
    return '${content.substring(0, match.start)}${content.substring(match.end)}'
        .trim();
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
      conversationId:
          (json['conversation_id'] ?? json['conversationId'])?.toString() ?? '',
      workerId: (json['worker_id'] ?? json['workerId'])?.toString() ?? '',
      senderType:
          (json['sender_type'] ?? json['senderType'])
              ?.toString()
              .toUpperCase() ??
          'ADMIN',
      messageType:
          (json['message_type'] ?? json['messageType'])
              ?.toString()
              .toUpperCase() ??
          'TEXT',
      content: json['content']?.toString() ?? '',
      mediaUrl: (json['media_url'] ?? json['mediaUrl'])?.toString(),
      youtubeId: (json['youtube_id'] ?? json['youtubeId'])?.toString(),
      durationSeconds:
          int.tryParse(
            (json['duration_seconds'] ?? json['durationSeconds'])?.toString() ??
                '0',
          ) ??
          0,
      isRead:
          json['is_read'] == 1 ||
          json['is_read'] == true ||
          json['is_read'] == '1' ||
          json['isRead'] == 1 ||
          json['isRead'] == true,
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

  WorkerSupportMessage copyWith({
    String? id,
    String? conversationId,
    String? workerId,
    String? senderType,
    String? messageType,
    String? content,
    String? mediaUrl,
    String? youtubeId,
    int? durationSeconds,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return WorkerSupportMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      workerId: workerId ?? this.workerId,
      senderType: senderType ?? this.senderType,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      youtubeId: youtubeId ?? this.youtubeId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
