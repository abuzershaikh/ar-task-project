class KycItemModel {
  final String id;
  final String workerId;
  final String workerName;
  final String workerEmail;
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
    this.workerEmail = '',
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
      workerEmail: json['workerEmail'] ?? json['email'] ?? '',
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
  final String workerEmail;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime? requestedAt;

  PayoutItemModel({
    required this.id,
    required this.workerId,
    required this.workerName,
    this.workerEmail = '',
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
      workerEmail: json['workerEmail'] ?? json['email'] ?? '',
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
  final String taskTitle;
  final String orderId;
  final String workerId;
  final String workerName;
  final String workerEmail;
  final String proofUrl;
  final String proofText;
  final String status;
  final DateTime? submittedAt;

  ReviewItemModel({
    required this.id,
    required this.taskId,
    this.taskTitle = 'Task Execution',
    this.orderId = '',
    required this.workerId,
    this.workerName = 'Worker',
    this.workerEmail = '',
    required this.proofUrl,
    this.proofText = '',
    required this.status,
    this.submittedAt,
  });

  factory ReviewItemModel.fromJson(Map<String, dynamic> json) {
    String extractedProofUrl = (json['proofUrl'] ?? json['proofScreenshotUrl'] ?? '').toString();
    
    // Extract from proofs array if present
    if (extractedProofUrl.isEmpty && json['proofs'] is List && (json['proofs'] as List).isNotEmpty) {
      final first = (json['proofs'] as List).first;
      if (first is Map) {
        extractedProofUrl = (first['url'] ?? first['path'] ?? '').toString();
      } else if (first is String) {
        extractedProofUrl = first;
      }
    }

    // Extract from data object if present
    String extractedProofText = (json['proofText'] ?? json['notes'] ?? '').toString();
    if (json['data'] is Map) {
      final dataMap = json['data'] as Map;
      if (extractedProofUrl.isEmpty) {
        extractedProofUrl = (dataMap['proofUrl'] ?? dataMap['screenshotUrl'] ?? '').toString();
      }
      if (extractedProofText.isEmpty) {
        extractedProofText = (dataMap['textProof'] ?? dataMap['proofText'] ?? dataMap['notes'] ?? '').toString();
      }
    }

    return ReviewItemModel(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      taskTitle: (json['taskTitle'] ?? json['taskType'] ?? 'Task Execution').toString(),
      orderId: (json['orderId'] ?? '').toString(),
      workerId: json['workerId']?.toString() ?? '',
      workerName: (json['workerName'] ?? json['worker']?['name'] ?? 'Worker').toString(),
      workerEmail: (json['workerEmail'] ?? json['worker']?['email'] ?? '').toString(),
      proofUrl: extractedProofUrl,
      proofText: extractedProofText,
      status: json['status']?.toString().toUpperCase() ?? 'SUBMITTED',
      submittedAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
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
