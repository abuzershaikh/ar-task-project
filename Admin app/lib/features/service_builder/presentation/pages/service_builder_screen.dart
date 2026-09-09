import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/service_builder_bloc.dart';
import '../bloc/service_builder_event.dart';
import '../bloc/service_builder_state.dart';
import '../widgets/buyer_worker_preview_modal.dart';
import '../widgets/voice_guide_studio_card.dart';
import '../../domain/models/service_model.dart';

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

class _ServiceBuilderScreenState extends State<ServiceBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _buyerPriceController;
  late TextEditingController _marginController;
  late TextEditingController _minQuantityController;
  late TextEditingController _maxQuantityController;
  late TextEditingController _minAcceptHoursController;
  late TextEditingController _maxAcceptHoursController;
  late TextEditingController _minCompleteHoursController;
  late TextEditingController _maxCompleteHoursController;
  late TextEditingController _linkFieldLabelController;
  late TextEditingController _linkFieldPlaceholderController;
  late TextEditingController _textFieldLabelController;
  late TextEditingController _textFieldPlaceholderController;
  late TextEditingController _adminInstructionsController;
  late TextEditingController _videoUrlController;
  late TextEditingController _audioUrlController;
  late TextEditingController _minRetentionHoursController;

  // State flags
  bool _isLinkFieldEnabled = true;
  bool _isTextFieldEnabled = false;
  bool _requiresScreenshot = true;
  bool _requiresTextProof = false;
  int _watchtimeSeconds = 0;
  String _reviewMode = 'buyer';
  bool _isPercentageMargin = false;
  bool _bootstrapped = false;

  // AI Generator Settings
  bool _aiGeneratorEnabled = false;
  String _aiLanguage = 'English';
  String _aiTone = 'natural';
  bool _aiUniqueness = true;

  // Professional Blue & White Theme Palette
  static const Color primaryBlue = Color(0xFF1E40AF); // Deep Royal Blue
  static const Color accentBlue = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color lightBlueBg = Color(0xFFEFF6FF); // Soft Blue Tint
  static const Color surfaceWhite = Colors.white;
  static const Color backgroundLight = Color(0xFFF8FAFC); // Clean Light Slate
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate
  static const Color textSecondary = Color(0xFF64748B); // Slate Muted
  static const Color borderSubtle = Color(0xFFE2E8F0); // Subtle Border

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _codeController = TextEditingController(text: widget.draftCode ?? '');
    _nameController = TextEditingController(text: widget.draftName ?? '');
    _descController =
        TextEditingController(text: widget.draftDescription ?? '');
    _buyerPriceController = TextEditingController(
        text: widget.draftBuyerPrice != null
            ? widget.draftBuyerPrice.toString()
            : '5.0');
    _marginController = TextEditingController(
        text:
            widget.draftMargin != null ? widget.draftMargin.toString() : '1.5');
    _minQuantityController = TextEditingController(text: '10');
    _maxQuantityController = TextEditingController(text: '10000');
    _minAcceptHoursController = TextEditingController(text: '1');
    _maxAcceptHoursController = TextEditingController(text: '72');
    _minCompleteHoursController = TextEditingController(text: '1');
    _maxCompleteHoursController = TextEditingController(text: '168');
    _linkFieldLabelController =
        TextEditingController(text: 'Target Link / URL');
    _linkFieldPlaceholderController =
        TextEditingController(text: 'https://...');
    _textFieldLabelController =
        TextEditingController(text: 'Custom Instructions / Text');
    _textFieldPlaceholderController = TextEditingController(
        text: 'Enter instructions, comments or proof details...');
    _adminInstructionsController = TextEditingController();
    _videoUrlController = TextEditingController();
    _audioUrlController = TextEditingController();
    _minRetentionHoursController = TextEditingController(text: '24');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bootstrapped) return;
      _bootstrapped = true;

      final bloc = context.read<ServiceBuilderBloc>();
      if (widget.serviceId != null && widget.serviceId!.isNotEmpty) {
        bloc.add(SelectServiceForEditEvent(widget.serviceId!));
      } else if (widget.draftCode != null && widget.draftName != null) {
        bloc.add(
          CreateNewServiceDraftEvent(
            code: widget.draftCode!,
            name: widget.draftName!,
            description: widget.draftDescription,
            buyerUnitPrice: widget.draftBuyerPrice,
            adminMarginPercent: widget.draftMargin,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _buyerPriceController.dispose();
    _marginController.dispose();
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    _minAcceptHoursController.dispose();
    _maxAcceptHoursController.dispose();
    _minCompleteHoursController.dispose();
    _maxCompleteHoursController.dispose();
    _linkFieldLabelController.dispose();
    _linkFieldPlaceholderController.dispose();
    _textFieldLabelController.dispose();
    _textFieldPlaceholderController.dispose();
    _adminInstructionsController.dispose();
    _videoUrlController.dispose();
    _audioUrlController.dispose();
    _minRetentionHoursController.dispose();
    super.dispose();
  }

  void _populateFromService(ServiceModel service) {
    if (_codeController.text.isEmpty) _codeController.text = service.code;
    if (service.name.isNotEmpty) _nameController.text = service.name;
    if (_descController.text.isEmpty)
      _descController.text = service.description;
    _buyerPriceController.text = service.pricing.buyerPrice.toString();
    _marginController.text = service.pricing.adminMarginPercent.toString();
    _isPercentageMargin =
        service.pricing.marginType.toUpperCase().contains('PERCENT');
    _minQuantityController.text = service.pricing.minQuantity.toString();
    _maxQuantityController.text = service.pricing.maxQuantity.toString();
    _minAcceptHoursController.text = service.minAcceptHours.toString();
    _maxAcceptHoursController.text = service.maxAcceptHours.toString();
    _minCompleteHoursController.text = service.minCompleteHours.toString();
    _maxCompleteHoursController.text = service.maxCompleteHours.toString();
    _minRetentionHoursController.text = service.minDurationSeconds > 0
        ? (service.minDurationSeconds ~/ 3600).toString()
        : '24';
    _linkFieldLabelController.text =
        service.linkFieldLabel ?? 'Target Link / URL';
    _linkFieldPlaceholderController.text =
        service.linkFieldPlaceholder ?? 'https://...';
    _textFieldLabelController.text =
        service.textFieldLabel ?? 'Custom Instructions / Text';
    _textFieldPlaceholderController.text = service.textFieldPlaceholder ?? '';
    _adminInstructionsController.text = service.adminInstructions ?? '';
    _videoUrlController.text = service.videoTutorialUrl ?? '';
    _audioUrlController.text = service.audioGuideUrl ?? '';

    _watchtimeSeconds = service.watchtimeSeconds;
    _reviewMode = service.reviewMode;
    _requiresScreenshot = service.requiresProofScreenshot;
    _requiresTextProof = service.requiresProofText;

    _aiGeneratorEnabled = service.aiGeneratorEnabled;
    if (service.aiGeneratorConfig != null) {
      _aiLanguage =
          service.aiGeneratorConfig!['language']?.toString() ?? 'English';
      _aiTone = service.aiGeneratorConfig!['tone']?.toString() ?? 'natural';
      _aiUniqueness = service.aiGeneratorConfig!['uniqueness'] == true ||
          service.aiGeneratorConfig!['unique'] == true ||
          service.aiGeneratorConfig!['uniqueness'] == null;
    }
  }

  double _getCalculatedWorkerReward() {
    final buyerPrice = double.tryParse(_buyerPriceController.text) ?? 0.0;
    final margin = double.tryParse(_marginController.text) ?? 0.0;
    if (_isPercentageMargin) {
      final reward = buyerPrice * (1.0 - (margin / 100.0));
      return reward > 0 ? double.parse(reward.toStringAsFixed(2)) : 0.0;
    } else {
      final reward = buyerPrice - margin;
      return reward > 0 ? double.parse(reward.toStringAsFixed(2)) : 0.0;
    }
  }

  void _saveAndPublish(BuildContext context, bool publish) {
    final bloc = context.read<ServiceBuilderBloc>();

    // 1. Update Info
    bloc.add(
      UpdateServiceInfoEvent(
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : (widget.draftName?.trim().isNotEmpty == true
                ? widget.draftName!.trim()
                : 'Service'),
        description: _descController.text.trim(),
        category:
            _codeController.text.startsWith('YOUTUBE') ? 'YouTube' : 'General',
        serviceType: _codeController.text.contains('COMMENT')
            ? 'comment'
            : (_codeController.text.contains('LIKE')
                ? 'like'
                : (_codeController.text.contains('SUBSCRIBE')
                    ? 'subscribe'
                    : (_codeController.text.contains('COMBO')
                        ? 'combo'
                        : 'custom'))),
        aiGeneratorEnabled: _aiGeneratorEnabled,
        aiGeneratorConfig: {
          'language': _aiLanguage,
          'tone': _aiTone,
          'uniqueness': _aiUniqueness,
        },
        videoTutorialUrl: _videoUrlController.text.trim().isNotEmpty
            ? _videoUrlController.text.trim()
            : null,
        audioGuideUrl: _audioUrlController.text.trim().isNotEmpty
            ? _audioUrlController.text.trim()
            : null,
        adminInstructions: _adminInstructionsController.text.trim().isNotEmpty
            ? _adminInstructionsController.text.trim()
            : null,
        linkFieldLabel:
            _isLinkFieldEnabled ? _linkFieldLabelController.text.trim() : null,
        linkFieldPlaceholder: _isLinkFieldEnabled
            ? _linkFieldPlaceholderController.text.trim()
            : null,
        textFieldLabel:
            _isTextFieldEnabled ? _textFieldLabelController.text.trim() : null,
        textFieldPlaceholder: _isTextFieldEnabled
            ? _textFieldPlaceholderController.text.trim()
            : null,
        watchtimeSeconds: _watchtimeSeconds,
      ),
    );

    // 2. Update Pricing
    final buyerPrice = double.tryParse(_buyerPriceController.text) ?? 0.0;
    final margin = double.tryParse(_marginController.text) ?? 0.0;
    final workerReward = _getCalculatedWorkerReward();
    final minQty = int.tryParse(_minQuantityController.text) ?? 10;
    final maxQty = int.tryParse(_maxQuantityController.text) ?? 10000;

    bloc.add(
      UpdatePricingEvent(
        buyerPrice: buyerPrice,
        unitPrice: buyerPrice,
        adminMarginPercent: margin,
        marginType: _isPercentageMargin ? 'PERCENTAGE' : 'FIXED',
        workerReward: workerReward,
        minQuantity: minQty,
        maxQuantity: maxQty,
      ),
    );

    // 3. Update Timing
    final minAcc = int.tryParse(_minAcceptHoursController.text) ?? 1;
    final maxAcc = int.tryParse(_maxAcceptHoursController.text) ?? 72;
    final minComp = int.tryParse(_minCompleteHoursController.text) ?? 1;
    final maxComp = int.tryParse(_maxCompleteHoursController.text) ?? 168;
    final retentionHours =
        int.tryParse(_minRetentionHoursController.text) ?? 24;

    bloc.add(
      UpdateTimingRulesEvent(
        minAcceptHours: minAcc,
        maxAcceptHours: maxAcc,
        minCompleteHours: minComp,
        maxCompleteHours: maxComp,
        minDurationSeconds: retentionHours * 3600,
      ),
    );

    // 4. Save / Publish
    if (publish && widget.serviceId != null && widget.serviceId!.isNotEmpty) {
      bloc.add(PublishServiceVersionEvent(widget.serviceId!));
    } else {
      bloc.add(SaveServiceDraftEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServiceBuilderBloc, ServiceBuilderState>(
      listener: (context, state) {
        if (state is ServiceEditingState) {
          if (!_bootstrapped) {
            _populateFromService(state.serviceDraft);
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        ServiceModel? service;
        bool isSaving = false;

        if (state is ServiceEditingState) {
          service = state.serviceDraft;
          isSaving = state.isSaving || state.isPublishing;
        }

        return Scaffold(
          backgroundColor: backgroundLight,
          appBar: AppBar(
            backgroundColor: surfaceWhite,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: primaryBlue),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text
                      : 'Configure Service',
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _codeController.text.isNotEmpty
                      ? _codeController.text
                      : 'NEW SERVICE',
                  style: const TextStyle(
                    color: accentBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              if (service != null)
                IconButton(
                  tooltip: 'Preview Runtime View',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: lightBlueBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Icon(Icons.remove_red_eye_rounded,
                        color: accentBlue, size: 18),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          BuyerWorkerPreviewModal(service: service!),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: isSaving
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: accentBlue),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _saveAndPublish(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: accentBlue.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(49),
              child: Container(
                decoration: const BoxDecoration(
                  color: surfaceWhite,
                  border:
                      Border(bottom: BorderSide(color: borderSubtle, width: 1)),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: accentBlue,
                  indicatorWeight: 3,
                  labelColor: accentBlue,
                  unselectedLabelColor: textSecondary,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: const [
                    Tab(
                        icon: Icon(Icons.info_outline_rounded, size: 18),
                        text: 'General Info'),
                    Tab(
                        icon: Icon(Icons.currency_rupee_rounded, size: 18),
                        text: 'Pricing & Margin'),
                    Tab(
                        icon: Icon(Icons.input_rounded, size: 18),
                        text: 'Buyer Inputs'),
                    Tab(
                        icon: Icon(Icons.verified_user_outlined, size: 18),
                        text: 'Worker Rules'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: General Information (Clean, presets hidden)
              _buildGeneralTab(),

              // Tab 2: Pricing & Margin Calculator
              _buildPricingTab(),

              // Tab 3: Buyer Input Configuration
              _buildBuyerInputsTab(),

              // Tab 4: Worker Rules & Verification
              _buildWorkerRulesTab(),
            ],
          ),
        );
      },
    );
  }

  // ==================== TAB 1: GENERAL INFO (CLEAN & PRESETS HIDDEN) ====================
  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Basic Info Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lightBlueBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.badge_outlined,
                          color: accentBlue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Service Identification',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set the internal system key, visible name and brief description for this service',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 18),

                // Unique Code
                _buildTextField(
                  controller: _codeController,
                  label: 'Service Code (Unique System Key)',
                  hint: 'e.g. YOUTUBE_LIKE, INSTA_FOLLOW, PLAYSTORE_RATING',
                  icon: Icons.key_rounded,
                ),
                const SizedBox(height: 16),

                // Fixed Service Title Display (Read-Only)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: lightBlueBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.label_important_rounded,
                          color: accentBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Service Title',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: const Text(
                                    'FIXED',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : (widget.draftName?.isNotEmpty == true
                                      ? widget.draftName!
                                      : 'Service Title'),
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                _buildTextField(
                  controller: _descController,
                  label: 'Service Description (Shown to Buyers & Workers)',
                  hint:
                      'Explain what workers need to do clearly in simple steps...',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Catalog Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Icon(Icons.public_rounded,
                      color: Color(0xFF16A34A), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instant Live Deployment',
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Changes saved here immediately synchronize with Buyer & Worker apps',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: PRICING & MARGIN ====================
  Widget _buildPricingTab() {
    final workerReward = _getCalculatedWorkerReward();
    final buyerPrice = double.tryParse(_buyerPriceController.text) ?? 0.0;
    final margin = double.tryParse(_marginController.text) ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Margin & Reward Breakdown Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              boxShadow: [
                BoxShadow(
                  color: accentBlue.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Live Profit & Reward Breakdown',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Automatic per-unit calculation for each completed order',
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFBFDBFE), height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildPricingStatColumn('Buyer Pays',
                          '₹${buyerPrice.toStringAsFixed(2)}', primaryBlue),
                    ),
                    const Text('-',
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 22,
                            fontWeight: FontWeight.w300)),
                    Expanded(
                      child: _buildPricingStatColumn(
                        'Admin Margin',
                        _isPercentageMargin
                            ? '$margin%'
                            : '₹${margin.toStringAsFixed(2)}',
                        const Color(0xFFD97706),
                      ),
                    ),
                    const Text('=',
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 22,
                            fontWeight: FontWeight.w300)),
                    Expanded(
                      child: _buildPricingStatColumn(
                          'Worker Reward',
                          '₹${workerReward.toStringAsFixed(2)}',
                          const Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pricing Configuration Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lightBlueBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: accentBlue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Pricing Parameters',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Buyer Unit Price
                _buildTextField(
                  controller: _buyerPriceController,
                  label: 'Buyer Price Per Unit (₹)',
                  hint: 'e.g. 5.00',
                  icon: Icons.currency_rupee_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Margin Type Selector
                Row(
                  children: [
                    const Text(
                      'Margin Type:',
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Fixed Amount (₹)'),
                      selected: !_isPercentageMargin,
                      selectedColor: accentBlue,
                      backgroundColor: backgroundLight,
                      labelStyle: TextStyle(
                        color:
                            !_isPercentageMargin ? Colors.white : textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(
                          color:
                              !_isPercentageMargin ? accentBlue : borderSubtle),
                      onSelected: (val) =>
                          setState(() => _isPercentageMargin = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Percentage (%)'),
                      selected: _isPercentageMargin,
                      selectedColor: accentBlue,
                      backgroundColor: backgroundLight,
                      labelStyle: TextStyle(
                        color:
                            _isPercentageMargin ? Colors.white : textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(
                          color:
                              _isPercentageMargin ? accentBlue : borderSubtle),
                      onSelected: (val) =>
                          setState(() => _isPercentageMargin = true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Admin Margin Value
                _buildTextField(
                  controller: _marginController,
                  label: _isPercentageMargin
                      ? 'Admin Margin Percentage (%)'
                      : 'Admin Margin Value (₹)',
                  hint: _isPercentageMargin ? 'e.g. 30' : 'e.g. 1.50',
                  icon: Icons.pie_chart_outline_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Min & Max Quantity Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _minQuantityController,
                        label: 'Min Order Qty',
                        hint: '10',
                        icon: Icons.format_list_numbered_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _maxQuantityController,
                        label: 'Max Order Qty',
                        hint: '10000',
                        icon: Icons.all_inclusive_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: BUYER INPUTS ====================
  Widget _buildBuyerInputsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target Link Requirement Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: lightBlueBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.link_rounded,
                              color: accentBlue, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Target URL / Link Input',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isLinkFieldEnabled,
                      activeColor: accentBlue,
                      onChanged: (val) =>
                          setState(() => _isLinkFieldEnabled = val),
                    ),
                  ],
                ),
                if (_isLinkFieldEnabled) ...[
                  const SizedBox(height: 12),
                  const Divider(color: borderSubtle, height: 1),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _linkFieldLabelController,
                    label: 'Field Label (Shown to Buyer)',
                    hint: 'e.g. YouTube Video Link, Instagram Post URL',
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _linkFieldPlaceholderController,
                    label: 'Placeholder Text',
                    hint: 'e.g. https://www.youtube.com/watch?v=...',
                    icon: Icons.short_text_rounded,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Custom Text Requirement Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: lightBlueBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.text_fields_rounded,
                              color: accentBlue, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Custom Text / Comment Input',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isTextFieldEnabled,
                      activeColor: accentBlue,
                      onChanged: (val) =>
                          setState(() => _isTextFieldEnabled = val),
                    ),
                  ],
                ),
                if (_isTextFieldEnabled) ...[
                  const SizedBox(height: 12),
                  const Divider(color: borderSubtle, height: 1),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _textFieldLabelController,
                    label: 'Field Label',
                    hint: 'e.g. Custom Comment Text, Keywords',
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _textFieldPlaceholderController,
                    label: 'Placeholder Text',
                    hint: 'e.g. Enter positive comment to post...',
                    icon: Icons.short_text_rounded,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Watch Time Requirement Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lightBlueBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer_outlined,
                          color: accentBlue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Mandatory Stay / Watch Time',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _watchtimeSeconds,
                  dropdownColor: surfaceWhite,
                  style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: backgroundLight,
                    prefixIcon: const Icon(Icons.schedule_rounded,
                        color: accentBlue, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: accentBlue, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 0, child: Text('No Timer (Instant Action)')),
                    DropdownMenuItem(
                        value: 30, child: Text('30 Seconds Mandatory Stay')),
                    DropdownMenuItem(
                        value: 60, child: Text('60 Seconds (1 Minute)')),
                    DropdownMenuItem(
                        value: 120, child: Text('120 Seconds (2 Minutes)')),
                    DropdownMenuItem(
                        value: 300, child: Text('300 Seconds (5 Minutes)')),
                  ],
                  onChanged: (val) =>
                      setState(() => _watchtimeSeconds = val ?? 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // AI Generator Switch Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _aiGeneratorEnabled
                    ? const Color(0xFFC084FC)
                    : borderSubtle,
                width: _aiGeneratorEnabled ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _aiGeneratorEnabled
                      ? const Color(0xFF9333EA).withOpacity(0.05)
                      : Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Color(0xFF9333EA), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Content Generator',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Auto-generate comments/tasks on backend',
                              style:
                                  TextStyle(color: textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _aiGeneratorEnabled,
                      activeColor: const Color(0xFF9333EA),
                      onChanged: (val) =>
                          setState(() => _aiGeneratorEnabled = val),
                    ),
                  ],
                ),
                if (_aiGeneratorEnabled) ...[
                  const SizedBox(height: 12),
                  const Divider(color: borderSubtle, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Language
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Language',
                                style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _aiLanguage,
                              dropdownColor: surfaceWhite,
                              style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: backgroundLight,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: borderSubtle),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: borderSubtle),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'English', child: Text('English')),
                                DropdownMenuItem(
                                    value: 'Hindi', child: Text('Hindi')),
                                DropdownMenuItem(
                                    value: 'Hinglish', child: Text('Hinglish')),
                                DropdownMenuItem(
                                    value: 'Spanish', child: Text('Spanish')),
                                DropdownMenuItem(
                                    value: 'Portuguese',
                                    child: Text('Portuguese')),
                                DropdownMenuItem(
                                    value: 'Arabic', child: Text('Arabic')),
                              ],
                              onChanged: (val) => setState(
                                  () => _aiLanguage = val ?? 'English'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tone',
                                style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _aiTone,
                              dropdownColor: surfaceWhite,
                              style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: backgroundLight,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: borderSubtle),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: borderSubtle),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'natural', child: Text('Natural')),
                                DropdownMenuItem(
                                    value: 'enthusiastic',
                                    child: Text('Excited')),
                                DropdownMenuItem(
                                    value: 'professional',
                                    child: Text('Professional')),
                                DropdownMenuItem(
                                    value: 'questioning',
                                    child: Text('Question')),
                              ],
                              onChanged: (val) =>
                                  setState(() => _aiTone = val ?? 'natural'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Ensure 100% Unique Comments',
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'No two workers receive the same comment text',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                    value: _aiUniqueness,
                    activeColor: const Color(0xFF9333EA),
                    onChanged: (val) => setState(() => _aiUniqueness = val),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 4: WORKER RULES ====================
  Widget _buildWorkerRulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proof Requirements Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lightBlueBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_user_rounded,
                          color: accentBlue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Proof Submission Requirements',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Screenshot Proof Required',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Worker must upload screenshot showing task completion',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                  value: _requiresScreenshot,
                  activeColor: accentBlue,
                  onChanged: (val) => setState(() => _requiresScreenshot = val),
                ),
                const Divider(color: borderSubtle, height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Text Proof / Username Required',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Worker must provide text answer (e.g. Account handle or username)',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                  value: _requiresTextProof,
                  activeColor: accentBlue,
                  onChanged: (val) => setState(() => _requiresTextProof = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Review Mode & Timing Windows
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lightBlueBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.rule_rounded,
                          color: accentBlue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Review Mode & Timings',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _reviewMode,
                  dropdownColor: surfaceWhite,
                  style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Task Review Mode',
                    labelStyle:
                        const TextStyle(color: textSecondary, fontSize: 12),
                    filled: true,
                    fillColor: backgroundLight,
                    prefixIcon: const Icon(Icons.fact_check_outlined,
                        color: accentBlue, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderSubtle),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'buyer', child: Text('Buyer Manual Review')),
                    DropdownMenuItem(
                        value: 'admin', child: Text('Admin Master Review')),
                    DropdownMenuItem(
                        value: 'auto', child: Text('Automatic Verification')),
                  ],
                  onChanged: (val) =>
                      setState(() => _reviewMode = val ?? 'buyer'),
                ),
                const SizedBox(height: 16),

                // Timing Windows
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _minAcceptHoursController,
                        label: 'Accept Window (Hours)',
                        hint: '24',
                        icon: Icons.timelapse_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _minCompleteHoursController,
                        label: 'Complete Deadline (Hours)',
                        hint: '48',
                        icon: Icons.hourglass_bottom_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _minRetentionHoursController,
                  label: 'App Install Min Retention (Hours)',
                  hint: '24 (Worker must keep app installed for this duration)',
                  icon: Icons.install_mobile_rounded,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Worker Guidelines & Media URLs Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lightBlueBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_outlined,
                          color: accentBlue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Worker Guidelines & Tutorials',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _adminInstructionsController,
                  label: 'Step-by-Step Instructions',
                  hint:
                      '1. Click target link\n2. Perform action\n3. Take screenshot and submit',
                  icon: Icons.list_alt_rounded,
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _videoUrlController,
                  label: 'Video Tutorial URL (Optional)',
                  hint: 'https://youtube.com/watch?v=...',
                  icon: Icons.video_collection_outlined,
                ),
                const SizedBox(height: 16),
                VoiceGuideStudioCard(
                  audioUrlController: _audioUrlController,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REUSABLE UI HELPERS ====================
  Widget _buildPricingStatColumn(String title, String value, Color valueColor) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(
          color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        prefixIcon: Icon(icon, color: accentBlue, size: 18),
        filled: true,
        fillColor: backgroundLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 1.5),
        ),
      ),
    );
  }
}
