import 'element_category.dart';

enum ElementType {
  heading(ElementCategory.content, 'Heading / Title'),
  paragraph(ElementCategory.content, 'Paragraph / Description'),
  youtube(ElementCategory.media, 'YouTube Video Embed'),
  audio(ElementCategory.media, 'Audio Player'),
  imageBanner(ElementCategory.media, 'Image Banner'),
  textField(ElementCategory.input, 'Text Input Field'),
  numberField(ElementCategory.input, 'Number Field'),
  dropdownField(ElementCategory.input, 'Dropdown Selector'),
  actionButton(ElementCategory.interactive, 'Action Button'),
  systemProof(ElementCategory.system, 'Proof Submission (Locked)'),
  systemTimer(ElementCategory.system, 'Task Timer (Locked)');

  final ElementCategory category;
  final String label;

  const ElementType(this.category, this.label);
}
