import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../services/domain/models/service_model.dart';
import '../../../services/domain/models/pricing_config.dart';
import '../../../services/domain/models/template_element.dart';
import '../../../services/domain/models/element_category.dart';
import '../../../services/domain/models/element_type.dart';
import '../../../services/domain/models/visibility_context.dart';
import '../../../services/data/repositories/service_repository_impl.dart';

/// CreateCampaignPage - Unified Single Source of Truth for Campaign Creation
/// Is screen me Buyer App ka service catalog view aur dynamic form builder dono merged hain.
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
  String _selectedCategoryFilter = 'ALL';

  // Dynamic Form Controllers Map (har element.key ke liye controller store hota hai)
  final Map<String, TextEditingController> _formControllers = {};
  final _formKey = GlobalKey<FormState>();

  // Dynamic Pricing State
  PriceChipModel? _selectedChip;
  int _selectedQuantity = 100;
  bool _isSubmitting = false;

  // Service card gradient colors
  static const _cardGradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
  ];

  // Service icons mapping
  IconData _getServiceIcon(String code) {
    final c = code.toUpperCase();
    if (c.contains('YOUTUBE') || c.contains('YT')) return Icons.play_circle_fill_rounded;
    if (c.contains('INSTAGRAM') || c.contains('INSTA')) return Icons.camera_alt_rounded;
    if (c.contains('TELEGRAM') || c.contains('TG')) return Icons.send_rounded;
    if (c.contains('TWITTER') || c.contains('X_')) return Icons.flutter_dash_rounded;
    if (c.contains('WEBSITE') || c.contains('WEB')) return Icons.language_rounded;
    if (c.contains('FACEBOOK') || c.contains('FB')) return Icons.facebook_rounded;
    return Icons.rocket_launch_rounded;
  }

  @override
  void initState() {
    super.initState();
    _loadPublishedServices();
  }

  /// Backend repository se active services load karne ka Hinglish function
  Future<void> _loadPublishedServices() async {
    setState(() => _isLoading = true);
    final services = await _serviceRepository.getPublishedServices();
    setState(() {
      _publishedServices = services;
      _isLoading = false;

      // Agar initial serviceId passed pass hua tha, toh match karke auto-select karo
      if (widget.serviceId != null) {
        try {
          _selectService(services.firstWhere((s) => s.id == widget.serviceId));
        } catch (_) {}
      }
    });
  }

  /// Service select hone par dynamic form controllers aur default chips initialize hota hai
  void _selectService(ServiceModel service) {
    setState(() {
      _selectedService = service;
      _formControllers.clear();

      // Pricing package chip initialization
      final p = service.pricing;
      if (p.chips.isNotEmpty) {
        _selectedChip = p.chips.firstWhere((c) => c.isPopular, orElse: () => p.chips.first);
        _selectedQuantity = _selectedChip!.quantity;
      } else {
        _selectedChip = null;
        _selectedQuantity = p.minQuantity;
      }

      // Dynamic Form TextControllers initialize karo for buyer visible/editable elements
      for (var element in service.elements) {
        if (element.visibility == VisibilityContext.both ||
            element.visibility == VisibilityContext.buyerOnly) {
          _formControllers[element.key] = TextEditingController(
            text: element.properties['default']?.toString() ?? '',
          );
        }
      }
    });
  }

  /// Target Campaign Budget calculate karne ka utility method
  double _calculateTotalCost() {
    if (_selectedService == null) return 0.0;
    final p = _selectedService!.pricing;

    if (p.modelType == PricingModelType.tieredChips && _selectedChip != null) {
      return _selectedChip!.price;
    } else if (p.modelType == PricingModelType.countBased) {
      return _selectedQuantity * p.unitPrice;
    }
    return p.buyerPrice;
  }

  /// Dynamic Campaign Form Submit and Payload Metadata Generation
  void _submitCampaign() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Collect dynamic text field entries keyed by element.key/element.id
      final Map<String, dynamic> requirementsMap = {};
      for (var entry in _formControllers.entries) {
        requirementsMap[entry.key] = entry.value.text.trim();
      }

      // 2. Build NestJS BuyerOrderController payload
      final Map<String, dynamic> payloadData = {
        'serviceId': _selectedService!.id,
        'serviceCode': _selectedService!.code,
        'title': '${_selectedService!.name} Campaign ($_selectedQuantity tasks)',
        'description': requirementsMap['buyer_instructions'] ?? _selectedService!.description,
        'quantity': _selectedQuantity,
        'totalTasksRequired': _selectedQuantity,
        'requirements': requirementsMap,
        'reviewMode': 'buyer',
        'timeToAcceptHours': 24,
        'timeToCompleteHours': 48,
      };

      // 3. Backend API call via ServiceRepositoryImpl
      final success = await _serviceRepository.submitCampaignOrder(payloadData);
      if (!success) {
        throw Exception('Failed to launch campaign order');
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Success dialog showing launched campaign summary
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Campaign Launched!', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedService!.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('₹${_calculateTotalCost().toStringAsFixed(0)} paid', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              const SizedBox(height: 12),
              const Text('Your campaign is now live and workers will start completing tasks shortly.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Back to Services', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedService = null);
                },
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to launch campaign: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: const CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 16),
              const Text('Loading services...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    // VIEW A: If no service selected -> Render Published Services Catalog Grid
    if (_selectedService == null) {
      return _buildServicesCatalogView();
    }

    // VIEW B: If service selected -> Render Dynamic Form Builder & Price Chip Selector
    return _buildDynamicFormBuilderView();
  }

  /// VIEW A: Published Services Catalog Selector Grid
  Widget _buildServicesCatalogView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Services', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF334155)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Header
          const Text('Choose a Service', style: TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Select a service to launch your marketing campaign.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w400, height: 1.4)),
          const SizedBox(height: 16),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'YOUTUBE', 'INSTAGRAM', 'WEBSITE'].map((cat) {
                final isSelected = _selectedCategoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategoryFilter = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                        boxShadow: isSelected
                            ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Service Cards List
          ..._publishedServices.asMap().entries.map((entry) {
            final index = entry.key;
            final service = entry.value;
            final p = service.pricing;
            final gradientColors = _cardGradients[index % _cardGradients.length];

            String pricingText = '';
            String pricingSubText = '';
            if (p.modelType == PricingModelType.tieredChips && p.chips.isNotEmpty) {
              pricingText = '₹${p.chips.first.price.toStringAsFixed(0)}';
              pricingSubText = 'starting from';
            } else if (p.modelType == PricingModelType.countBased) {
              pricingText = '₹${p.unitPrice.toStringAsFixed(1)}';
              pricingSubText = 'per unit';
            } else {
              pricingText = '₹${p.buyerPrice.toStringAsFixed(0)}';
              pricingSubText = 'flat rate';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _selectService(service),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Service Icon with gradient
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_getServiceIcon(service.code), color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),

                        // Service Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                service.description,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.modelType.label,
                                  style: const TextStyle(color: Color(0xFF0369A1), fontSize: 9, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Price Badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(pricingSubText, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(pricingText, style: TextStyle(color: gradientColors[0], fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Select', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                  SizedBox(width: 3),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// VIEW B: Dynamic Form Builder & Price Chip Selector Screen
  Widget _buildDynamicFormBuilderView() {
    final service = _selectedService!;
    final pricing = service.pricing;
    final totalCost = _calculateTotalCost();

    final buyerElements = service.elements.where((e) {
      return e.visibility == VisibilityContext.both || e.visibility == VisibilityContext.buyerOnly;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(service.name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF334155), size: 20),
          onPressed: () => setState(() => _selectedService = null),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Budget', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('₹${totalCost.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submitCampaign,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSubmitting)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    else
                      const Icon(Icons.rocket_launch_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _isSubmitting ? 'Launching...' : 'Pay & Launch',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Service Summary Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _cardGradients[_publishedServices.indexOf(service) % _cardGradients.length],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getServiceIcon(service.code), color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(service.description, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. Dynamic Pricing Package Selector Card
            if (pricing.modelType == PricingModelType.tieredChips && pricing.chips.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_offer_rounded, color: Color(0xFF2563EB), size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text('Choose Package', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...pricing.chips.map((chip) {
                      final isSelected = _selectedChip?.id == chip.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedChip = chip;
                            _selectedQuantity = chip.quantity;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                                  border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: 2),
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(chip.label, style: TextStyle(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
                                        if (chip.isPopular) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text('₹${chip.price.toStringAsFixed(0)}', style: TextStyle(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155), fontSize: 15, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (pricing.modelType == PricingModelType.countBased) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Color(0xFF16A34A), size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Target Quantity', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('₹${pricing.unitPrice.toStringAsFixed(1)}/unit', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildQuantityButton(Icons.remove_rounded, _selectedQuantity > pricing.minQuantity
                            ? () => setState(() => _selectedQuantity -= 10)
                            : null),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              '$_selectedQuantity',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ),
                        ),
                        _buildQuantityButton(Icons.add_rounded, () => setState(() => _selectedQuantity += 10)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Min: ${pricing.minQuantity}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                        Text('Max: ${pricing.maxQuantity}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. Dynamic Template Form Elements Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: Color(0xFFF59E0B), size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('Campaign Details', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Fill in the required information for your campaign.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, height: 1.3)),
                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  ...buyerElements.map((element) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: _renderElementInputWidget(element),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback? onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: onPressed != null ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: onPressed != null ? Colors.white : const Color(0xFF94A3B8), size: 20),
        ),
      ),
    );
  }

  /// Helper to extract YouTube Video ID from any YouTube URL format
  String? _extractYouTubeId(String url) {
    if (url.isEmpty) return null;
    final regExp = RegExp(
      r'^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url.trim());
    return match?.group(1);
  }

  /// Dynamic Template Element Renderer Widget with Full Interactive Previews
  Widget _renderElementInputWidget(TemplateElement element) {
    final controller = _formControllers[element.key];

    switch (element.type) {
      case ElementType.heading:
        return Text(
          element.label,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
        );

      case ElementType.paragraph:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(element.label, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                element.properties['placeholder']?.toString() ?? 'Follow these detailed steps to complete the task.',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
              ),
            ],
          ),
        );

      case ElementType.youtube:
        final ytId = controller != null ? _extractYouTubeId(controller.text) : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFEF4444), size: 14),
                ),
                const SizedBox(width: 8),
                Text(element.label, style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600)),
                if (element.isRequired) const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: controller,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
              onChanged: (_) => setState(() {}), // Trigger live YouTube preview update
              validator: (val) {
                if (element.isRequired && (val == null || val.trim().isEmpty)) {
                  return 'YouTube URL is required';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=... or https://youtu.be/...',
                hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFFEF4444), size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
              ),
            ),
            const SizedBox(height: 8),
            // Live YouTube Video Preview Card
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                image: ytId != null
                    ? DecorationImage(
                        image: NetworkImage('https://img.youtube.com/vi/$ytId/hqdefault.jpg'),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (ytId == null)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.video_library_rounded, color: Colors.white38, size: 36),
                        SizedBox(height: 6),
                        Text('Paste YouTube URL above for Live Video Preview', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    )
                  else ...[
                    Container(color: Colors.black.withOpacity(0.35)),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                            SizedBox(width: 4),
                            Text('YouTube Live Preview', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

      case ElementType.audio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.mic_rounded, color: Color(0xFF0284C7), size: 14),
                ),
                const SizedBox(width: 8),
                Text(element.label, style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0369A1)]),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Voice Guidance for Workers', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('Record or attach an audio message explaining task steps', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.fiber_manual_record_rounded, color: Colors.redAccent, size: 14),
                        label: const Text('Record Voice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          // Voice record simulator
                          controller?.text = 'voice_instruction_recorded_${DateTime.now().millisecondsSinceEpoch}.aac';
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Voice instruction recorded successfully!'), backgroundColor: Color(0xFF0284C7)),
                          );
                        },
                      ),
                    ],
                  ),
                  if (controller != null && controller.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Color(0xFF0369A1), size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('00:24 / 00:45 Audio Waveform Recorded', style: TextStyle(color: Color(0xFF0369A1), fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                            onPressed: () {
                              controller.clear();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

      case ElementType.actionButton:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.ads_click_rounded, color: Color(0xFF16A34A), size: 14),
                ),
                const SizedBox(width: 8),
                Text(element.label, style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600)),
                if (element.isRequired) const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: controller,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
              validator: (val) {
                if (element.isRequired && (val == null || val.trim().isEmpty)) {
                  return 'Target Action Link is required';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: element.properties['placeholder'] as String? ?? 'https://youtube.com/..., https://t.me/...',
                hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF16A34A), size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
              ),
            ),
          ],
        );

      case ElementType.systemProof:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: const [
              Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Proof Submission: Worker will submit mandatory Screenshot & Text proof for verification.',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(element.label, style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w500)),
                if (element.isRequired) const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: controller,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
              validator: (val) {
                if (element.isRequired && (val == null || val.trim().isEmpty)) {
                  return 'This field is required';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: element.properties['placeholder'] as String? ?? 'Enter ${element.label.toLowerCase()}',
                hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
              ),
            ),
          ],
        );
    }
  }
}
