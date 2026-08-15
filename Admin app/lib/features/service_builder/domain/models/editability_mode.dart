enum EditabilityMode {
  buyerInput,
  adminFixed,
  workerInteractive;

  String get label {
    switch (this) {
      case EditabilityMode.buyerInput:
        return 'Buyer Input (Filled during campaign creation)';
      case EditabilityMode.adminFixed:
        return 'Admin Fixed (Value locked by Admin)';
      case EditabilityMode.workerInteractive:
        return 'Worker Interactive (Actionable by Worker)';
    }
  }
}
