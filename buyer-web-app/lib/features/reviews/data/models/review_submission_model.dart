class ReviewSubmissionModel {
  final String id;
  final String taskId;
  final String taskTitle;
  final String workerId;
  final String workerName;
  final String proofScreenshotUrl;
  final String proofText;
  final String status;
  final DateTime submittedAt;

  ReviewSubmissionModel({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.workerId,
    required this.workerName,
    required this.proofScreenshotUrl,
    required this.proofText,
    required this.status,
    required this.submittedAt,
  });

  factory ReviewSubmissionModel.fromJson(Map<String, dynamic> json) {
    String extractedProofUrl = (json['proofScreenshotUrl'] ?? json['proofUrl'] ?? '').toString();
    
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
        extractedProofUrl = (dataMap['proofUrl'] ?? dataMap['screenshotUrl'] ?? dataMap['image'] ?? dataMap['fileUrl'] ?? '').toString();
      }
      if (extractedProofText.isEmpty) {
        extractedProofText = (dataMap['textProof'] ?? dataMap['proofText'] ?? dataMap['notes'] ?? '').toString();
      }
    }

    if (extractedProofUrl.isNotEmpty && !extractedProofUrl.startsWith('http')) {
      final clean = extractedProofUrl.replaceAll(RegExp(r'^/+'), '').replaceAll('uploads/', '');
      extractedProofUrl = 'http://65.20.77.112:3000/api/v1/files/raw/$clean';
    }

    return ReviewSubmissionModel(
      id: (json['id'] ?? json['_id'] ?? json['submissionId'] ?? '').toString(),
      taskId: (json['taskId'] ?? '').toString(),
      taskTitle: (json['taskTitle'] ?? json['taskType'] ?? 'Task Submission').toString(),
      workerId: (json['workerId'] ?? '').toString(),
      workerName: (json['workerName'] ?? json['worker']?['name'] ?? 'Worker').toString(),
      proofScreenshotUrl: extractedProofUrl,
      proofText: extractedProofText,
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      submittedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['submittedAt'] != null
              ? DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'workerId': workerId,
      'workerName': workerName,
      'proofScreenshotUrl': proofScreenshotUrl,
      'proofText': proofText,
      'status': status,
      'createdAt': submittedAt.toIso8601String(),
    };
  }
}
