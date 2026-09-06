/// Enums for Buyer App

// ============ USER & AUTH ============

enum UserRole {
  buyer,
  admin,
  worker,
}

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

// ============ CAMPAIGN (ORDER) ============

enum CampaignStatus {
  draft,
  active,
  paused,
  underReview,
  completed,
  cancelled,
  expired,
}

extension CampaignStatusExtension on CampaignStatus {
  String get displayName {
    switch (this) {
      case CampaignStatus.draft:
        return 'Draft';
      case CampaignStatus.active:
        return 'Active';
      case CampaignStatus.paused:
        return 'Paused';
      case CampaignStatus.underReview:
        return 'Under Review';
      case CampaignStatus.completed:
        return 'Completed';
      case CampaignStatus.cancelled:
        return 'Cancelled';
      case CampaignStatus.expired:
        return 'Expired';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

// ============ TASK ============

enum TaskStatus {
  pending,
  assigned,
  accepted,
  working,
  submitted,
  underReview,
  approved,
  rejected,
  changesRequested,
  expired,
}

extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.accepted:
        return 'Accepted';
      case TaskStatus.working:
        return 'Working';
      case TaskStatus.submitted:
        return 'Submitted';
      case TaskStatus.underReview:
        return 'Under Review';
      case TaskStatus.approved:
        return 'Approved';
      case TaskStatus.rejected:
        return 'Rejected';
      case TaskStatus.changesRequested:
        return 'Changes Requested';
      case TaskStatus.expired:
        return 'Expired';
    }
  }
}

// ============ SUBMISSION & REVIEW ============

enum SubmissionStatus {
  pending,
  underReview,
  approved,
  rejected,
  changesRequested,
}

enum ReviewMode {
  manual,
  auto,
  hybrid,
}

enum ProofType {
  screenshot,
  image,
  video,
  textResponse,
  link,
  file,
}

// ============ WALLET & TRANSACTIONS (NEW) ============

enum TransactionType {
  credit,     // Balance added
  debit,      // Balance deducted
  reserved,   // Amount reserved for campaign
  captured,   // Reserved amount captured
  released,   // Reserved amount released back
  refund,     // Refund credited
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.credit:
        return 'Credit';
      case TransactionType.debit:
        return 'Debit';
      case TransactionType.reserved:
        return 'Reserved';
      case TransactionType.captured:
        return 'Captured';
      case TransactionType.released:
        return 'Released';
      case TransactionType.refund:
        return 'Refund';
    }
  }

  bool get isCredit => this == TransactionType.credit || 
                       this == TransactionType.refund || 
                       this == TransactionType.released;

  bool get isDebit => this == TransactionType.debit || 
                      this == TransactionType.reserved ||
                      this == TransactionType.captured;
}

enum TransactionStatus {
  pending,
  processing,
  successful,
  failed,
  reversed,
}

// ============ PAYMENT ============

enum PaymentStatus {
  pending,
  processing,
  successful,
  failed,
  refunded,
  reserved, // NEW: Amount reserved for campaign
  captured, // NEW: Reserved amount captured
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.successful:
        return 'Successful';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.reserved:
        return 'Reserved';
      case PaymentStatus.captured:
        return 'Captured';
    }
  }
}

enum PaymentMethod {
  upi,
  card,
  netBanking,
  wallet,
  prepaidBalance, // NEW: Use wallet balance
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.prepaidBalance:
        return 'Prepaid Balance';
    }
  }
}

// ============ NOTIFICATION ============

enum NotificationType {
  campaign,
  review,
  payment,
  system,
  announcement,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

// ============ ANALYTICS ============

enum AnalyticsPeriod {
  today,
  week,
  month,
  quarter,
  year,
  custom,
}

enum ChartType {
  line,
  bar,
  pie,
  donut,
  area,
}

// ============ INVOICE ============

enum InvoiceStatus {
  draft,
  issued,
  paid,
  overdue,
  cancelled,
}

// ============ SUPPORT ============

enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed,
}

enum TicketPriority {
  low,
  medium,
  high,
  urgent,
}

// ============ SERVICE ============

enum ServiceCategory {
  socialMedia,
  appTesting,
  survey,
  contentModeration,
  dataEntry,
  research,
  other,
}

enum ServiceStatus {
  active,
  inactive,
  comingSoon,
}

// ============ FORM & UI ============

enum FormStatus {
  initial,
  validating,
  valid,
  invalid,
  submitting,
  success,
  error,
}

enum LoadingState {
  initial,
  loading,
  success,
  error,
  empty,
}

// ============ CAMPAIGN CREATION WIZARD (NEW) ============

enum CampaignCreationStep {
  chooseService,      // Step 1
  campaignDetails,    // Step 2
  proofRequirements,  // Step 3
  timing,             // Step 4
  reviewRules,        // Step 5
  summaryPayment,     // Step 6
}

extension CampaignCreationStepExtension on CampaignCreationStep {
  int get stepNumber {
    switch (this) {
      case CampaignCreationStep.chooseService:
        return 1;
      case CampaignCreationStep.campaignDetails:
        return 2;
      case CampaignCreationStep.proofRequirements:
        return 3;
      case CampaignCreationStep.timing:
        return 4;
      case CampaignCreationStep.reviewRules:
        return 5;
      case CampaignCreationStep.summaryPayment:
        return 6;
    }
  }

  String get title {
    switch (this) {
      case CampaignCreationStep.chooseService:
        return 'Choose Service';
      case CampaignCreationStep.campaignDetails:
        return 'Campaign Details';
      case CampaignCreationStep.proofRequirements:
        return 'Proof Requirements';
      case CampaignCreationStep.timing:
        return 'Timing';
      case CampaignCreationStep.reviewRules:
        return 'Review Rules';
      case CampaignCreationStep.summaryPayment:
        return 'Summary & Payment';
    }
  }
}
