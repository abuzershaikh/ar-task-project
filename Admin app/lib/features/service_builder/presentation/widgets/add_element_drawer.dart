import 'package:flutter/material.dart';
import '../../domain/models/element_category.dart';
import '../../domain/models/element_type.dart';
import '../../domain/models/template_element.dart';
import '../../domain/models/visibility_context.dart';
import '../../domain/models/editability_mode.dart';

class AddElementDrawer extends StatelessWidget {
  final Function(TemplateElement) onElementSelected;

  const AddElementDrawer({super.key, required this.onElementSelected});

  IconData _getIconForType(ElementType type) {
    switch (type) {
      case ElementType.heading:
        return Icons.title_rounded;
      case ElementType.paragraph:
        return Icons.notes_rounded;
      case ElementType.youtube:
        return Icons.play_circle_fill_rounded;
      case ElementType.audio:
        return Icons.graphic_eq_rounded;
      case ElementType.imageBanner:
        return Icons.image_rounded;
      case ElementType.textField:
        return Icons.text_fields_rounded;
      case ElementType.numberField:
        return Icons.pin_rounded;
      case ElementType.dropdownField:
        return Icons.arrow_drop_down_circle_rounded;
      case ElementType.actionButton:
        return Icons.touch_app_rounded;
      case ElementType.systemProof:
        return Icons.verified_user_rounded;
      case ElementType.systemTimer:
        return Icons.timer_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Template Element',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: ElementCategory.values.map((category) {
                final categoryTypes = ElementType.values.where((t) => t.category == category).toList();
                if (categoryTypes.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        category.displayName,
                        style: TextStyle(
                          color: category == ElementCategory.system ? Colors.amber : Colors.cyanAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...categoryTypes.map((type) {
                      return Card(
                        color: const Color(0xFF0F172A),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_getIconForType(type), color: Colors.white),
                          ),
                          title: Text(type.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(
                            type.category == ElementCategory.system ? 'Platform Locked System Rule' : 'Custom Configurable Element',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.add_circle_outline_rounded, color: Colors.cyanAccent),
                          onTap: () {
                            final newId = 'el_${DateTime.now().millisecondsSinceEpoch}';
                            final key = '${type.name}_${newId.substring(newId.length - 4)}';
                            
                            final bool isWorkerMedia = type == ElementType.youtube || type == ElementType.audio || type.category == ElementCategory.system;
                            final String initialLabel = type == ElementType.youtube
                                ? 'YouTube Tutorial Video'
                                : (type == ElementType.audio ? 'Admin Voice Audio Guide' : type.label);
                            final Map<String, dynamic> initialProps = type == ElementType.youtube
                                ? {'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'videoUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'}
                                : (type == ElementType.audio
                                    ? {'url': 'https://earnpost-media-worker.aawuazer.workers.dev/audio/sample_voice_guide.m4a', 'audioUrl': 'https://earnpost-media-worker.aawuazer.workers.dev/audio/sample_voice_guide.m4a'}
                                    : {});

                            final element = TemplateElement(
                              id: newId,
                              key: key,
                              label: initialLabel,
                              category: type.category,
                              type: type,
                              visibility: isWorkerMedia ? VisibilityContext.workerOnly : VisibilityContext.both,
                              editability: type.category == ElementCategory.input ? EditabilityMode.buyerInput : EditabilityMode.adminFixed,
                              properties: initialProps,
                            );

                            onElementSelected(element);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
