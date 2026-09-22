class SupportConversationModel {
  final String id;
  final String workerId;
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

  const SupportConversationModel({
    required this.id,
    required this.workerId,
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
  });

  factory SupportConversationModel.fromJson(Map<String, dynamic> json) {
    return SupportConversationModel(
      id: json['id']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? '',
      workerName: json['worker_name']?.toString() ?? 'Worker',
      workerPhone: json['worker_phone']?.toString() ?? '',
      workerEmail: json['worker_email']?.toString() ?? '',
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
    );
  }
}
