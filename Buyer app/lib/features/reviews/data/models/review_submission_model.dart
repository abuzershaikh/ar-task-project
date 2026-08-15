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
    return ReviewSubmissionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      taskId: (json['taskId'] ?? '').toString(),
      taskTitle: (json['taskTitle'] ?? json['taskType'] ?? 'Task Submission').toString(),
      workerId: (json['workerId'] ?? '').toString(),
      workerName: (json['workerName'] ?? json['worker']?['name'] ?? 'Worker').toString(),
      proofScreenshotUrl: (json['proofScreenshotUrl'] ?? json['proofUrl'] ?? '').toString(),
      proofText: (json['proofText'] ?? json['notes'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      submittedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
