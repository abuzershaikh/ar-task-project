import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/service_builder_bloc.dart';
import '../bloc/service_builder_event.dart';
import '../bloc/service_builder_state.dart';
import '../widgets/add_element_drawer.dart';
import '../widgets/element_property_inspector.dart';
import '../widgets/buyer_worker_preview_modal.dart';
import '../../domain/models/element_category.dart';
import '../../domain/models/element_type.dart';
import '../../domain/models/template_element.dart';
import '../../domain/models/visibility_context.dart';
import '../../domain/models/editability_mode.dart';
import '../../domain/models/pricing_config.dart';

class ServiceBuilderScreen extends StatefulWidget {
  final String? serviceId;
  final String? draftCode;
  final String? draftName;

  const ServiceBuilderScreen({
    super.key,
    this.serviceId,
    this.draftCode,
    this.draftName,
  });

  @override
  State<ServiceBuilderScreen> createState() => _ServiceBuilderScreenState();
}

class _ServiceBuilderScreenState extends State<ServiceBuilderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _buyerPriceController;
  late TextEditingController _marginController;
  bool _isDraggingOverCanvas = false;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _buyerPriceController = TextEditingController();
    _marginController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bootstrapped) return;
      _bootstrapped = true;

      final bloc = context.read<ServiceBuilderBloc>();
      if (widget.serviceId != null && widget.serviceId!.isNotEmpty) {
        bloc.add(SelectServiceForEditEvent(widget.serviceId!));
        return;
      }

      if (widget.draftCode != null && widget.draftName != null) {
        bloc.add(
          CreateNewServiceDraftEvent(
            code: widget.draftCode!,
            name: widget.draftName!,
          ),
        );
        return;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buyerPriceController.dispose();
    _marginController.dispose();
    super.dispose();
  }

  void _syncPricingControllers(ServiceEditingState state) {
    final buyerStr = state.serviceDraft.pricing.buyerPrice.toStringAsFixed(0);
    final marginStr = state.serviceDraft.pricing.adminMarginPercent.toStringAsFixed(0);

    if (_buyerPriceController.text != buyerStr) {
      _buyerPriceController.text = buyerStr;
    }
    if (_marginController.text != marginStr) {
      _marginController.text = marginStr;
    }
  }

  void _showEditServiceBasicInfoDialog(dynamic service) {
    final nameCtrl = TextEditingController(text: service.name);
    final descCtrl = TextEditingController(text: service.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Edit Service Details',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Service Title / Name',
                labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.black, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Save Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                context.read<ServiceBuilderBloc>().add(
                      UpdateServiceInfoEvent(
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _addNewElementFromType(ElementType type) {
    final newId = 'el_${DateTime.now().millisecondsSinceEpoch}';
    final key = '${type.name}_${newId.substring(newId.length - 4)}';

    final element = TemplateElement(
      id: newId,
      key: key,
      label: type.label,
      category: type.category,
      type: type,
      visibility: type.category == ElementCategory.system ? VisibilityContext.workerOnly : VisibilityContext.both,
      editability: type.category == ElementCategory.input ? EditabilityMode.buyerInput : EditabilityMode.adminFixed,
    );

    context.read<ServiceBuilderBloc>().add(AddTemplateElementEvent(element));
  }

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
    return BlocConsumer<ServiceBuilderBloc, ServiceBuilderState>(
      listener: (context, state) {
        if (state is ServiceEditingState) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!), backgroundColor: AppColors.success),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.redAccent),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is ServiceBuilderLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          );
        }

        if (state is ServiceEditingState) {
          _syncPricingControllers(state);
          final service = state.serviceDraft;

          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(
              titleSpacing: 12,
              title: InkWell(
                onTap: () => _showEditServiceBasicInfoDialog(service),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  service.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_outlined, size: 12, color: Colors.cyanAccent),
                            ],
                          ),
                          Text('Code: ${service.code} • V${service.currentVersion}',
                              style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              backgroundColor: const Color(0xFF0F172A),
              actions: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.amberAccent, size: 20),
                  tooltip: 'Live Preview Simulator',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BuyerWorkerPreviewModal(service: service),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save_rounded, color: Colors.white70, size: 20),
                  tooltip: 'Save Draft',
                  onPressed: state.isSaving
                      ? null
                      : () => context.read<ServiceBuilderBloc>().add(SaveServiceDraftEvent()),
                ),
                IconButton(
                  icon: const Icon(Icons.publish_rounded, color: AppColors.success, size: 20),
                  tooltip: 'Publish Version',
                  onPressed: state.isPublishing
                      ? null
                      : () => context.read<ServiceBuilderBloc>().add(PublishServiceVersionEvent(service.id)),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Colors.cyanAccent,
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                tabs: const [
                  Tab(icon: Icon(Icons.drag_indicator_rounded, size: 16), text: 'Template Builder'),
                  Tab(icon: Icon(Icons.attach_money_rounded, size: 16), text: 'Pricing Engine'),
                  Tab(icon: Icon(Icons.timer_rounded, size: 16), text: 'Timing Rules'),
                  Tab(icon: Icon(Icons.rule_rounded, size: 16), text: 'Proof Engine'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Ultra-Sleek Mini Drag & Drop Service Template Builder Studio
                _buildDragAndDropCanvasTab(context, state),

                // TAB 2: Financial Pricing Engine
                _buildPricingTab(context, state),

                // TAB 3: Timing Rules
                _buildTimingTab(context, state),

                // TAB 4: Proof Rules
                _buildProofTab(context, state),
              ],
            ),
          );
        }

        if (widget.serviceId != null || widget.draftCode != null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          );
        }

        return const Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(child: Text('Select or create a service from catalog.', style: TextStyle(color: Colors.white54, fontSize: 13))),
        );
      },
    );
  }

  /// Compact Mini Drag & Drop Studio Builder
  Widget _buildDragAndDropCanvasTab(BuildContext context, ServiceEditingState state) {
    final elements = state.serviceDraft.elements;

    return Column(
      children: [
        // Mini Toolbox Header Guidance
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Drag mini component tiles into canvas target below:',
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BuyerWorkerPreviewModal(service: state.serviceDraft),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Simulator', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        // Mini Component Tiles Palette (Horizontal Scrollable Ribbon)
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: const BoxDecoration(
            color: const Color(0xFF0F172A),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ElementType.values.length,
            itemBuilder: (context, idx) {
              final type = ElementType.values[idx];
              final isSystem = type.category == ElementCategory.system;

              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: LongPressDraggable<ElementType>(
                  delay: const Duration(milliseconds: 150),
                  hapticFeedbackOnStart: true,
                  data: type,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSystem ? Colors.amber : Colors.cyanAccent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getIconForType(type), color: Colors.black, size: 14),
                          const SizedBox(width: 4),
                          Text(type.label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildMiniPaletteTile(type, isSystem),
                  ),
                  child: InkWell(
                    onTap: () => _addNewElementFromType(type),
                    child: _buildMiniPaletteTile(type, isSystem),
                  ),
                ),
              );
            },
          ),
        ),

        // Main Compact Drop Target Canvas Container
        Expanded(
          child: DragTarget<ElementType>(
            onWillAcceptWithDetails: (details) {
              setState(() => _isDraggingOverCanvas = true);
              return true;
            },
            onLeave: (data) {
              setState(() => _isDraggingOverCanvas = false);
            },
            onAcceptWithDetails: (details) {
              setState(() => _isDraggingOverCanvas = false);
              _addNewElementFromType(details.data);
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isDraggingOverCanvas ? Colors.cyanAccent.withOpacity(0.08) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isDraggingOverCanvas ? Colors.cyanAccent : Colors.white12,
                    width: _isDraggingOverCanvas ? 2.0 : 1.0,
                  ),
                ),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  floatingActionButton: FloatingActionButton.small(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    child: const Icon(Icons.add_rounded),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddElementDrawer(
                          onElementSelected: (el) {
                            context.read<ServiceBuilderBloc>().add(AddTemplateElementEvent(el));
                          },
                        ),
                      );
                    },
                  ),
                  body: elements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.move_to_inbox_rounded,
                                size: 40,
                                color: _isDraggingOverCanvas ? Colors.cyanAccent : Colors.white30,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isDraggingOverCanvas ? 'Drop element here!' : 'DRAG & DROP CANVAS DROP ZONE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isDraggingOverCanvas ? Colors.cyanAccent : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Drag mini tiles from top ribbon into this box', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.only(bottom: 60),
                          itemCount: elements.length,
                          onReorder: (oldIdx, newIdx) {
                            context.read<ServiceBuilderBloc>().add(ReorderTemplateElementsEvent(oldIdx, newIdx));
                          },
                          itemBuilder: (context, index) {
                            final element = elements[index];
                            final isSystem = element.category == ElementCategory.system;

                            return Card(
                              key: ValueKey(element.id),
                              color: const Color(0xFF1E293B),
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSystem ? Colors.amber.withOpacity(0.2) : Colors.cyanAccent.withOpacity(0.2),
                                    child: Icon(
                                      isSystem ? Icons.lock_rounded : _getIconForType(element.type),
                                      color: isSystem ? Colors.amber : Colors.cyanAccent,
                                      size: 14,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          element.label,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          element.visibility.name.toUpperCase(),
                                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${element.type.label} • ${element.isRequired ? "Mandatory" : "Optional"}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 16),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => ElementPropertyInspector(
                                              element: element,
                                              onSave: (updated) {
                                                context.read<ServiceBuilderBloc>().add(UpdateElementPropertiesEvent(updated));
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      if (!isSystem)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                          onPressed: () {
                                            context.read<ServiceBuilderBloc>().add(RemoveTemplateElementEvent(element.id));
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPaletteTile(ElementType type, bool isSystem) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSystem ? Colors.amber : Colors.cyanAccent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIconForType(type), color: isSystem ? Colors.amber : Colors.cyanAccent, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditChipDialog({PriceChipModel? chipToEdit}) {
    final labelCtrl = TextEditingController(text: chipToEdit?.label ?? '');
    final countCtrl = TextEditingController(text: chipToEdit?.quantity.toString() ?? '100');
    final priceCtrl = TextEditingController(text: chipToEdit?.price.toStringAsFixed(0) ?? '199');
    bool isPopular = chipToEdit?.isPopular ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.style_rounded, color: Colors.cyan, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                chipToEdit == null ? 'Add Price Chip Package' : 'Edit Chip Package',
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Package Title / Label',
                  hintText: 'e.g. 500 Subscribers Pack',
                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: countCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Quantity / Count',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Price (₹)',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                dense: true,
                title: const Text('Highlight "MOST POPULAR"', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                value: isPopular,
                activeColor: Colors.cyan,
                onChanged: (val) => setDlgState(() => isPopular = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Package', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                final label = labelCtrl.text.trim();
                final count = int.tryParse(countCtrl.text) ?? 100;
                final price = double.tryParse(priceCtrl.text) ?? 199.0;

                if (label.isNotEmpty) {
                  final chip = PriceChipModel(
                    id: chipToEdit?.id ?? 'chip_${DateTime.now().millisecondsSinceEpoch}',
                    label: label,
                    quantity: count,
                    price: price,
                    isPopular: isPopular,
                  );

                  if (chipToEdit == null) {
                    context.read<ServiceBuilderBloc>().add(AddPriceChipEvent(chip));
                  } else {
                    context.read<ServiceBuilderBloc>().add(UpdatePriceChipEvent(chip));
                  }
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingTab(BuildContext context, ServiceEditingState state) {
    final pricing = state.serviceDraft.pricing;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Pricing Model Card
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Service Pricing Model', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('Choose how buyers will be charged for this service.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 10),

                DropdownButtonFormField<PricingModelType>(
                  value: pricing.modelType,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: PricingModelType.values.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m.label));
                  }).toList(),
                  onChanged: (model) {
                    if (model != null) {
                      context.read<ServiceBuilderBloc>().add(UpdatePricingEvent(modelType: model));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // SECTION A: Pre-Configured Chip Package Cards
        if (pricing.modelType == PricingModelType.tieredChips) ...[
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Price Chip Packages', style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Chip Package', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddEditChipDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Buyers can pick from these pre-set cards.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const Divider(color: Colors.white12, height: 16),

                  if (pricing.chips.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('No chip packages added yet. Tap "Add Chip Package" above.',
                            style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pricing.chips.map((chip) {
                        return Container(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: chip.isPopular ? Colors.cyanAccent.withOpacity(0.12) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: chip.isPopular ? Colors.cyanAccent : Colors.white24,
                              width: chip.isPopular ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (chip.isPopular)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('MOST POPULAR', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              Text(chip.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('Count: ${chip.quantity}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              Text('Price: ₹${chip.price.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                              const Divider(color: Colors.white12, height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.cyanAccent, size: 16),
                                    onPressed: () => _showAddEditChipDialog(chipToEdit: chip),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                    onPressed: () {
                                      context.read<ServiceBuilderBloc>().add(RemovePriceChipEvent(chip.id));
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // SECTION B: Count-Based Quantity Unit Rate
        if (pricing.modelType == PricingModelType.countBased) ...[
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Per-Unit Quantity Rate Config', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text('Buyer enters custom quantity (e.g. 500 subscribers). Total = Count * Unit Rate.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const Divider(color: Colors.white12, height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: pricing.unitPrice.toStringAsFixed(1)),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Unit Rate (₹ per count)',
                            labelStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (val) {
                            final uRate = double.tryParse(val) ?? 1.0;
                            context.read<ServiceBuilderBloc>().add(UpdatePricingEvent(unitPrice: uRate));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: pricing.minQuantity.toString()),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Min Quantity',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (val) {
                            final minQ = int.tryParse(val) ?? 1;
                            context.read<ServiceBuilderBloc>().add(UpdatePricingEvent(minQuantity: minQ));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // SECTION C: Fixed Rate / Global Financial Calculation
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Global Financial Margin & Rewards', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white12, height: 16),

                if (pricing.modelType == PricingModelType.fixed) ...[
                  TextField(
                    controller: _buyerPriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Flat Buyer Price (₹)',
                      labelStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Colors.cyanAccent, size: 16),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) {
                      final bPrice = double.tryParse(val) ?? 0.0;
                      context.read<ServiceBuilderBloc>().add(
                            UpdatePricingEvent(buyerPrice: bPrice),
                          );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Admin Margin % Input
                TextField(
                  controller: _marginController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Admin Platform Margin (%)',
                    labelStyle: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                    prefixIcon: const Icon(Icons.percent_rounded, color: Colors.amberAccent, size: 16),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    final margin = double.tryParse(val) ?? 0.0;
                    context.read<ServiceBuilderBloc>().add(
                          UpdatePricingEvent(adminMarginPercent: margin),
                        );
                  },
                ),
                const SizedBox(height: 14),

                // Real-Time Calculated Worker Reward Display Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amberAccent.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated Worker Reward Rate', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Worker reward = Price * (1 - Margin %)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                      Text(
                        '₹${pricing.workerReward.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingTab(BuildContext context, ServiceEditingState state) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        Card(
          color: Color(0xFF1E293B),
          child: Padding(
            padding: EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Task Timing & Execution Duration', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Minimum Execution Time: 60 Seconds', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('• Maximum Execution Time: 86,400 Seconds (24 Hours)', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProofTab(BuildContext context, ServiceEditingState state) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        Card(
          color: Color(0xFF1E293B),
          child: Padding(
            padding: EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Proof Verification Engine Rules', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Screenshot Proof Attachment (Default Mandatory)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('• Automatic Matching Engine & Admin Audit Verification', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
