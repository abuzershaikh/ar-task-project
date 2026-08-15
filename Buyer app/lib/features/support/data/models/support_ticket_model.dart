class SupportTicketModel {
  final String id;
  final String subject;
  final String category;
  final String message;
  final String status;
  final DateTime createdAt;

  SupportTicketModel({
    required this.id,
    required this.subject,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      subject: (json['subject'] ?? 'Support Inquiry').toString(),
      category: (json['category'] ?? 'GENERAL').toString(),
      message: (json['message'] ?? '').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
