enum ActionType {
  openUrl,
  copyText,
  takeScreenshot,
}

extension ActionTypeExtension on ActionType {
  String get label {
    switch (this) {
      case ActionType.openUrl:
        return 'Open Target Link / URL';
      case ActionType.copyText:
        return 'Copy Instruction Text';
      case ActionType.takeScreenshot:
        return 'Capture Screenshot Proof';
    }
  }
}
