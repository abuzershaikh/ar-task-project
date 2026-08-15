enum VisibilityContext {
  both,
  buyerOnly,
  workerOnly,
  adminOnly;

  String get label {
    switch (this) {
      case VisibilityContext.both:
        return 'Both (Buyer & Worker)';
      case VisibilityContext.buyerOnly:
        return 'Buyer Only';
      case VisibilityContext.workerOnly:
        return 'Worker Only';
      case VisibilityContext.adminOnly:
        return 'Admin Only';
    }
  }
}
