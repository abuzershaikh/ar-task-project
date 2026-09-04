import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../../../services/domain/models/service_model.dart';
import '../../../services/domain/models/pricing_config.dart';
import '../../../services/data/repositories/service_repository_impl.dart';
import '../../../services/presentation/widgets/category_accordion_card.dart';
import '../../../services/presentation/widgets/ai_comment_config_widget.dart';
import '../../../../core/utils/service_unit_helper.dart';

class CreateCampaignPage extends StatefulWidget {
  final String? serviceId;

  const CreateCampaignPage({super.key, this.serviceId});

  @override
  State<CreateCampaignPage> createState() => _CreateCampaignPageState();
}

class _CreateCampaignPageState extends State<CreateCampaignPage> {
  final ServiceRepositoryImpl _serviceRepository = ServiceRepositoryImpl();

  List<ServiceModel> _publishedServices = [];
  ServiceModel? _selectedService;
  bool _isLoading = true;
  double _walletBalance = 0.0;

  // Order Form State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _targetUrlController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '10');
  int _selectedQuantity = 10;
  String _selectedLanguage = 'English';
  String _selectedTone = 'natural';
  bool _isSubmitting = false;
  List<String> _sampleComments = [];
  bool _isGeneratingPreview = false;

  @override
  void initState() {
    super.initState();
    _loadPublishedServices();
    _loadWalletBalance();
  }

  @override
  void dispose() {
    _targetUrlController.dispose();
    _topicController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  bool _isCommentOrComboService(ServiceModel? s) {
    if (s == null) return false;
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    final desc = s.description.toUpperCase();
    final type = s.serviceType.toUpperCase();
    return s.aiGeneratorEnabled ||
        code.contains('COMMENT') ||
        code.contains('COMBO') ||
        code.contains('REVIEW') ||
        name.contains('COMMENT') ||
        name.contains('COMBO') ||
        name.contains('REVIEW') ||
        desc.contains('COMMENT') ||
        type.contains('COMMENT') ||
        type.contains('COMBO');
  }

  Future<void> _generateSampleComments() async {
    setState(() => _isGeneratingPreview = true);
    try {
      if (_serviceRepository.dioClient != null) {
        try {
          final res = await _serviceRepository.dioClient!.post(
            '/buyer/orders/ai-preview-comments',
            data: {
              'topic': _topicController.text.trim(),
              'language': _selectedLanguage,
              'tone': _selectedTone,
              'count': _selectedQuantity,
              'serviceCode': _selectedService?.code,
              'targetUrl': _targetUrlController.text.trim(),
            },
          );
          if (res.statusCode == 200 && res.data != null && res.data['sampleComments'] != null) {
            final List comments = res.data['sampleComments'];
            if (comments.isNotEmpty) {
              setState(() {
                _sampleComments = comments.map((c) => c.toString()).toList();
              });
              return;
            }
          }
        } catch (apiErr) {
          debugPrint('Preview API error, fallback: $apiErr');
        }
      }

      // Instant Organic Fallback Generation
      final topic = _topicController.text.trim();
      final targetCount = _selectedQuantity < 5 ? (_selectedQuantity > 0 ? _selectedQuantity : 1) : 5;
      final isReview = _selectedService?.code.toUpperCase().contains('PLAY') == true ||
          _selectedService?.code.toUpperCase().contains('REVIEW') == true ||
          _selectedService?.category.toUpperCase().contains('PLAY') == true ||
          _selectedService?.name.toUpperCase().contains('PLAY') == true ||
          _selectedService?.name.toUpperCase().contains('REVIEW') == true;

      final fallbacks = isReview
          ? [
              topic.isNotEmpty ? "Fantastic app, very smooth and intuitive with great features for $topic! 5 stars ⭐⭐⭐⭐⭐" : "Amazing application! Very smooth UI and easy to use. Highly recommended! ⭐⭐⭐⭐⭐",
              topic.isNotEmpty ? "Really impressed with the $topic functionality. Works flawlessly!" : "Best app in this category. Clean interface and super fast. 5 stars ⭐⭐⭐⭐⭐",
              topic.isNotEmpty ? "Top-notch performance and clean design for $topic. 5 stars!" : "Very helpful and reliable app. Great job by the developers!",
              topic.isNotEmpty ? "Everything about $topic works effortlessly. Loved it!" : "One of the best Android apps I have used. Flawless experience! ⭐⭐⭐⭐⭐",
              topic.isNotEmpty ? "Solid 5-star rating for excellent $topic support." : "Highly recommended to everyone! Deserves a full 5-star rating ⭐⭐⭐⭐⭐",
            ]
          : [
              topic.isNotEmpty ? "Great insights regarding $topic! Really enjoyed the video." : "Very informative and well presented! Keep it up.",
              topic.isNotEmpty ? "Super helpful content on $topic. Thanks for explaining so clearly!" : "Awesome content, learned a lot from this video.",
              topic.isNotEmpty ? "The points made about $topic are spot on. Subscribed!" : "Clear, concise, and super helpful. Highly recommended!",
              topic.isNotEmpty ? "Loved the practical tips shared for $topic." : "Quality explanation and great pacing. Thanks for sharing!",
              topic.isNotEmpty ? "Fantastic video on $topic, looking forward to the next one!" : "Really well explained and easy to follow.",
            ];
      setState(() {
        _sampleComments = fallbacks.take(targetCount).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate sample preview: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPreview = false);
      }
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      if (_serviceRepository.dioClient != null) {
        final res = await _serviceRepository.dioClient!.get('/buyer/wallet/balance');
        if (res.statusCode == 200 && res.data != null) {
          final bal = res.data['balance'];
          if (bal != null && bal['available'] != null) {
            if (mounted) {
              setState(() {
                _walletBalance = (bal['available'] as num).toDouble();
              });
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPublishedServices() async {
    setState(() => _isLoading = true);
    final services = await _serviceRepository.getPublishedServices();
    setState(() {
      _publishedServices = services;
      _isLoading = false;

      if (widget.serviceId != null) {
        try {
          _selectService(services.firstWhere((s) => s.id == widget.serviceId));
        } catch (_) {}
      }
    });
  }

  void _selectService(ServiceModel service) {
    setState(() {
      _selectedService = service;
      _selectedQuantity = 10;
      _quantityController.text = '10';
      _targetUrlController.clear();
      _topicController.clear();
      _sampleComments = [];
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.trim().isNotEmpty) {
      setState(() {
        _targetUrlController.text = data.text!.trim();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Link pasted from clipboard'),
            duration: Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty'),
            duration: Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  double _calculateTotalCost() {
    if (_selectedService == null) return 0.0;
    return _selectedQuantity * _selectedService!.pricing.buyerPrice;
  }

  void _submitCampaign() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final totalCost = _calculateTotalCost();
    if (_walletBalance < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ Insufficient wallet balance (₹${_walletBalance.toStringAsFixed(2)}). Required: ₹${totalCost.toStringAsFixed(2)}. Please top up!'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isCommentService = _isCommentOrComboService(_selectedService);

    if (isCommentService && _sampleComments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ Please generate sample comments first before placing the order!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final orderPayload = {
        'serviceCode': _selectedService!.code,
        'quantity': _selectedQuantity,
        'title': '${_selectedService!.name} Campaign ($_selectedQuantity tasks)',
        'description': isCommentService ? 'Custom content campaign' : 'Direct promotional campaign',
        'requirements': {
          'targetUrl': _targetUrlController.text.trim(),
          'topic': _topicController.text.trim(),
          'language': _selectedLanguage,
          'tone': _selectedTone,
          'aiGeneratorEnabled': isCommentService,
          'sampleComments': _sampleComments,
        },
        'timeToAcceptHours': _selectedService!.minAcceptHours,
        'timeToCompleteHours': _selectedService!.maxCompleteHours > 48
            ? 48
            : _selectedService!.maxCompleteHours,
      };

      final response =
          await _serviceRepository.dioClient!.post('/buyer/orders', data: orderPayload);

      setState(() => _isSubmitting = false);
      _loadWalletBalance();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Text('Order Live!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Successfully created ${_selectedService!.name} campaign for ${ServiceUnitHelper.getUnitName(_selectedService!.name, count: _selectedQuantity, includeCount: true)}.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text('₹${totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _selectedService = null;
                });
              },
              child: const Text('Create Another'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Order failed: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    if (_selectedService != null) {
      return _buildOrderFormView();
    }

    return _buildCategoryAccordionCatalogView();
  }

  // ==================== VIEW 1: CATEGORY ACCORDION CATALOG ====================
  Widget _buildCategoryAccordionCatalogView() {
    // Group services by category
    final Map<String, List<ServiceModel>> grouped = {};
    for (var s in _publishedServices) {
      String cat = s.category;
      if (s.category.isNotEmpty && s.category != 'General') {
        cat = s.category;
      } else if (s.code.toUpperCase().contains('YOUTUBE') || s.code.toUpperCase().contains('YT')) {
        cat = 'YouTube';
      } else if (s.code.toUpperCase().contains('PLAY') || s.code.toUpperCase().contains('REVIEW') || s.code.toUpperCase().contains('RATING')) {
        cat = 'Google Play Store';
      } else if (s.code.toUpperCase().contains('TELEGRAM') || s.code.toUpperCase().contains('TG')) {
        cat = 'Telegram';
      } else if (s.code.toUpperCase().contains('INSTA')) {
        cat = 'Instagram';
      } else if (s.code.toUpperCase().contains('APP')) {
        cat = 'App Install & Review';
      }
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    // Category visual themes
    final Map<String, Map<String, dynamic>> categoryMeta = {
      'Google Play Store': {
        'icon': Icons.star_rate_rounded,
        'color': const Color(0xFF00875A),
      },
      'Play Store': {
        'icon': Icons.star_rate_rounded,
        'color': const Color(0xFF00875A),
      },
      'YouTube': {
        'icon': Icons.play_circle_fill_rounded,
        'color': const Color(0xFFEF4444),
      },
      'Telegram': {
        'icon': Icons.send_rounded,
        'color': const Color(0xFF0284C7),
      },
      'Instagram': {
        'icon': Icons.camera_alt_rounded,
        'color': const Color(0xFFEC4899),
      },
      'App Install & Review': {
        'icon': Icons.android_rounded,
        'color': const Color(0xFF10B981),
      },
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign Catalog',
              style: TextStyle(
                  color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Select a category to browse verified promotional services',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Text(
                  '₹${_walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Categories Accordion List (All collapsed by default)
          ...grouped.entries.map((entry) {
            final cat = entry.key;
            final services = entry.value;
            final meta = categoryMeta[cat] ?? {
              'icon': Icons.stars_rounded,
              'color': const Color(0xFF6366F1),
            };

            return CategoryAccordionCard(
              categoryName: cat,
              icon: meta['icon'] as IconData,
              themeColor: meta['color'] as Color,
              services: services,
              initialExpanded: false, // All categories collapsed by default
              onSelectService: (service) => _selectService(service),
            );
          }),
        ],
      ),
    );
  }

  // ==================== VIEW 2: ORDER PLACEMENT VIEW ====================
  Widget _buildOrderFormView() {
    final s = _selectedService!;
    final isAi = _isCommentOrComboService(s);
    final totalCost = _calculateTotalCost();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => setState(() => _selectedService = null),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.name,
              style: const TextStyle(
                  color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              ServiceUnitHelper.getRateLabel(s.name, s.pricing.buyerPrice),
              style: const TextStyle(
                  color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target URL Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.linkFieldLabel ?? 'Target Link / Video URL',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _targetUrlController,
                      keyboardType: TextInputType.url,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please provide target URL';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: s.linkFieldPlaceholder ?? 'https://www.youtube.com/watch?v=...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF2563EB)),
                        suffixIcon: InkWell(
                          onTap: _pasteFromClipboard,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.content_paste_rounded, size: 14, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text(
                                  'Paste',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // AI Generator Options Widget (if AI is enabled)
              if (isAi) ...[
                AiCommentConfigWidget(
                  topicController: _topicController,
                  selectedLanguage: _selectedLanguage,
                  selectedTone: _selectedTone,
                  selectedQuantity: _selectedQuantity,
                  sampleComments: _sampleComments,
                  isGeneratingPreview: _isGeneratingPreview,
                  isAppReview: s.code.toUpperCase().contains('PLAY') ||
                      s.code.toUpperCase().contains('REVIEW') ||
                      s.category.toUpperCase().contains('PLAY') ||
                      s.name.toUpperCase().contains('PLAY') ||
                      s.name.toUpperCase().contains('REVIEW'),
                  onGeneratePreview: _generateSampleComments,
                  onLanguageChanged: (lang) => setState(() {
                    _selectedLanguage = lang;
                    _sampleComments = [];
                  }),
                  onToneChanged: (tone) => setState(() {
                    _selectedTone = tone;
                    _sampleComments = [];
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // Quantity Selector Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ServiceUnitHelper.getQuantityHeader(s.name),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ServiceUnitHelper.getUnitExplanation(s.name),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),

                    // Stepper row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF2563EB)),
                          onPressed: () {
                            if (_selectedQuantity > 1) {
                              setState(() {
                                _selectedQuantity--;
                                _quantityController.text = '$_selectedQuantity';
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            onChanged: (val) {
                              final num = int.tryParse(val) ?? 1;
                              setState(() => _selectedQuantity = num > 0 ? num : 1);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
                          onPressed: () {
                            setState(() {
                              _selectedQuantity++;
                              _quantityController.text = '$_selectedQuantity';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick presets
                    Wrap(
                      spacing: 8,
                      children: [10, 25, 50, 100, 500, 1000].map((qty) {
                        final isSelected = _selectedQuantity == qty;
                        return ChoiceChip(
                          label: Text(ServiceUnitHelper.getUnitName(s.name, count: qty, includeCount: true)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedQuantity = qty;
                              _quantityController.text = '$qty';
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Total & Checkout Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantity:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(ServiceUnitHelper.getUnitName(s.name, count: _selectedQuantity, includeCount: true),
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rate per ${ServiceUnitHelper.getUnitName(s.name, count: 1)}:',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('₹${s.pricing.buyerPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Budget:',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('₹${totalCost.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitCampaign,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.rocket_launch_rounded),
                  label: Text(
                    _isSubmitting ? 'Launching Campaign...' : 'Place Campaign Order',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
