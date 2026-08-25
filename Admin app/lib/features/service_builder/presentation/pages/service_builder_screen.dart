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
  final String? draftDescription;
  final double? draftBuyerPrice;
  final double? draftMargin;

  const ServiceBuilderScreen({
    super.key,
    this.serviceId,
    this.draftCode,
    this.draftName,
    this.draftDescription,
    this.draftBuyerPrice,
    this.draftMargin,
  });

  @override
  State<ServiceBuilderScreen> createState() => _ServiceBuilderScreenState();
}

class _ServiceBuilderScreenState extends State<ServiceBuilderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _buyerPriceController;
  late TextEditingController _marginController;
  late TextEditingController _unitPriceController;
  late TextEditingController _minQuantityController;
  late TextEditingController _maxQuantityController;
  late TextEditingController _minCompleteHoursController;
  late TextEditingController _maxCompleteHoursController;
  late TextEditingController _workerTimeoutMinutesController;

  final FocusNode _buyerPriceFocusNode = FocusNode();
  final FocusNode _marginFocusNode = FocusNode();
  final FocusNode _unitPriceFocusNode = FocusNode();
  final FocusNode _minQuantityFocusNode = FocusNode();
  final FocusNode _maxQuantityFocusNode = FocusNode();
  final FocusNode _flatWorkerRewardFocusNode = FocusNode();
  final FocusNode _flatWorkerLimitFocusNode = FocusNode();
  final FocusNode _minCompleteHoursFocusNode = FocusNode();
  final FocusNode _maxCompleteHoursFocusNode = FocusNode();
  final FocusNode _workerTimeoutMinutesFocusNode = FocusNode();

  bool _isDraggingOverCanvas = false;
  bool _bootstrapped = false;

  late final TextEditingController _flatWorkerRewardController;
  late final TextEditingController _flatWorkerLimitController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _buyerPriceController = TextEditingController();
    _marginController = TextEditingController();
    _unitPriceController = TextEditingController();
    _minQuantityController = TextEditingController();
    _maxQuantityController = TextEditingController();
    _flatWorkerRewardController = TextEditingController();
    _flatWorkerLimitController = TextEditingController();
    _minCompleteHoursController = TextEditingController();
    _maxCompleteHoursController = TextEditingController();
    _workerTimeoutMinutesController = TextEditingController();

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
            description: widget.draftDescription,
            buyerUnitPrice: widget.draftBuyerPrice,
            adminMarginPercent: widget.draftMargin,
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
    _unitPriceController.dispose();
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    _minCompleteHoursController.dispose();
    _maxCompleteHoursController.dispose();
    _flatWorkerRewardController.dispose();
    _flatWorkerLimitController.dispose();
    _workerTimeoutMinutesController.dispose();
    _buyerPriceFocusNode.dispose();
    _marginFocusNode.dispose();
    _unitPriceFocusNode.dispose();
    _minQuantityFocusNode.dispose();
    _maxQuantityFocusNode.dispose();
    _flatWorkerRewardFocusNode.dispose();
    _flatWorkerLimitFocusNode.dispose();
    _minCompleteHoursFocusNode.dispose();
    _maxCompleteHoursFocusNode.dispose();
    _workerTimeoutMinutesFocusNode.dispose();
    super.dispose();
  }

  void _syncPricingControllers(ServiceEditingState state) {
    final p = state.serviceDraft.pricing;
    final s = state.serviceDraft;

    final buyerStr = p.buyerPrice > 0 ? (p.buyerPrice == p.buyerPrice.roundToDouble() ? p.buyerPrice.toStringAsFixed(0) : p.buyerPrice.toString()) : '';
    final marginStr = p.adminMarginPercent > 0 ? (p.adminMarginPercent == p.adminMarginPercent.roundToDouble() ? p.adminMarginPercent.toStringAsFixed(0) : p.adminMarginPercent.toString()) : '';
    final unitStr = p.unitPrice > 0 ? (p.unitPrice == p.unitPrice.roundToDouble() ? p.unitPrice.toStringAsFixed(0) : p.unitPrice.toString()) : '';
    final minQStr = p.minQuantity > 0 ? p.minQuantity.toString() : '1';
    final maxQStr = p.maxQuantity > 0 ? p.maxQuantity.toString() : '10000';
    final workerRewardStr = p.workerReward > 0 ? (p.workerReward == p.workerReward.roundToDouble() ? p.workerReward.toStringAsFixed(0) : p.workerReward.toString()) : '';
    final workerLimitStr = s.workerLimit > 0 ? s.workerLimit.toString() : '1';
    final minHStr = s.minCompleteHours > 0 ? s.minCompleteHours.toString() : '24';
    final maxHStr = s.maxCompleteHours > 0 ? s.maxCompleteHours.toString() : '72';
    final workerTOStr = (s.maxDurationSeconds > 0 ? (s.maxDurationSeconds ~/ 60) : 60).toString();

    if (!_buyerPriceFocusNode.hasFocus && _buyerPriceController.text != buyerStr) {
      _buyerPriceController.text = buyerStr;
    }
    if (!_marginFocusNode.hasFocus && _marginController.text != marginStr) {
      _marginController.text = marginStr;
    }
    if (!_unitPriceFocusNode.hasFocus && _unitPriceController.text != unitStr) {
      _unitPriceController.text = unitStr;
    }
    if (!_minQuantityFocusNode.hasFocus && _minQuantityController.text != minQStr) {
      _minQuantityController.text = minQStr;
    }
    if (!_maxQuantityFocusNode.hasFocus && _maxQuantityController.text != maxQStr) {
      _maxQuantityController.text = maxQStr;
    }
    if (!_flatWorkerRewardFocusNode.hasFocus && _flatWorkerRewardController.text != workerRewardStr) {
      _flatWorkerRewardController.text = workerRewardStr;
    }
    if (!_flatWorkerLimitFocusNode.hasFocus && _flatWorkerLimitController.text != workerLimitStr) {
      _flatWorkerLimitController.text = workerLimitStr;
    }
    if (!_minCompleteHoursFocusNode.hasFocus && _minCompleteHoursController.text != minHStr) {
      _minCompleteHoursController.text = minHStr;
    }
    if (!_maxCompleteHoursFocusNode.hasFocus && _maxCompleteHoursController.text != maxHStr) {
      _maxCompleteHoursController.text = maxHStr;
    }
    if (!_workerTimeoutMinutesFocusNode.hasFocus && _workerTimeoutMinutesController.text != workerTOStr) {
      _workerTimeoutMinutesController.text = workerTOStr;
    }
  }

  void _showEditServiceBasicInfoDialog(dynamic service) {
    final nameCtrl = TextEditingController(text: service.name);
    final descCtrl = TextEditingController(text: service.description);
    final videoCtrl = TextEditingController(text: service.videoTutorialUrl ?? '');
    final audioCtrl = TextEditingController(text: service.audioGuideUrl ?? '');
    final instructionsCtrl = TextEditingController(text: service.adminInstructions ?? service.description ?? '');
    final linkLabelCtrl = TextEditingController(text: service.linkFieldLabel ?? 'Target Link / URL');
    final textLabelCtrl = TextEditingController(text: service.textFieldLabel ?? 'Custom Text / Instructions');
    int selectedWatchTime = service.watchtimeSeconds ?? 0;

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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'Service & Guidance Controls',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Service Title & Overview
                  const Text('1. Service Basic Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Service Name / Title',
                      labelStyle: const TextStyle(color: AppColors.primary, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Short Description for Buyer App',
                      labelStyle: const TextStyle(color: Colors.black54, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Worker Media & Guidance
                  const Text('2. Worker Media & Instructions (Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED))),
                  const SizedBox(height: 4),
                  const Text('Tutorial video & voice guides are shown exclusively to workers on their task execution screen.',
                      style: TextStyle(color: Colors.black54, fontSize: 11)),
                  const SizedBox(height: 10),

                  // YouTube Video Tutorial Input
                  TextField(
                    controller: videoCtrl,
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                    onChanged: (_) => setDlgState(() {}),
                    decoration: InputDecoration(
                      labelText: 'YouTube Tutorial / Video URL (For Workers)',
                      hintText: 'https://youtube.com/watch?v=... or https://youtu.be/...',
                      prefixIcon: const Icon(Icons.video_library_rounded, color: Colors.red, size: 18),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Quick Video Presets
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        label: const Text('YouTube Tutorial Sample', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        avatar: const Icon(Icons.play_circle_filled_rounded, color: Colors.red, size: 14),
                        onPressed: () {
                          setDlgState(() {
                            videoCtrl.text = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
                          });
                        },
                      ),
                      if (videoCtrl.text.isNotEmpty)
                        ActionChip(
                          label: const Text('Clear Video', style: TextStyle(fontSize: 10, color: Colors.red)),
                          avatar: const Icon(Icons.close_rounded, color: Colors.red, size: 14),
                          onPressed: () {
                            setDlgState(() => videoCtrl.clear());
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Audio Guide / Voice Note Input
                  TextField(
                    controller: audioCtrl,
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                    onChanged: (_) => setDlgState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Voice Audio Guide URL (Cloudflare R2 / Server)',
                      hintText: 'https://media.earnpost.workers.dev/audio/... or server URL',
                      prefixIcon: const Icon(Icons.record_voice_over_rounded, color: Colors.indigo, size: 18),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Quick Voice Guide Creator & Presets
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        backgroundColor: const Color(0xFFEEF2FF),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        label: const Text('🎙️ Cloudflare / Server Voice Sample',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                        onPressed: () {
                          setDlgState(() {
                            audioCtrl.text = 'http://95.179.178.6:3000/api/v1/files/raw/sample_audio_guide.m4a';
                          });
                        },
                      ),
                      if (audioCtrl.text.isNotEmpty)
                        ActionChip(
                          label: const Text('Clear Audio', style: TextStyle(fontSize: 10, color: Colors.red)),
                          avatar: const Icon(Icons.close_rounded, color: Colors.red, size: 14),
                          onPressed: () {
                            setDlgState(() => audioCtrl.clear());
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Step-by-step guidance
                  TextField(
                    controller: instructionsCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Step-by-Step Instructions for Workers',
                      hintText: '1. Open link\n2. Subscribe to channel\n3. Take screenshot proof',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Template Presets for Instructions
                  Wrap(
                    spacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('YouTube Template', style: TextStyle(fontSize: 10)),
                        onPressed: () {
                          setDlgState(() {
                            instructionsCtrl.text = '1. Open YouTube link.\n2. Watch at least 60 seconds.\n3. Hit Subscribe & Bell icon.\n4. Take screenshot and upload proof.';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Telegram Template', style: TextStyle(fontSize: 10)),
                        onPressed: () {
                          setDlgState(() {
                            instructionsCtrl.text = '1. Open Telegram link.\n2. Click "Join Channel".\n3. Do not mute or leave.\n4. Take screenshot showing "Mute" status.';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Buyer Form Field Customization
                  const Text('3. Buyer Form Input Labels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF059669))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: linkLabelCtrl,
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Target Link Field Label (Buyer Form)',
                      hintText: 'e.g. YouTube Video Link, Channel Link',
                      prefixIcon: const Icon(Icons.link_rounded, color: Colors.blue, size: 18),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textLabelCtrl,
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Custom Text Field Label (Buyer Form)',
                      hintText: 'e.g. Comment Text to Post, Search Keywords',
                      prefixIcon: const Icon(Icons.text_fields_rounded, color: Colors.teal, size: 18),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Watch Time Selection
                  const Text('4. Required Watch Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('None (0s)'),
                        selected: selectedWatchTime == 0,
                        onSelected: (val) => setDlgState(() => selectedWatchTime = 0),
                      ),
                      ChoiceChip(
                        label: const Text('60 Seconds'),
                        selected: selectedWatchTime == 60,
                        onSelected: (val) => setDlgState(() => selectedWatchTime = 60),
                      ),
                      ChoiceChip(
                        label: const Text('120 Seconds'),
                        selected: selectedWatchTime == 120,
                        onSelected: (val) => setDlgState(() => selectedWatchTime = 120),
                      ),
                      ChoiceChip(
                        label: const Text('300 Seconds'),
                        selected: selectedWatchTime == 300,
                        onSelected: (val) => setDlgState(() => selectedWatchTime = 300),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
              child: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  context.read<ServiceBuilderBloc>().add(
                        UpdateServiceInfoEvent(
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          videoTutorialUrl: videoCtrl.text.trim(),
                          audioGuideUrl: audioCtrl.text.trim(),
                          adminInstructions: instructionsCtrl.text.trim(),
                          linkFieldLabel: linkLabelCtrl.text.trim(),
                          textFieldLabel: textLabelCtrl.text.trim(),
                          watchtimeSeconds: selectedWatchTime,
                        ),
                      );
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
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

  void _showDeleteServiceConfirmation(BuildContext context, String serviceName, String serviceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Delete Service?',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$serviceName"',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Past campaigns & orders will NOT be affected.',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This service will be removed from the catalog and no new orders can be created for it.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ServiceBuilderBloc>().add(DeleteServiceEvent(serviceId));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServiceBuilderBloc, ServiceBuilderState>(
      listener: (context, state) {
        if (state is ServiceDeletedState) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
        }
        if (state is ServiceEditingState) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.successMessage!,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.cyanAccent,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
                          Text('Version V${service.currentVersion}',
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
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Delete Service',
                  onPressed: () => _showDeleteServiceConfirmation(context, service.name, service.id),
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
        // Admin-Controlled Service Title & Description Summary Card
        Container(
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.design_services_rounded, color: Colors.cyanAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            state.serviceDraft.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'V${state.serviceDraft.currentVersion}',
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.serviceDraft.description.isNotEmpty ? state.serviceDraft.description : 'No description set by admin yet.',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 14),
                label: const Text('Edit Info', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _showEditServiceBasicInfoDialog(state.serviceDraft),
              ),
            ],
          ),
        ),
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
                                   onTap: () {
                                     showModalBottomSheet(
                                       context: context,
                                       isScrollControlled: true,
                                       backgroundColor: Colors.transparent,
                                       builder: (_) => ElementPropertyInspector(
                                         element: element,
                                         onSave: (updated) {
                                            context.read<ServiceBuilderBloc>().add(UpdateElementPropertiesEvent(updated));
                                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        '✓ "${updated.label}" Settings Saved!',
                                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: Colors.cyanAccent,
                                                behavior: SnackBarBehavior.floating,
                                                duration: const Duration(seconds: 2),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            );
                                         },
                                       ),
                                     );
                                   },
                                   leading: CircleAvatar(
                                     radius: 14,
                                     backgroundColor: isSystem
                                         ? Colors.amber.withOpacity(0.2)
                                         : (element.type == ElementType.youtube
                                             ? Colors.redAccent.withOpacity(0.2)
                                             : (element.type == ElementType.audio
                                                 ? Colors.indigoAccent.withOpacity(0.2)
                                                 : Colors.cyanAccent.withOpacity(0.2))),
                                     child: Icon(
                                       isSystem ? Icons.lock_rounded : _getIconForType(element.type),
                                       color: isSystem
                                           ? Colors.amber
                                           : (element.type == ElementType.youtube
                                               ? Colors.redAccent
                                               : (element.type == ElementType.audio ? Colors.indigoAccent : Colors.cyanAccent)),
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
                                      () {
                                        if (element.type == ElementType.heading) {
                                          return '📌 Admin Defined Header • Fixed on Campaign';
                                        } else if (element.type == ElementType.paragraph) {
                                          return '📄 Admin Instructions & Guidelines for Workers';
                                        } else if (element.type == ElementType.numberField) {
                                          return '🔢 Buyer Quantity / Count Input (e.g. 100, 500)';
                                        } else if (element.type == ElementType.actionButton) {
                                          return '🔗 Target Action Link (Redirects Worker)';
                                        } else if (element.type == ElementType.youtube) {
                                          final hasUrl = element.properties['url'] != null && element.properties['url'].toString().isNotEmpty;
                                          return hasUrl ? '🎬 YouTube Video Attached (Tap to Edit/Change)' : '🎬 Tap to Set YouTube Link';
                                        } else if (element.type == ElementType.audio) {
                                          final hasUrl = element.properties['url'] != null && element.properties['url'].toString().isNotEmpty;
                                          return hasUrl ? '🎙️ Voice Guide Attached (Tap to Listen/Record)' : '🎙️ Tap to Record Voice Guide';
                                        } else if (element.type == ElementType.systemProof) {
                                          return '🛡️ Worker Proof Verification Rules';
                                        } else if (element.type == ElementType.systemTimer) {
                                          final dur = element.properties['durationSeconds'] ?? 60;
                                          return '⏱️ Task Watch Timer (${dur}s)';
                                        }
                                        return '${element.type.label} • ${element.isRequired ? "Mandatory" : "Optional"}';
                                      }(),
                                      style: TextStyle(
                                        color: (element.type == ElementType.youtube || element.type == ElementType.audio || element.type == ElementType.heading)
                                            ? Colors.cyanAccent
                                            : Colors.white54,
                                        fontSize: 10,
                                        fontWeight: (element.type == ElementType.youtube || element.type == ElementType.audio || element.type == ElementType.heading)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
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
                                                 ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                 ScaffoldMessenger.of(context).showSnackBar(
                                                   SnackBar(
                                                     content: Row(
                                                       children: [
                                                         const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                                                         const SizedBox(width: 8),
                                                         Expanded(
                                                           child: Text(
                                                             '✓ "${updated.label}" Settings Saved!',
                                                             style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                     backgroundColor: Colors.cyanAccent,
                                                     behavior: SnackBarBehavior.floating,
                                                     duration: const Duration(seconds: 2),
                                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                   ),
                                                 );
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
                final count = int.tryParse(countCtrl.text) ?? 1;
                final price = double.tryParse(priceCtrl.text) ?? 0.0;

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
    final bloc = context.read<ServiceBuilderBloc>();

    // Calculate live financial numbers
    final double baseRate = pricing.modelType == PricingModelType.countBased
        ? (pricing.unitPrice > 0 ? pricing.unitPrice : pricing.buyerPrice)
        : (pricing.modelType == PricingModelType.tieredChips && pricing.chips.isNotEmpty
            ? pricing.chips.first.price
            : pricing.buyerPrice);

    final double marginAmount = pricing.marginType.toUpperCase() == 'FIXED'
        ? pricing.adminMarginPercent
        : (baseRate * (pricing.adminMarginPercent / 100.0));

    final double workerReward = (baseRate - marginAmount) < 0 ? 0.0 : (baseRate - marginAmount);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 1. Pricing Model Selection Card
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Select Pricing Model', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Choose how buyers will be charged for this service.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 12),

                DropdownButtonFormField<PricingModelType>(
                  value: pricing.modelType,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: PricingModelType.values.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m.label));
                  }).toList(),
                  onChanged: (model) {
                    if (model != null) {
                      bloc.add(UpdatePricingEvent(modelType: model));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Count-Based Quantity Unit Rate Config (Most Common & Requested)
        if (pricing.modelType == PricingModelType.countBased) ...[
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_rounded, color: Colors.cyanAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Per-Unit Rate & Quantity Settings', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Buyer chooses count (e.g. 500 subscribers). Total Cost = Count × Unit Rate.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  const Divider(color: Colors.white12, height: 20),

                  // Unit Rate Input
                  const Text('Buyer Unit Rate (₹ per 1 task/action) *', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _unitPriceController,
                    focusNode: _unitPriceFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'e.g. 0.50, 1.00, 2.50',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      final uRate = double.tryParse(val) ?? 0.0;
                      bloc.add(UpdatePricingEvent(unitPrice: uRate, buyerPrice: uRate));
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quick Preset Chips for Unit Rate
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [0.20, 0.50, 1.0, 1.5, 2.0, 5.0, 10.0].map((preset) {
                      final isSelected = (pricing.unitPrice == preset);
                      return ActionChip(
                        label: Text('₹${preset < 1 ? preset.toStringAsFixed(2) : preset.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            )),
                        backgroundColor: isSelected ? Colors.cyanAccent : const Color(0xFF0F172A),
                        side: BorderSide(color: isSelected ? Colors.cyanAccent : Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: () {
                          _unitPriceController.text = preset < 1 ? preset.toStringAsFixed(2) : preset.toStringAsFixed(0);
                          bloc.add(UpdatePricingEvent(unitPrice: preset, buyerPrice: preset));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Min & Max Quantity Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Min Quantity *', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _minQuantityController,
                              focusNode: _minQuantityFocusNode,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: '10, 50, 100',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              onChanged: (val) {
                                final minQ = int.tryParse(val) ?? 1;
                                bloc.add(UpdatePricingEvent(minQuantity: minQ));
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Max Quantity', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _maxQuantityController,
                              focusNode: _maxQuantityFocusNode,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: '10000, 50000',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              onChanged: (val) {
                                final maxQ = int.tryParse(val) ?? 10000;
                                bloc.add(UpdatePricingEvent(maxQuantity: maxQ));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Min Quantity Presets
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [10, 25, 50, 100, 500, 1000].map((preset) {
                      final isSelected = (pricing.minQuantity == preset);
                      return ActionChip(
                        label: Text('$preset min',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            )),
                        backgroundColor: isSelected ? Colors.amberAccent : const Color(0xFF0F172A),
                        side: BorderSide(color: isSelected ? Colors.amberAccent : Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: () {
                          _minQuantityController.text = preset.toString();
                          bloc.add(UpdatePricingEvent(minQuantity: preset));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 3. Pre-Configured Chip Package Cards
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
                        label: const Text('Add Package', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddEditChipDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Buyers can pick from these pre-set package cards.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const Divider(color: Colors.white12, height: 16),

                  if (pricing.chips.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('No chip packages added yet. Tap "Add Package" above.',
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
                                      bloc.add(RemovePriceChipEvent(chip.id));
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
          const SizedBox(height: 12),
        ],

        // 4. Fixed Price Flat Rate
        if (pricing.modelType == PricingModelType.fixed) ...[
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Flat Rate & Worker Allocation Config', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Configure flat buyer price, how many workers will be assigned, and worker reward per task.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const Divider(color: Colors.white12, height: 16),

                  // 1. Flat Buyer Price
                  const Text('Flat Buyer Price (₹ Total Charged to Buyer) *', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _buyerPriceController,
                    focusNode: _buyerPriceFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'e.g. 50, 100, 500',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      final bPrice = double.tryParse(val) ?? 0.0;
                      bloc.add(UpdatePricingEvent(buyerPrice: bPrice, unitPrice: bPrice));
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. Worker Reward per Task
                  const Text('Worker Reward Per Task (₹ Har Worker Ko Kitna Milega) *', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _flatWorkerRewardController,
                    focusNode: _flatWorkerRewardFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Color(0xFF00875A), fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'e.g. 2.00, 4.00, 5.00',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Color(0xFF00875A), fontWeight: FontWeight.bold, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      final wReward = double.tryParse(val) ?? 0.0;
                      bloc.add(UpdatePricingEvent(workerReward: wReward));
                    },
                  ),
                  const SizedBox(height: 12),

                  // Auto Worker Allocation Info Note
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Colors.cyanAccent, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Auto Worker Allocation: Order quantity ke according automatically workers assign honge (1 Task = 1 Unique Worker).',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 5. Global Admin Margin & Platform Profit Config
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, color: Colors.amberAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Admin Margin & Platform Fee', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Platform margin is deducted from the buyer price, and the rest is paid to the worker.',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                const Divider(color: Colors.white12, height: 16),

                // Margin % Input
                TextField(
                  controller: _marginController,
                  focusNode: _marginFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Admin Margin (%) *',
                    labelStyle: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                    prefixIcon: const Icon(Icons.percent_rounded, color: Colors.amberAccent, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    final margin = double.tryParse(val) ?? 0.0;
                    bloc.add(UpdatePricingEvent(adminMarginPercent: margin));
                  },
                ),
                const SizedBox(height: 8),

                // Quick Margin Presets
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [10.0, 15.0, 20.0, 25.0, 30.0, 40.0].map((preset) {
                    final isSelected = (pricing.adminMarginPercent == preset);
                    return ActionChip(
                      label: Text('${preset.toInt()}%',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          )),
                      backgroundColor: isSelected ? Colors.amberAccent : const Color(0xFF0F172A),
                      side: BorderSide(color: isSelected ? Colors.amberAccent : Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () {
                        _marginController.text = preset.toInt().toString();
                        bloc.add(UpdatePricingEvent(adminMarginPercent: preset));
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 6. LIVE INTERACTIVE FINANCIAL BREAKDOWN & WORKER REWARD CARD
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights_rounded, color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Live Financial Breakdown (Per Task)',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3-Pillar Summary Cards (Buyer Pays, Admin Margin, Worker Reward)
              Row(
                children: [
                  // Pillar 1: Buyer Pays
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Buyer Pays', style: TextStyle(color: Colors.white54, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text('₹${baseRate.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const Text('Per Task', style: TextStyle(color: Colors.white38, fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Pillar 2: Admin Margin
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Admin Cut', style: TextStyle(color: Colors.amberAccent, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text('₹${marginAmount.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${pricing.adminMarginPercent.toStringAsFixed(0)}% Margin', style: const TextStyle(color: Colors.amber, fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Pillar 3: Worker Reward
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.cyanAccent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Worker Gets', style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('₹${workerReward.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                          const Text('Per Worker', style: TextStyle(color: Colors.cyanAccent, fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),

              // Simulated Campaign Example
              const Text('📊 Example Campaign Simulation (100 Tasks):',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Buyer Payment:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('₹${(baseRate * 100).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Platform Profit (Admin):', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                        Text('₹${(marginAmount * 100).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Worker Payout Pool (100 Workers):', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                        Text('₹${(workerReward * 100).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTimingTab(BuildContext context, ServiceEditingState state) {
    final service = state.serviceDraft;
    final bloc = context.read<ServiceBuilderBloc>();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Card 1: Buyer Delivery Timeline SLA Window (Min & Max Hours)
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Colors.cyanAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Buyer Delivery Timeline Window (Hours)',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Set minimum and maximum hours required to fulfill orders for this service.',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                const Divider(color: Colors.white12, height: 20),

                // Min Delivery Hours
                const Row(
                  children: [
                    Text('Minimum Delivery Time (Hours) *',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(width: 6),
                    Text('(Buyer cannot expect faster than this)',
                        style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _minCompleteHoursController,
                  focusNode: _minCompleteHoursFocusNode,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'e.g. 12, 24, 40, 48, 50',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    suffixText: 'Hours',
                    suffixStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    final h = int.tryParse(val) ?? 24;
                    bloc.add(UpdateTimingRulesEvent(minCompleteHours: h));
                  },
                ),
                const SizedBox(height: 8),

                // Quick Presets for Min Hours
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [6, 12, 24, 40, 48, 50, 72].map((preset) {
                    final isSelected = (service.minCompleteHours == preset);
                    return ActionChip(
                      label: Text('$preset Hours',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.cyanAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          )),
                      backgroundColor: isSelected ? Colors.cyanAccent : const Color(0xFF0F172A),
                      side: BorderSide(color: isSelected ? Colors.cyanAccent : Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () {
                        _minCompleteHoursController.text = preset.toString();
                        bloc.add(UpdateTimingRulesEvent(minCompleteHours: preset));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Max Delivery Hours
                const Row(
                  children: [
                    Text('Maximum Delivery Time (Hours) *',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(width: 6),
                    Text('(Upper completion ceiling)',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _maxCompleteHoursController,
                  focusNode: _maxCompleteHoursFocusNode,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'e.g. 48, 72, 100, 120, 168',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    suffixText: 'Hours',
                    suffixStyle: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    final h = int.tryParse(val) ?? 72;
                    bloc.add(UpdateTimingRulesEvent(maxCompleteHours: h));
                  },
                ),
                const SizedBox(height: 8),

                // Quick Presets for Max Hours
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [24, 48, 72, 120, 168, 240].map((preset) {
                    final isSelected = (service.maxCompleteHours == preset);
                    return ActionChip(
                      label: Text(preset >= 24 ? '${preset ~/ 24} Days ($preset h)' : '$preset Hours',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          )),
                      backgroundColor: isSelected ? Colors.amberAccent : const Color(0xFF0F172A),
                      side: BorderSide(color: isSelected ? Colors.amberAccent : Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () {
                        _maxCompleteHoursController.text = preset.toString();
                        bloc.add(UpdateTimingRulesEvent(maxCompleteHours: preset));
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Card 2: Worker Task Execution Proof Timeout (Per Individual Task)
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_rounded, color: Colors.amberAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Worker Task Execution Timeout',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('How much time a worker gets to perform the task & submit proof after accepting.',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                const Divider(color: Colors.white12, height: 20),

                const Text('Worker Proof Submission Timeout (Minutes) *',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _workerTimeoutMinutesController,
                  focusNode: _workerTimeoutMinutesFocusNode,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'e.g. 15, 30, 60, 120',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    suffixText: 'Minutes',
                    suffixStyle: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    final mins = int.tryParse(val) ?? 60;
                    bloc.add(UpdateTimingRulesEvent(maxDurationSeconds: mins * 60));
                  },
                ),
                const SizedBox(height: 8),

                // Quick Presets for Worker Timeout
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [15, 30, 60, 120, 240, 1440].map((preset) {
                    final isSelected = (service.maxDurationSeconds == preset * 60);
                    return ActionChip(
                      label: Text(preset >= 60 ? '${preset ~/ 60} Hour${preset >= 120 ? "s" : ""}' : '$preset min',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          )),
                      backgroundColor: isSelected ? Colors.amberAccent : const Color(0xFF0F172A),
                      side: BorderSide(color: isSelected ? Colors.amberAccent : Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () {
                        _workerTimeoutMinutesController.text = preset.toString();
                        bloc.add(UpdateTimingRulesEvent(maxDurationSeconds: preset * 60));
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Card 3: Live SLA Rules & Anti-Abuse Protection Summary
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Service Timing Policy & Protection Rules',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),

              // Rule Item 1: Buyer SLA
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.cyanAccent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Buyer Instant Delivery Block',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            'Buyers cannot expect instant completion (e.g. 5 minutes). Minimum delivery expectation is strictly locked at ${service.minCompleteHours} Hours.',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Rule Item 2: Max Delivery & Worker Window
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: Colors.amberAccent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order SLA: ${service.minCompleteHours}h to ${service.maxCompleteHours}h Window',
                              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            'Each worker has ${service.maxDurationSeconds ~/ 60} Minutes to complete and submit proof once accepted.',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
