import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/service_builder_bloc.dart';
import '../bloc/service_builder_event.dart';
import '../bloc/service_builder_state.dart';
import '../widgets/buyer_worker_preview_modal.dart';
import '../../domain/models/service_model.dart';
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

  // State flags
  bool _isLinkFieldEnabled = true;
  bool _isTextFieldEnabled = false;
  bool _requiresScreenshot = true;
  bool _requiresTextProof = false;
  int _watchtimeSeconds = 0;
  String _reviewMode = 'buyer';
  bool _isPercentageMargin = false;
  bool _bootstrapped = false;
  String _selectedPresetCategory = 'All';

  // AI Generator Settings (Section 18)
  bool _aiGeneratorEnabled = false;
  String _aiLanguage = 'English';
  String _aiTone = 'natural';
  bool _aiUniqueness = true;

  // Category Presets
  final List<Map<String, dynamic>> _presetTemplates = [
    // YouTube Fixed 4 Services Presets
    {
      'category': 'YouTube',
      'icon': Icons.chat_bubble_outline_rounded,
      'color': Colors.redAccent,
      'code': 'YOUTUBE_COMMENT',
      'name': 'YouTube Video Comment',
      'desc': 'Post unique, high-retention comments on the target video with AI generator support',
      'buyerPrice': 3.0,
      'margin': 1.0,
      'workerReward': 2.0,
      'linkLabel': 'YouTube Video URL',
      'linkPlaceholder': 'https://www.youtube.com/watch?v=...',
      'needText': true,
      'textLabel': 'Comment Topic / Keywords',
      'textPlaceholder': 'e.g. informative tutorial, honest review, excellent breakdown',
      'watchtime': 0,
      'aiEnabled': true,
    },
    {
      'category': 'YouTube',
      'icon': Icons.thumb_up_alt_outlined,
      'color': Colors.redAccent,
      'code': 'YOUTUBE_LIKE',
      'name': 'YouTube Video Like',
      'desc': 'Real user likes on YouTube video with high retention',
      'buyerPrice': 2.0,
      'margin': 0.5,
      'workerReward': 1.5,
      'linkLabel': 'YouTube Video URL',
      'linkPlaceholder': 'https://www.youtube.com/watch?v=...',
      'needText': false,
      'watchtime': 0,
      'aiEnabled': false,
    },
    {
      'category': 'YouTube',
      'icon': Icons.subscriptions_outlined,
      'color': Colors.redAccent,
      'code': 'YOUTUBE_SUBSCRIBE',
      'name': 'YouTube Channel Subscribe',
      'desc': 'Permanent subscribers from verified active accounts',
      'buyerPrice': 5.0,
      'margin': 1.5,
      'workerReward': 3.5,
      'linkLabel': 'YouTube Channel Link',
      'linkPlaceholder': 'https://www.youtube.com/@channel',
      'needText': false,
      'watchtime': 0,
      'aiEnabled': false,
    },
    {
      'category': 'YouTube',
      'icon': Icons.auto_awesome,
      'color': Colors.amberAccent,
      'code': 'YOUTUBE_COMBO',
      'name': 'YouTube Combo (Like + Sub + Comment)',
      'desc': 'All-in-one engagement: Like video + Subscribe to Channel + Post unique AI comment',
      'buyerPrice': 8.0,
      'margin': 2.5,
      'workerReward': 5.5,
      'linkLabel': 'YouTube Video / Channel URL',
      'linkPlaceholder': 'https://www.youtube.com/watch?v=...',
      'needText': true,
      'textLabel': 'Comment Topic / Keywords',
      'textPlaceholder': 'e.g. loved the video, subscribed!',
      'watchtime': 60,
      'aiEnabled': true,
    },
    {
      'category': 'Telegram',
      'icon': Icons.send_rounded,
      'color': Colors.lightBlueAccent,
      'code': 'TELEGRAM_JOIN',
      'name': 'Telegram Channel Join',
      'desc': 'Join public/private Telegram channel and stay active for 7 days',
      'buyerPrice': 3.0,
      'margin': 1.0,
      'workerReward': 2.0,
      'linkLabel': 'Telegram Invite Link',
      'linkPlaceholder': 'https://t.me/yourchannel',
      'needText': true,
      'textLabel': 'Telegram Username (Worker Proof)',
      'textPlaceholder': '@username',
      'watchtime': 0,
      'aiEnabled': false,
    },
    {
      'category': 'Instagram',
      'icon': Icons.camera_alt,
      'color': Colors.pinkAccent,
      'code': 'INSTA_FOLLOW',
      'name': 'Instagram Profile Follow',
      'desc': 'Organic profile follow from real active accounts',
      'buyerPrice': 4.0,
      'margin': 1.0,
      'workerReward': 3.0,
      'linkLabel': 'Instagram Profile URL',
      'linkPlaceholder': 'https://instagram.com/profile',
      'needText': true,
      'textLabel': 'Worker Instagram Handle',
      'textPlaceholder': '@handle',
      'watchtime': 0,
      'aiEnabled': false,
    },
    {
      'category': 'App Install',
      'icon': Icons.android,
      'color': Colors.greenAccent,
      'code': 'APP_INSTALL',
      'name': 'Android App Install & Open',
      'desc': 'Download app from Google Play Store and open for 60 seconds',
      'buyerPrice': 10.0,
      'margin': 3.0,
      'workerReward': 7.0,
      'linkLabel': 'Play Store Link',
      'linkPlaceholder': 'https://play.google.com/store/apps/details?id=...',
      'needText': false,
      'watchtime': 60,
      'aiEnabled': false,
    },
    {
      'category': 'Website',
      'icon': Icons.language,
      'color': Colors.amberAccent,
      'code': 'WEB_VISIT',
      'name': 'Website Visit & Stay 30s',
      'desc': 'Visit landing page and browse at least 2 pages for 30s',
      'buyerPrice': 2.5,
      'margin': 0.7,
      'workerReward': 1.8,
      'linkLabel': 'Website URL',
      'linkPlaceholder': 'https://example.com',
      'needText': false,
      'watchtime': 30,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _codeController = TextEditingController(text: widget.draftCode ?? '');
    _nameController = TextEditingController(text: widget.draftName ?? '');
    _descController = TextEditingController(text: widget.draftDescription ?? '');
    _buyerPriceController = TextEditingController(
        text: widget.draftBuyerPrice != null ? widget.draftBuyerPrice.toString() : '5.0');
    _marginController = TextEditingController(
        text: widget.draftMargin != null ? widget.draftMargin.toString() : '1.5');
    _minQuantityController = TextEditingController(text: '10');
    _maxQuantityController = TextEditingController(text: '10000');
    _minAcceptHoursController = TextEditingController(text: '1');
    _maxAcceptHoursController = TextEditingController(text: '72');
    _minCompleteHoursController = TextEditingController(text: '1');
    _maxCompleteHoursController = TextEditingController(text: '168');
    _linkFieldLabelController = TextEditingController(text: 'Target Link / URL');
    _linkFieldPlaceholderController = TextEditingController(text: 'https://...');
    _textFieldLabelController = TextEditingController(text: 'Custom Instructions / Text');
    _textFieldPlaceholderController =
        TextEditingController(text: 'Enter instructions, comments or proof details...');
    _adminInstructionsController = TextEditingController();
    _videoUrlController = TextEditingController();
    _audioUrlController = TextEditingController();

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
    super.dispose();
  }

  void _populateFromService(ServiceModel service) {
    if (_codeController.text.isEmpty) _codeController.text = service.code;
    if (_nameController.text.isEmpty) _nameController.text = service.name;
    if (_descController.text.isEmpty) _descController.text = service.description;
    _buyerPriceController.text = service.pricing.buyerPrice.toString();
    _marginController.text = service.pricing.adminMarginPercent.toString();
    _minQuantityController.text = service.pricing.minQuantity.toString();
    _maxQuantityController.text = service.pricing.maxQuantity.toString();
    _minAcceptHoursController.text = service.minAcceptHours.toString();
    _maxAcceptHoursController.text = service.maxAcceptHours.toString();
    _minCompleteHoursController.text = service.minCompleteHours.toString();
    _maxCompleteHoursController.text = service.maxCompleteHours.toString();
    _linkFieldLabelController.text = service.linkFieldLabel ?? 'Target Link / URL';
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
      _aiLanguage = service.aiGeneratorConfig!['language']?.toString() ?? 'English';
      _aiTone = service.aiGeneratorConfig!['tone']?.toString() ?? 'natural';
      _aiUniqueness = service.aiGeneratorConfig!['uniqueness'] == true ||
          service.aiGeneratorConfig!['unique'] == true ||
          service.aiGeneratorConfig!['uniqueness'] == null;
    }
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _codeController.text = preset['code'] ?? _codeController.text;
      _nameController.text = preset['name'] ?? _nameController.text;
      _descController.text = preset['desc'] ?? _descController.text;
      _buyerPriceController.text = (preset['buyerPrice'] ?? 5.0).toString();
      _marginController.text = (preset['margin'] ?? 1.5).toString();
      if (preset['linkLabel'] != null) {
        _linkFieldLabelController.text = preset['linkLabel'];
        _linkFieldPlaceholderController.text = preset['linkPlaceholder'] ?? 'https://...';
        _isLinkFieldEnabled = true;
      }
      if (preset['needText'] == true) {
        _isTextFieldEnabled = true;
        if (preset['textLabel'] != null) _textFieldLabelController.text = preset['textLabel'];
        if (preset['textPlaceholder'] != null) {
          _textFieldPlaceholderController.text = preset['textPlaceholder'];
        }
      }
      _watchtimeSeconds = preset['watchtime'] ?? 0;
      if (preset['aiEnabled'] != null) {
        _aiGeneratorEnabled = preset['aiEnabled'] == true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied preset: ${preset['name']}'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _getCalculatedWorkerReward() {
    final buyerPrice = double.tryParse(_buyerPriceController.text) ?? 0.0;
    final margin = double.tryParse(_marginController.text) ?? 0.0;
    if (_isPercentageMargin) {
      final reward = buyerPrice * (1.0 - (margin / 100.0));
      return reward > 0 ? reward : 0.0;
    } else {
      final reward = buyerPrice - margin;
      return reward > 0 ? reward : 0.0;
    }
  }

  void _saveAndPublish(BuildContext context, bool publish) {
    final bloc = context.read<ServiceBuilderBloc>();

    // 1. Update Info
    bloc.add(
      UpdateServiceInfoEvent(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _codeController.text.startsWith('YOUTUBE') ? 'YouTube' : 'General',
        serviceType: _codeController.text.contains('COMMENT')
            ? 'comment'
            : (_codeController.text.contains('LIKE')
                ? 'like'
                : (_codeController.text.contains('SUBSCRIBE')
                    ? 'subscribe'
                    : (_codeController.text.contains('COMBO') ? 'combo' : 'custom'))),
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
        linkFieldLabel: _isLinkFieldEnabled ? _linkFieldLabelController.text.trim() : null,
        linkFieldPlaceholder:
            _isLinkFieldEnabled ? _linkFieldPlaceholderController.text.trim() : null,
        textFieldLabel: _isTextFieldEnabled ? _textFieldLabelController.text.trim() : null,
        textFieldPlaceholder:
            _isTextFieldEnabled ? _textFieldPlaceholderController.text.trim() : null,
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

    bloc.add(
      UpdateTimingRulesEvent(
        minAcceptHours: minAcc,
        maxAcceptHours: maxAcc,
        minCompleteHours: minComp,
        maxCompleteHours: maxComp,
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
                backgroundColor: AppColors.success,
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
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
          backgroundColor: const Color(0xFF0B1120),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text
                      : 'Fixed Service Setup',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _codeController.text.isNotEmpty ? _codeController.text : 'NEW SERVICE',
                  style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              if (service != null)
                IconButton(
                  tooltip: 'Preview Buyer & Worker View',
                  icon: const Icon(Icons.remove_red_eye_rounded,
                      color: Colors.cyanAccent, size: 22),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BuyerWorkerPreviewModal(service: service!),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: isSaving
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.cyanAccent),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _saveAndPublish(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.cyanAccent,
              indicatorWeight: 3,
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline, size: 18), text: 'General & Presets'),
                Tab(icon: Icon(Icons.currency_rupee, size: 18), text: 'Pricing & Margin'),
                Tab(icon: Icon(Icons.input_rounded, size: 18), text: 'Buyer Inputs'),
                Tab(icon: Icon(Icons.verified_user_outlined, size: 18), text: 'Worker Rules'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: General & Category Presets
              _buildGeneralTab(),

              // Tab 2: Fixed Pricing & Margin Calculator
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

  // ==================== TAB 1: GENERAL & PRESETS ====================
  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Category Presets
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'One-Tap Preset Templates',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap any preset below to instantly populate standard settings:',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetTemplates.map((p) {
                    return ActionChip(
                      avatar: Icon(p['icon'] as IconData,
                          size: 16, color: p['color'] as Color),
                      label: Text(
                        p['name'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Colors.white24),
                      onPressed: () => _applyPreset(p),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Service Basic Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Identification',
                  style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                // Unique Code
                _buildTextField(
                  controller: _codeController,
                  label: 'Service Code (System Key)',
                  hint: 'e.g. YOUTUBE_LIKE, INSTA_FOLLOW',
                  icon: Icons.key_rounded,
                ),
                const SizedBox(height: 12),

                // Service Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Service Display Name',
                  hint: 'e.g. YouTube Video Like',
                  icon: Icons.label_important_rounded,
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Description
                _buildTextField(
                  controller: _descController,
                  label: 'Service Description (Shown to Buyers & Workers)',
                  hint: 'Explain what workers need to do clearly...',
                  icon: Icons.description_rounded,
                  maxLines: 3,
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
          // Live Margin & Reward Calculation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(0.15),
                  const Color(0xFF1E293B)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: Colors.cyanAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Live Profit & Reward Breakdown',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPricingStatColumn('Buyer Pays', '₹${buyerPrice.toStringAsFixed(2)}', Colors.cyanAccent),
                    const Text('-', style: TextStyle(color: Colors.white38, fontSize: 20)),
                    _buildPricingStatColumn('Admin Margin', _isPercentageMargin ? '$margin%' : '₹${margin.toStringAsFixed(2)}', Colors.amberAccent),
                    const Text('=', style: TextStyle(color: Colors.white38, fontSize: 20)),
                    _buildPricingStatColumn('Worker Reward', '₹${workerReward.toStringAsFixed(2)}', Colors.greenAccent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pricing Configuration Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pricing Parameters',
                  style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                // Buyer Unit Price
                _buildTextField(
                  controller: _buyerPriceController,
                  label: 'Buyer Price Per Unit (₹)',
                  hint: 'e.g. 5.00',
                  icon: Icons.currency_rupee,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Margin Type Selector
                Row(
                  children: [
                    const Text('Margin Type: ',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Fixed Amount (₹)'),
                      selected: !_isPercentageMargin,
                      selectedColor: Colors.cyanAccent,
                      labelStyle: TextStyle(
                          color: !_isPercentageMargin ? Colors.black : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                      onSelected: (val) => setState(() => _isPercentageMargin = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Percentage (%)'),
                      selected: _isPercentageMargin,
                      selectedColor: Colors.cyanAccent,
                      labelStyle: TextStyle(
                          color: _isPercentageMargin ? Colors.black : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                      onSelected: (val) => setState(() => _isPercentageMargin = true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Admin Margin Value
                _buildTextField(
                  controller: _marginController,
                  label: _isPercentageMargin
                      ? 'Admin Margin Percentage (%)'
                      : 'Admin Margin Value (₹)',
                  hint: _isPercentageMargin ? 'e.g. 30' : 'e.g. 1.50',
                  icon: Icons.pie_chart_outline,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Min & Max Quantity
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _minQuantityController,
                        label: 'Min Order Qty',
                        hint: '10',
                        icon: Icons.format_list_numbered,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _maxQuantityController,
                        label: 'Max Order Qty',
                        hint: '10000',
                        icon: Icons.all_inclusive,
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
          // Target Link Requirement Switch Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.link_rounded, color: Colors.cyanAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Target URL / Link Input',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isLinkFieldEnabled,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => setState(() => _isLinkFieldEnabled = val),
                    ),
                  ],
                ),
                if (_isLinkFieldEnabled) ...[
                  const Divider(color: Colors.white12, height: 16),
                  _buildTextField(
                    controller: _linkFieldLabelController,
                    label: 'Field Label (Shown to Buyer)',
                    hint: 'e.g. YouTube Video Link, Instagram Post URL',
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _linkFieldPlaceholderController,
                    label: 'Placeholder Text',
                    hint: 'e.g. https://www.youtube.com/watch?v=...',
                    icon: Icons.short_text,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Custom Text Requirement Switch Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.text_fields_rounded,
                            color: Colors.cyanAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Custom Text / Comment Input',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isTextFieldEnabled,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => setState(() => _isTextFieldEnabled = val),
                    ),
                  ],
                ),
                if (_isTextFieldEnabled) ...[
                  const Divider(color: Colors.white12, height: 16),
                  _buildTextField(
                    controller: _textFieldLabelController,
                    label: 'Field Label',
                    hint: 'e.g. Custom Comment Text, Keywords',
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _textFieldPlaceholderController,
                    label: 'Placeholder Text',
                    hint: 'e.g. Enter positive comment to post...',
                    icon: Icons.short_text,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Watch Time Requirement Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.cyanAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Mandatory Stay / Watch Time',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _watchtimeSeconds,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('No Timer (Instant Action)')),
                    DropdownMenuItem(value: 30, child: Text('30 Seconds Mandatory Stay')),
                    DropdownMenuItem(value: 60, child: Text('60 Seconds (1 Minute)')),
                    DropdownMenuItem(value: 120, child: Text('120 Seconds (2 Minutes)')),
                    DropdownMenuItem(value: 300, child: Text('300 Seconds (5 Minutes)')),
                  ],
                  onChanged: (val) => setState(() => _watchtimeSeconds = val ?? 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // AI Generator Switch Card (Section 18)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _aiGeneratorEnabled ? Colors.purpleAccent : Colors.white12,
                width: _aiGeneratorEnabled ? 1.5 : 1.0,
              ),
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Content Generator',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Auto-generate comments/tasks on backend',
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _aiGeneratorEnabled,
                      activeColor: Colors.purpleAccent,
                      onChanged: (val) => setState(() => _aiGeneratorEnabled = val),
                    ),
                  ],
                ),
                if (_aiGeneratorEnabled) ...[
                  const Divider(color: Colors.white12, height: 20),
                  const Text(
                    'Default AI Settings for this Service:',
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Language
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Language', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _aiLanguage,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'English', child: Text('English')),
                                DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                                DropdownMenuItem(value: 'Hinglish', child: Text('Hinglish')),
                                DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                                DropdownMenuItem(value: 'Portuguese', child: Text('Portuguese')),
                                DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
                              ],
                              onChanged: (val) => setState(() => _aiLanguage = val ?? 'English'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Tone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tone', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _aiTone,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'natural', child: Text('🌿 Natural')),
                                DropdownMenuItem(value: 'enthusiastic', child: Text('🔥 Excited')),
                                DropdownMenuItem(value: 'professional', child: Text('💼 Professional')),
                                DropdownMenuItem(value: 'questioning', child: Text('❓ Question')),
                              ],
                              onChanged: (val) => setState(() => _aiTone = val ?? 'natural'),
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
                    title: const Text('Ensure 100% Unique Comments', style: TextStyle(color: Colors.white, fontSize: 12)),
                    subtitle: const Text('No two workers receive the same comment text', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    value: _aiUniqueness,
                    activeColor: Colors.purpleAccent,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proof Submission Requirements',
                  style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Screenshot Proof Required',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text(
                      'Worker must upload screenshot showing task completion',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: _requiresScreenshot,
                  activeColor: Colors.cyanAccent,
                  onChanged: (val) => setState(() => _requiresScreenshot = val),
                ),
                const Divider(color: Colors.white12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Text Proof / Username Required',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text(
                      'Worker must provide text answer (e.g. Account handle)',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: _requiresTextProof,
                  activeColor: Colors.cyanAccent,
                  onChanged: (val) => setState(() => _requiresTextProof = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Review Mode & Timing Windows
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review Mode & Timings',
                  style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _reviewMode,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Task Review Mode',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'buyer', child: Text('Buyer Manual Review')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin Master Review')),
                    DropdownMenuItem(value: 'auto', child: Text('Automatic Verification')),
                  ],
                  onChanged: (val) => setState(() => _reviewMode = val ?? 'buyer'),
                ),
                const SizedBox(height: 14),

                // Timing Windows
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _minAcceptHoursController,
                        label: 'Accept Window (Hours)',
                        hint: '24',
                        icon: Icons.timelapse,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _minCompleteHoursController,
                        label: 'Complete Deadline (Hours)',
                        hint: '48',
                        icon: Icons.hourglass_bottom,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Worker Guidelines & Media URLs Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Worker Guidelines & Tutorials',
                  style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _adminInstructionsController,
                  label: 'Step-by-Step Instructions',
                  hint: '1. Click target link\n2. Perform action\n3. Take screenshot and submit',
                  icon: Icons.list_alt_rounded,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _videoUrlController,
                  label: 'Video Tutorial URL (Optional)',
                  hint: 'https://youtube.com/watch?v=...',
                  icon: Icons.video_collection_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _audioUrlController,
                  label: 'Audio Guide URL (Optional)',
                  hint: 'https://example.com/guide.mp3',
                  icon: Icons.mic_none_outlined,
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
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
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
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }
}
