enum VisibilityContext {
  buyerOnly,
  workerOnly,
  both,
}

extension VisibilityContextExtension on VisibilityContext {
  String get label {
    switch (this) {
      case VisibilityContext.buyerOnly:
        return 'Buyer Only (Campaign Form)';
      case VisibilityContext.workerOnly:
        return 'Worker Only (Task Execution)';
      case VisibilityContext.both:
        return 'Shared (Both Buyer & Worker)';
    }
  }
}
