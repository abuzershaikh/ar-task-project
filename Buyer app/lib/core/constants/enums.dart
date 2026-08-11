// Campaign/Order Status
enum CampaignStatus {
  paymentPending,
  active,
  inProgress,
  completed,
  paused,
  cancelled,
  expired,
}

extension CampaignStatusExtension on CampaignStatus {
  String get value {
    switch (this) {
      case CampaignStatus.paymentPending:
        return 'PAYMENT_PENDING';
      case CampaignStatus.active:
        return 'ACTIVE';
      case CampaignStatus.inProgress:
        return 'IN_PROGRESS';
      case CampaignStatus.completed:
        return 'COMPLETED';
      case CampaignStatus.paused:
        return 'PAUSED';
      case CampaignStatus.cancelled:
        return 'CANCELLED';
      case CampaignStatus.expired:
        return 'EXPIRED';
    }
  }

  String get displayName {
    switch (this) {
      case CampaignStatus.paymentPending:
        return 'Payment Pending';
      case CampaignStatus.active:
        return 'Active';
      case CampaignStatus.inProgress:
        return 'In Progress';
      case CampaignStatus.completed:
        return 'Completed';
      case CampaignStatus.paused:
        return 'Paused';
      case CampaignStatus.cancelled:
        return 'Cancelled';
      case CampaignStatus.expired:
        return 'Expired';
    }
  }
}

// Submission/Review Status
enum SubmissionStatus {
  pending,
  underReview,
  approved,
  rejected,
  changesRequested,
}

extension SubmissionStatusExtension on SubmissionStatus {
  String get value {
    switch (this) {
      case SubmissionStatus.pending:
        return 'PENDING';
      case SubmissionStatus.underReview:
        return 'UNDER_REVIEW';
      case SubmissionStatus.approved:
        return 'APPROVED';
      case SubmissionStatus.rejected:
        return 'REJECTED';
      case SubmissionStatus.changesRequested:
        return 'CHANGES_REQUESTED';
    }
  }

  String get displayName {
    switch (this) {
      case SubmissionStatus.pending:
        return 'Pending';
      case SubmissionStatus.underReview:
        return 'Under Review';
      case SubmissionStatus.approved:
        return 'Approved';
      case SubmissionStatus.rejected:
        return 'Rejected';
      case SubmissionStatus.changesRequested:
        return 'Changes Requested';
    }
  }
}

// Payment Status
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

extension PaymentStatusExtension on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'PENDING';
      case PaymentStatus.processing:
        return 'PROCESSING';
      case PaymentStatus.completed:
        return 'COMPLETED';
      case PaymentStatus.failed:
        return 'FAILED';
      case PaymentStatus.refunded:
        return 'REFUNDED';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

// Task Type (Service Type)
enum TaskType {
  productTesting,
  survey,
  feedback,
  storeVisit,
  hotelAudit,
  other,
}

extension TaskTypeExtension on TaskType {
  String get value {
    switch (this) {
      case TaskType.productTesting:
        return 'PRODUCT_TESTING';
      case TaskType.survey:
        return 'SURVEY';
      case TaskType.feedback:
        return 'FEEDBACK';
      case TaskType.storeVisit:
        return 'STORE_VISIT';
      case TaskType.hotelAudit:
        return 'HOTEL_AUDIT';
      case TaskType.other:
        return 'OTHER';
    }
  }

  String get displayName {
    switch (this) {
      case TaskType.productTesting:
        return 'Product Testing';
      case TaskType.survey:
        return 'Survey';
      case TaskType.feedback:
        return 'Feedback';
      case TaskType.storeVisit:
        return 'Store Visit';
      case TaskType.hotelAudit:
        return 'Hotel Audit';
      case TaskType.other:
        return 'Other';
    }
  }
}

// Review Mode
enum ReviewMode {
  buyer,
  admin,
  automatic,
  hybrid,
}

extension ReviewModeExtension on ReviewMode {
  String get value {
    switch (this) {
      case ReviewMode.buyer:
        return 'BUYER';
      case ReviewMode.admin:
        return 'ADMIN';
      case ReviewMode.automatic:
        return 'AUTOMATIC';
      case ReviewMode.hybrid:
        return 'HYBRID';
    }
  }

  String get displayName {
    switch (this) {
      case ReviewMode.buyer:
        return 'Buyer Review';
      case ReviewMode.admin:
        return 'Admin Review';
      case ReviewMode.automatic:
        return 'Automatic';
      case ReviewMode.hybrid:
        return 'Hybrid';
    }
  }
}

// Notification Type
enum NotificationType {
  campaignCreated,
  campaignActivated,
  taskCompleted,
  submissionReceived,
  paymentReceived,
  campaignCompleted,
  campaignExpiring,
  systemAlert,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.campaignCreated:
        return 'CAMPAIGN_CREATED';
      case NotificationType.campaignActivated:
        return 'CAMPAIGN_ACTIVATED';
      case NotificationType.taskCompleted:
        return 'TASK_COMPLETED';
      case NotificationType.submissionReceived:
        return 'SUBMISSION_RECEIVED';
      case NotificationType.paymentReceived:
        return 'PAYMENT_RECEIVED';
      case NotificationType.campaignCompleted:
        return 'CAMPAIGN_COMPLETED';
      case NotificationType.campaignExpiring:
        return 'CAMPAIGN_EXPIRING';
      case NotificationType.systemAlert:
        return 'SYSTEM_ALERT';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.campaignCreated:
        return 'Campaign Created';
      case NotificationType.campaignActivated:
        return 'Campaign Activated';
      case NotificationType.taskCompleted:
        return 'Task Completed';
      case NotificationType.submissionReceived:
        return 'Submission Received';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.campaignCompleted:
        return 'Campaign Completed';
      case NotificationType.campaignExpiring:
        return 'Campaign Expiring';
      case NotificationType.systemAlert:
        return 'System Alert';
    }
  }
}

// Sort Order
enum SortOrder {
  ascending,
  descending,
}

extension SortOrderExtension on SortOrder {
  String get value {
    switch (this) {
      case SortOrder.ascending:
        return 'ASC';
      case SortOrder.descending:
        return 'DESC';
    }
  }
}

// Filter Period
enum FilterPeriod {
  today,
  yesterday,
  last7Days,
  last30Days,
  last90Days,
  thisMonth,
  lastMonth,
  custom,
}

extension FilterPeriodExtension on FilterPeriod {
  String get displayName {
    switch (this) {
      case FilterPeriod.today:
        return 'Today';
      case FilterPeriod.yesterday:
        return 'Yesterday';
      case FilterPeriod.last7Days:
        return 'Last 7 Days';
      case FilterPeriod.last30Days:
        return 'Last 30 Days';
      case FilterPeriod.last90Days:
        return 'Last 90 Days';
      case FilterPeriod.thisMonth:
        return 'This Month';
      case FilterPeriod.lastMonth:
        return 'Last Month';
      case FilterPeriod.custom:
        return 'Custom';
    }
  }
}

// Invoice Status
enum InvoiceStatus {
  draft,
  sent,
  paid,
  cancelled,
  overdue,
}

extension InvoiceStatusExtension on InvoiceStatus {
  String get value {
    switch (this) {
      case InvoiceStatus.draft:
        return 'DRAFT';
      case InvoiceStatus.sent:
        return 'SENT';
      case InvoiceStatus.paid:
        return 'PAID';
      case InvoiceStatus.cancelled:
        return 'CANCELLED';
      case InvoiceStatus.overdue:
        return 'OVERDUE';
    }
  }

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
      case InvoiceStatus.overdue:
        return 'Overdue';
    }
  }
}

// Payment Method
enum PaymentMethod {
  card,
  upi,
  netBanking,
  wallet,
}

extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.card:
        return 'CARD';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.netBanking:
        return 'NET_BANKING';
      case PaymentMethod.wallet:
        return 'WALLET';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.wallet:
        return 'Wallet';
    }
  }
}

// Campaign Sort By
enum CampaignSortBy {
  createdDate,
  updatedDate,
  name,
  status,
  progress,
  expiryDate,
}

extension CampaignSortByExtension on CampaignSortBy {
  String get value {
    switch (this) {
      case CampaignSortBy.createdDate:
        return 'created_at';
      case CampaignSortBy.updatedDate:
        return 'updated_at';
      case CampaignSortBy.name:
        return 'name';
      case CampaignSortBy.status:
        return 'status';
      case CampaignSortBy.progress:
        return 'progress';
      case CampaignSortBy.expiryDate:
        return 'expires_at';
    }
  }

  String get displayName {
    switch (this) {
      case CampaignSortBy.createdDate:
        return 'Created Date';
      case CampaignSortBy.updatedDate:
        return 'Updated Date';
      case CampaignSortBy.name:
        return 'Name';
      case CampaignSortBy.status:
        return 'Status';
      case CampaignSortBy.progress:
        return 'Progress';
      case CampaignSortBy.expiryDate:
        return 'Expiry Date';
    }
  }
}

// File Type
enum FileType {
  image,
  video,
  document,
  audio,
  other,
}

extension FileTypeExtension on FileType {
  String get value {
    switch (this) {
      case FileType.image:
        return 'IMAGE';
      case FileType.video:
        return 'VIDEO';
      case FileType.document:
        return 'DOCUMENT';
      case FileType.audio:
        return 'AUDIO';
      case FileType.other:
        return 'OTHER';
    }
  }

  List<String> get extensions {
    switch (this) {
      case FileType.image:
        return ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      case FileType.video:
        return ['mp4', 'avi', 'mov', 'mkv'];
      case FileType.document:
        return ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'];
      case FileType.audio:
        return ['mp3', 'wav', 'aac', 'm4a'];
      case FileType.other:
        return [];
    }
  }
}

// Rating Value
enum RatingValue {
  oneStar,
  twoStar,
  threeStar,
  fourStar,
  fiveStar,
}

extension RatingValueExtension on RatingValue {
  int get value {
    switch (this) {
      case RatingValue.oneStar:
        return 1;
      case RatingValue.twoStar:
        return 2;
      case RatingValue.threeStar:
        return 3;
      case RatingValue.fourStar:
        return 4;
      case RatingValue.fiveStar:
        return 5;
    }
  }

  String get displayName {
    switch (this) {
      case RatingValue.oneStar:
        return 'Poor';
      case RatingValue.twoStar:
        return 'Fair';
      case RatingValue.threeStar:
        return 'Good';
      case RatingValue.fourStar:
        return 'Very Good';
      case RatingValue.fiveStar:
        return 'Excellent';
    }
  }
}

// Support Ticket Priority
enum TicketPriority {
  low,
  medium,
  high,
  urgent,
}

extension TicketPriorityExtension on TicketPriority {
  String get value {
    switch (this) {
      case TicketPriority.low:
        return 'LOW';
      case TicketPriority.medium:
        return 'MEDIUM';
      case TicketPriority.high:
        return 'HIGH';
      case TicketPriority.urgent:
        return 'URGENT';
    }
  }

  String get displayName {
    switch (this) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.urgent:
        return 'Urgent';
    }
  }
}

// Support Ticket Status
enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed,
}

extension TicketStatusExtension on TicketStatus {
  String get value {
    switch (this) {
      case TicketStatus.open:
        return 'OPEN';
      case TicketStatus.inProgress:
        return 'IN_PROGRESS';
      case TicketStatus.resolved:
        return 'RESOLVED';
      case TicketStatus.closed:
        return 'CLOSED';
    }
  }

  String get displayName {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }
}
