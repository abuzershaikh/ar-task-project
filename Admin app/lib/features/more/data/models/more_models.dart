class KycItemModel {
  final String id;
  final String workerId;
  final String workerName;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? paypalId;
  final String status;
  final DateTime? submittedAt;

  KycItemModel({
    required this.id,
    required this.workerId,
    required this.workerName,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    this.paypalId,
    required this.status,
    this.submittedAt,
  });

  factory KycItemModel.fromJson(Map<String, dynamic> json) {
    return KycItemModel(
      id: json['id']?.toString() ?? '',
      workerId: json['workerId']?.toString() ?? '',
      workerName: json['workerName'] ?? json['name'] ?? 'Worker',
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
      ifscCode: json['ifscCode'],
      upiId: json['upiId'],
      paypalId: json['paypalId'],
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      submittedAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class PayoutItemModel {
  final String id;
  final String workerId;
  final String workerName;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime? requestedAt;

  PayoutItemModel({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.requestedAt,
  });

  factory PayoutItemModel.fromJson(Map<String, dynamic> json) {
    return PayoutItemModel(
      id: json['id']?.toString() ?? '',
      workerId: json['userId']?.toString() ?? json['workerId']?.toString() ?? '',
      workerName: json['workerName'] ?? 'Worker',
      amount: double.tryParse(json['amount']?.toString() ?? '0.0') ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? json['method'] ?? 'UPI / Bank',
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      requestedAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class ReviewItemModel {
  final String id;
  final String taskId;
  final String workerId;
  final String proofUrl;
  final String status;
  final DateTime? submittedAt;

  ReviewItemModel({
    required this.id,
    required this.taskId,
    required this.workerId,
    required this.proofUrl,
    required this.status,
    this.submittedAt,
  });

  factory ReviewItemModel.fromJson(Map<String, dynamic> json) {
    return ReviewItemModel(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      workerId: json['workerId']?.toString() ?? '',
      proofUrl: json['proofUrl'] ?? json['proofData'] ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'SUBMITTED',
      submittedAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class AuditLogItemModel {
  final String id;
  final String action;
  final String adminEmail;
  final String details;
  final DateTime? timestamp;

  AuditLogItemModel({
    required this.id,
    required this.action,
    required this.adminEmail,
    required this.details,
    this.timestamp,
  });

  factory AuditLogItemModel.fromJson(Map<String, dynamic> json) {
    return AuditLogItemModel(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? 'ACTION',
      adminEmail: json['adminEmail'] ?? json['userId'] ?? 'system',
      details: json['details']?.toString() ?? json['entityType']?.toString() ?? '',
      timestamp: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
