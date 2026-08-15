enum ElementCategory {
  content,
  media,
  input,
  interactive,
  system;

  String get displayName {
    switch (this) {
      case ElementCategory.content:
        return 'Content Elements';
      case ElementCategory.media:
        return 'Media Elements';
      case ElementCategory.input:
        return 'Input Elements';
      case ElementCategory.interactive:
        return 'Interactive Elements';
      case ElementCategory.system:
        return 'System Elements (Platform Locked)';
    }
  }
}
