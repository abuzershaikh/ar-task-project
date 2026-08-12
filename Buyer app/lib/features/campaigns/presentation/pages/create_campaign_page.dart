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

      // Dynamic Form TextControllers initialize karo for buyer visible elements
      for (var element in service.elements) {
        if (element.visibility == VisibilityContext.both ||
            element.visibility == VisibilityContext.buyerOnly) {
          if (element.category == ElementCategory.input) {
            _formControllers[element.key] = TextEditingController();
          }
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

    // 1. Collect dynamic text field entries keyed by element.key
    final Map<String, dynamic> payloadData = {};
    for (var entry in _formControllers.entries) {
      payloadData[entry.key] = entry.value.text.trim();
    }

    // 2. Add pricing & chip metadata to payload
    final p = _selectedService!.pricing;
    payloadData['pricing_model'] = p.modelType.name;
    if (_selectedChip != null) {
      payloadData['package_chip_id'] = _selectedChip!.id;
      payloadData['package_label'] = _selectedChip!.label;
    }
    payloadData['target_quantity'] = _selectedQuantity;
    payloadData['total_campaign_cost'] = _calculateTotalCost();

    // 3. Backend API call via ServiceRepositoryImpl
    await _serviceRepository.submitCampaignOrder(payloadData);

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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 10),
            const Text('Campaign Published!', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${_selectedService!.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 4),
            Text('Paid Amount: ₹${_calculateTotalCost().toStringAsFixed(0)}', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            const Text('Generated Form Payload Metadata:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payloadData.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Back to Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _selectedService = null);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Create New Campaign'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Select a Service Template:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Choose from active published templates configured by Admin.', style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 16),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'YOUTUBE', 'INSTAGRAM', 'WEBSITE'].map((cat) {
                final isSelected = _selectedCategoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    selected: isSelected,
                    selectedColor: Colors.cyanAccent,
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (val) => setState(() => _selectedCategoryFilter = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Service Cards List
          ..._publishedServices.map((service) {
            final p = service.pricing;

            String pricingBadgeText = '';
            if (p.modelType == PricingModelType.tieredChips && p.chips.isNotEmpty) {
              pricingBadgeText = 'PACKAGES FROM ₹${p.chips.first.price.toStringAsFixed(0)}';
            } else if (p.modelType == PricingModelType.countBased) {
              pricingBadgeText = '₹${p.unitPrice.toStringAsFixed(1)} / UNIT';
            } else {
              pricingBadgeText = 'FLAT RATE ₹${p.buyerPrice.toStringAsFixed(0)}';
            }

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _selectService(service),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(service.code, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(pricingBadgeText, style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(service.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(service.description, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      const Divider(color: Colors.white12, height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pricing: ${p.modelType.label}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text('Select Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            onPressed: () => _selectService(service),
                          ),
                        ],
                      ),
                    ],
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(service.name),
        backgroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => setState(() => _selectedService = null),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Budget', style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text('₹${totalCost.toStringAsFixed(0)}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(_isSubmitting ? 'Launching...' : 'Pay & Launch Campaign', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: _isSubmitting ? null : _submitCampaign,
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Dynamic Pricing Package Selector Card
            if (pricing.modelType == PricingModelType.tieredChips && pricing.chips.isNotEmpty) ...[
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Package Chip:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: pricing.chips.map((chip) {
                          final isSelected = _selectedChip?.id == chip.id;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedChip = chip;
                                _selectedQuantity = chip.quantity;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.cyanAccent : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.cyanAccent : Colors.white24,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (chip.isPopular)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amberAccent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('MOST POPULAR', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                  Text(
                                    chip.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${chip.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.black87 : Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (pricing.modelType == PricingModelType.countBased) ...[
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Target Quantity:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Rate: ₹${pricing.unitPrice}/unit', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.cyanAccent, size: 28),
                            onPressed: _selectedQuantity > pricing.minQuantity
                                ? () => setState(() => _selectedQuantity -= 10)
                                : null,
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_selectedQuantity Units',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 28),
                            onPressed: () => setState(() => _selectedQuantity += 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. Dynamic Template Form Elements Card
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Form Details & Requirements', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white12, height: 20),

                    ...buyerElements.map((element) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: _renderElementInputWidget(element),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dynamic Template Element Renderer Widget
  Widget _renderElementInputWidget(TemplateElement element) {
    switch (element.type) {
      case ElementType.heading:
        return Text(
          element.label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        );
      case ElementType.paragraph:
        return Text(
          element.label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        );
      case ElementType.textField:
        final controller = _formControllers[element.key];
        return TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          validator: (val) {
            if (element.isRequired && (val == null || val.trim().isEmpty)) {
              return 'Please enter ${element.label}';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: element.label,
            labelStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${element.type.label}: ${element.label}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        );
    }
  }
}
