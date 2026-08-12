enum ActionType {
  openUrl,
  copyText,
  subscribeChannel,
  watchVideo,
  takeScreenshot,
  voiceRecord;

  String get label {
    switch (this) {
      case ActionType.openUrl:
        return 'Open Target URL';
      case ActionType.copyText:
        return 'Copy Text to Clipboard';
      case ActionType.subscribeChannel:
        return 'Subscribe YouTube Channel';
      case ActionType.watchVideo:
        return 'Watch Video (Timer Enforced)';
      case ActionType.takeScreenshot:
        return 'Take & Upload Screenshot';
      case ActionType.voiceRecord:
        return 'Record Voice Proof';
    }
  }
}
