class SupportConversationModel {
  final String id;
  final String workerId;
  final String? workerActualId;
  final String workerName;
  final String workerPhone;
  final String workerEmail;
  final String lastMessageText;
  final String lastMessageType;
  final DateTime lastMessageAt;
  final int unreadAdminCount;
  final int unreadWorkerCount;
  final DateTime? lastActiveAt;
  final int totalTasksCompleted;
  final String? workerStatus;
  final String? workerAvatarUrl;

  const SupportConversationModel({
    required this.id,
    required this.workerId,
    this.workerActualId,
    required this.workerName,
    required this.workerPhone,
    required this.workerEmail,
    required this.lastMessageText,
    required this.lastMessageType,
    required this.lastMessageAt,
    required this.unreadAdminCount,
    required this.unreadWorkerCount,
    this.lastActiveAt,
    this.totalTasksCompleted = 0,
    this.workerStatus,
    this.workerAvatarUrl,
  });

  factory SupportConversationModel.fromJson(Map<String, dynamic> json) {
    // Resolve clean name (avoid generic 'Worker' fallback if email/name exists)
    String rawName = json['worker_name']?.toString().trim() ?? '';
    final rawEmail = json['worker_email']?.toString().trim() ?? '';
    final rawPhone = json['worker_phone']?.toString().trim() ?? '';

    String resolvedName = rawName;
    if (resolvedName.isEmpty || resolvedName.toLowerCase() == 'worker') {
      if (rawEmail.isNotEmpty) {
        resolvedName = rawEmail.split('@')[0];
      } else if (rawPhone.isNotEmpty) {
        resolvedName = rawPhone;
      } else {
        final wId = json['worker_id']?.toString() ?? '';
        resolvedName = wId.length > 6 ? 'Worker #${wId.substring(0, 6)}' : 'Worker';
      }
    }

    return SupportConversationModel(
      id: json['id']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? '',
      workerActualId: json['worker_actual_id']?.toString(),
      workerName: resolvedName,
      workerPhone: rawPhone,
      workerEmail: rawEmail,
      lastMessageText: json['last_message_text']?.toString() ?? '',
      lastMessageType: json['last_message_type']?.toString() ?? 'TEXT',
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.tryParse(json['last_message_at'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      unreadAdminCount: int.tryParse(json['unread_admin_count']?.toString() ?? '0') ?? 0,
      unreadWorkerCount: int.tryParse(json['unread_worker_count']?.toString() ?? '0') ?? 0,
      lastActiveAt: json['last_active_at'] != null 
          ? DateTime.tryParse(json['last_active_at'].toString()) 
          : null,
      totalTasksCompleted: int.tryParse(json['total_tasks_completed']?.toString() ?? '0') ?? 0,
      workerStatus: json['worker_status']?.toString(),
      workerAvatarUrl: json['worker_avatar_url']?.toString() ?? json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
    );
  }

  SupportConversationModel copyWith({
    String? lastMessageText,
    String? lastMessageType,
    DateTime? lastMessageAt,
    int? unreadAdminCount,
    int? unreadWorkerCount,
  }) {
    return SupportConversationModel(
      id: id,
      workerId: workerId,
      workerActualId: workerActualId,
      workerName: workerName,
      workerPhone: workerPhone,
      workerEmail: workerEmail,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadAdminCount: unreadAdminCount ?? this.unreadAdminCount,
      unreadWorkerCount: unreadWorkerCount ?? this.unreadWorkerCount,
      lastActiveAt: lastActiveAt,
      totalTasksCompleted: totalTasksCompleted,
      workerStatus: workerStatus,
      workerAvatarUrl: workerAvatarUrl,
    );
  }
}
