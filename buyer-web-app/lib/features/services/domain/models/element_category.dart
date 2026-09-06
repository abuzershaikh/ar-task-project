enum ElementCategory {
  display,
  input,
  interactive,
  system,
}

extension ElementCategoryExtension on ElementCategory {
  String get displayName {
    switch (this) {
      case ElementCategory.display:
        return 'Display Elements';
      case ElementCategory.input:
        return 'Form Inputs';
      case ElementCategory.interactive:
        return 'Interactive Actions';
      case ElementCategory.system:
        return 'System Rules & Proofs';
    }
  }
}
