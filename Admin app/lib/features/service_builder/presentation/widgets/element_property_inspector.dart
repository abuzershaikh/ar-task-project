import 'package:flutter/material.dart';
import '../../domain/models/template_element.dart';
import '../../domain/models/visibility_context.dart';
import '../../domain/models/editability_mode.dart';
import '../../domain/models/action_type.dart';
import '../../domain/models/element_category.dart';

class ElementPropertyInspector extends StatefulWidget {
  final TemplateElement element;
  final Function(TemplateElement) onSave;

  const ElementPropertyInspector({
    super.key,
    required this.element,
    required this.onSave,
  });

  @override
  State<ElementPropertyInspector> createState() => _ElementPropertyInspectorState();
}

class _ElementPropertyInspectorState extends State<ElementPropertyInspector> {
  late TextEditingController _keyController;
  late TextEditingController _labelController;
  late VisibilityContext _visibility;
  late EditabilityMode _editability;
  late bool _isRequired;
  ActionType? _actionType;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.element.key);
    _labelController = TextEditingController(text: widget.element.label);
    _visibility = widget.element.visibility;
    _editability = widget.element.editability;
    _isRequired = widget.element.isRequired;
    _actionType = widget.element.actionType;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _onLabelChanged(String val) {
    if (widget.element.key.startsWith('heading_') ||
        widget.element.key.startsWith('paragraph_') ||
        widget.element.key.startsWith('textField_') ||
        widget.element.key.startsWith('actionButton_') ||
        widget.element.key.startsWith('youtube_')) {
      final autoKey = val.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      if (autoKey.isNotEmpty) {
        _keyController.text = autoKey;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSystem = widget.element.category == ElementCategory.system;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Component Settings: ${widget.element.type.label}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Primary Label (Title)
            TextField(
              controller: _labelController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Component Title / Heading Label',
                labelStyle: const TextStyle(color: Colors.cyanAccent),
                hintText: 'e.g. Subscribe to YouTube Channel',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _onLabelChanged,
            ),
            const SizedBox(height: 16),

            // Who can view this?
            const Text('Who can see this component?', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<VisibilityContext>(
              value: _visibility,
              dropdownColor: const Color(0xFF0F172A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: VisibilityContext.values.map((v) {
                return DropdownMenuItem(value: v, child: Text(v.label));
              }).toList(),
              onChanged: isSystem ? null : (val) => setState(() => _visibility = val!),
            ),
            const SizedBox(height: 16),

            // Who fills this?
            const Text('Who fills or interacts with this?', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<EditabilityMode>(
              value: _editability,
              dropdownColor: const Color(0xFF0F172A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: EditabilityMode.values.map((e) {
                return DropdownMenuItem(value: e, child: Text(e.label));
              }).toList(),
              onChanged: isSystem ? null : (val) => setState(() => _editability = val!),
            ),
            const SizedBox(height: 16),

            // Action Binding (if interactive button)
            if (widget.element.category == ElementCategory.interactive) ...[
              const Text('What action should this button trigger?', style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<ActionType>(
                value: _actionType,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ActionType.values.map((a) {
                  return DropdownMenuItem(value: a, child: Text(a.label));
                }).toList(),
                onChanged: (val) => setState(() => _actionType = val),
              ),
              const SizedBox(height: 16),
            ],

            // Is Required Field Switch
            SwitchListTile(
              title: const Text('Mandatory / Required Field', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('User cannot submit without completing this field', style: TextStyle(color: Colors.white54, fontSize: 11)),
              value: _isRequired,
              activeColor: Colors.cyanAccent,
              onChanged: isSystem ? null : (val) => setState(() => _isRequired = val),
            ),
            const SizedBox(height: 12),

            // Optional Advanced Technical Settings (Collapsed by default)
            InkWell(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(_showAdvanced ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.white54),
                    const SizedBox(width: 6),
                    const Text('Advanced Technical Config (Developer Only)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ),

            if (_showAdvanced) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _keyController,
                enabled: !isSystem,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'System Field ID (Auto Generated)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Component Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final updated = widget.element.copyWith(
                  key: _keyController.text.trim().replaceAll(' ', '_'),
                  label: _labelController.text.trim(),
                  visibility: _visibility,
                  editability: _editability,
                  isRequired: _isRequired,
                  actionType: _actionType,
                );
                widget.onSave(updated);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
