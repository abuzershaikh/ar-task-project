enum EditabilityMode {
  adminFixed,
  buyerInput,
  workerInput,
  systemCalculated,
}

extension EditabilityModeExtension on EditabilityMode {
  String get label {
    switch (this) {
      case EditabilityMode.adminFixed:
        return 'Admin Fixed Value';
      case EditabilityMode.buyerInput:
        return 'Buyer Field Input';
      case EditabilityMode.workerInput:
        return 'Worker Submission Field';
      case EditabilityMode.systemCalculated:
        return 'System Calculated';
    }
  }
}
