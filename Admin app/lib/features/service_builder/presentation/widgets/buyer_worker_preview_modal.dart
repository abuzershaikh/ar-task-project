import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/service_model.dart';
import '../../domain/models/pricing_config.dart';
import '../../domain/models/visibility_context.dart';
import '../../domain/models/element_type.dart';

class BuyerWorkerPreviewModal extends StatefulWidget {
  final ServiceModel service;

  const BuyerWorkerPreviewModal({super.key, required this.service});

  @override
  State<BuyerWorkerPreviewModal> createState() => _BuyerWorkerPreviewModalState();
}

class _BuyerWorkerPreviewModalState extends State<BuyerWorkerPreviewModal> {
  bool _isBuyerMode = true; // true = Buyer Campaign Creator Preview, false = Worker Task Execution Preview
  PriceChipModel? _selectedChip;
  int _selectedQuantity = 100;

  @override
  void initState() {
    super.initState();
    final p = widget.service.pricing;
    if (p.chips.isNotEmpty) {
      _selectedChip = p.chips.firstWhere((c) => c.isPopular, orElse: () => p.chips.first);
      _selectedQuantity = _selectedChip!.quantity;
    } else {
      _selectedQuantity = p.minQuantity;
    }
  }

  double _getCalculatedBuyerPrice() {
    final p = widget.service.pricing;
    if (p.modelType == PricingModelType.tieredChips && _selectedChip != null) {
      return _selectedChip!.price;
    } else if (p.modelType == PricingModelType.countBased) {
      return _selectedQuantity * p.unitPrice;
    }
    return p.buyerPrice;
  }

  double _getCalculatedWorkerReward() {
    final buyerPrice = _getCalculatedBuyerPrice();
    final marginFraction = widget.service.pricing.adminMarginPercent / 100.0;
    final reward = buyerPrice * (1.0 - marginFraction);
    return reward < 0 ? 0 : reward;
  }

  @override
  Widget build(BuildContext context) {
    final pricing = widget.service.pricing;

    final filteredElements = widget.service.elements.where((e) {
      if (_isBuyerMode) {
        return e.visibility == VisibilityContext.both || e.visibility == VisibilityContext.buyerOnly;
      } else {
        return e.visibility == VisibilityContext.both || e.visibility == VisibilityContext.workerOnly;
      }
    }).toList();

    final calcCost = _getCalculatedBuyerPrice();
    final calcReward = _getCalculatedWorkerReward();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header & Mode Toggle
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Runtime UI Simulator',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Context Switcher Segmented Control
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBuyerMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isBuyerMode ? Colors.cyanAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Buyer View (Order Service)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isBuyerMode ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBuyerMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isBuyerMode ? Colors.amberAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Worker View (Do Task)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_isBuyerMode ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Simulation Container Screen
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isBuyerMode ? const Color(0xFF1E1B4B) : const Color(0xFF022C22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isBuyerMode ? Colors.indigoAccent : AppColors.success,
                  width: 1.5,
                ),
              ),
              child: ListView(
                children: [
                  // Service Title & Price Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.service.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isBuyerMode ? Colors.cyanAccent.withOpacity(0.2) : Colors.amberAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isBuyerMode
                              ? 'Total: ₹${calcCost.toStringAsFixed(0)}'
                              : 'Reward: ₹${calcReward.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: _isBuyerMode ? Colors.cyanAccent : Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),

                  // BUYER SIMULATOR: PRICING CHIPS & QUANTITY SELECTOR
                  if (_isBuyerMode) ...[
                    // A: Tiered Chips Packages
                    if (pricing.modelType == PricingModelType.tieredChips && pricing.chips.isNotEmpty) ...[
                      const Text('Choose Package:', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? Colors.cyanAccent : Colors.white24,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (chip.isPopular)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      margin: const EdgeInsets.only(bottom: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amberAccent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('POPULAR', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold)),
                                    ),
                                  Text(
                                    chip.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹${chip.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.black87 : Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // B: Count Based Quantity Counter Input
                    if (pricing.modelType == PricingModelType.countBased) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity / Count:', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Rate: ₹${pricing.unitPrice}/unit', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.cyanAccent),
                            onPressed: _selectedQuantity > pricing.minQuantity
                                ? () => setState(() => _selectedQuantity -= 10)
                                : null,
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_selectedQuantity Units',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
                            onPressed: () => setState(() => _selectedQuantity += 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],

                  if (filteredElements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No dynamic elementsvisible.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),

                  ...filteredElements.map((element) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: _renderElementPreview(element),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderElementPreview(dynamic element) {
    switch (element.type as ElementType) {
      case ElementType.heading:
        return Text(
          element.label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        );
      case ElementType.paragraph:
        return Text(
          element.label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        );
      case ElementType.textField:
        return TextField(
          enabled: _isBuyerMode,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: element.label,
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
            hintText: element.properties['placeholder'] ?? 'Enter input...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: Colors.black26,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      case ElementType.actionButton:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigoAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text(element.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          onPressed: () {},
        );
      case ElementType.systemProof:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(element.label, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('Worker screenshot attachment required.', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${element.type.label}: ${element.label}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
        );
    }
  }
}
