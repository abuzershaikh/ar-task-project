import 'element_category.dart';

enum ElementType {
  heading(ElementCategory.display, 'Heading / Title'),
  paragraph(ElementCategory.display, 'Paragraph / Description'),
  youtube(ElementCategory.display, 'YouTube Video Embed'),
  audio(ElementCategory.display, 'Audio Player'),
  imageBanner(ElementCategory.display, 'Image Banner'),

  textField(ElementCategory.input, 'Text Field Input'),
  numberField(ElementCategory.input, 'Number Input'),
  dropdownField(ElementCategory.input, 'Dropdown Selector'),

  actionButton(ElementCategory.interactive, 'Action Button'),

  systemProof(ElementCategory.system, 'Mandatory Proof Rule'),
  systemTimer(ElementCategory.system, 'Task Timer Rule');

  final ElementCategory category;
  final String label;
  const ElementType(this.category, this.label);
}
