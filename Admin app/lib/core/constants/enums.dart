enum AdminRole {
  superAdmin,
  admin,
  operations,
  finance,
  kycReviewer,
  support,
}

enum UserStatus {
  active,
  inactive,
  suspended,
  banned,
}

enum TaskStatus {
  created,
  allocationPending,
  assigned,
  accepted,
  inProgress,
  submitted,
  underReview,
  approved,
  rejected,
  timeout,
  completed,
  cancelled,
}

enum OrderStatus {
  draft,
  paymentPending,
  active,
  paused,
  completed,
  cancelled,
}

enum KycStatus {
  pending,
  verified,
  rejected,
  resubmission,
}

enum PayoutStatus {
  pending,
  processing,
  paid,
  rejected,
}

enum ReviewStatus {
  pending,
  approved,
  rejected,
  requestChanges,
}

enum ServiceStatus {
  active,
  inactive,
  archived,
}

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}
