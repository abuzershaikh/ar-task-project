import 'package:flutter/material.dart';
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
  bool _isBuyerMode = true; // true = Buyer View, false = Worker View
  PriceChipModel? _selectedChip;
  int _selectedQuantity = 100;

  // Blue & White Palette
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color lightBlueBg = Color(0xFFEFF6FF);
  static const Color surfaceWhite = Colors.white;
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    final p = widget.service.pricing;
    if (p.chips.isNotEmpty) {
      _selectedChip = p.chips.firstWhere((c) => c.isPopular, orElse: () => p.chips.first);
      _selectedQuantity = _selectedChip!.quantity;
    } else {
      _selectedQuantity = p.minQuantity > 0 ? p.minQuantity : 100;
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
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header & Mode Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lightBlueBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Icon(Icons.remove_red_eye_rounded, color: accentBlue, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Runtime Preview',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Simulate buyer and worker interactive views',
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: textSecondary, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: borderSubtle, height: 1),
          const SizedBox(height: 12),

          // Context Switcher Segmented Control
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: backgroundLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBuyerMode = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _isBuyerMode ? accentBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _isBuyerMode
                            ? [
                                BoxShadow(
                                  color: accentBlue.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 16,
                            color: _isBuyerMode ? Colors.white : textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Buyer View (Order)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isBuyerMode ? Colors.white : textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBuyerMode = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: !_isBuyerMode ? const Color(0xFF16A34A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_isBuyerMode
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF16A34A).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_outline_rounded,
                            size: 16,
                            color: !_isBuyerMode ? Colors.white : textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Worker View (Task)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isBuyerMode ? Colors.white : textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isBuyerMode ? const Color(0xFFF8FAFC) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isBuyerMode ? const Color(0xFFBFDBFE) : const Color(0xFFBBF7D0),
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
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isBuyerMode ? lightBlueBg : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isBuyerMode ? const Color(0xFFBFDBFE) : const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Text(
                          _isBuyerMode
                              ? 'Total: ₹${calcCost.toStringAsFixed(0)}'
                              : 'Reward: ₹${calcReward.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: _isBuyerMode ? primaryBlue : const Color(0xFF15803D),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: borderSubtle, height: 1),
                  const SizedBox(height: 14),

                  // BUYER SIMULATOR: PRICING CHIPS & QUANTITY SELECTOR
                  if (_isBuyerMode) ...[
                    // Tiered Chips Packages
                    if (pricing.modelType == PricingModelType.tieredChips && pricing.chips.isNotEmpty) ...[
                      const Text(
                        'Choose Package Option:',
                        style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? accentBlue : surfaceWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? accentBlue : borderSubtle,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (chip.isPopular)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'POPULAR',
                                        style: TextStyle(
                                          color: Color(0xFFB45309),
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    chip.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${chip.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : primaryBlue,
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
                      const SizedBox(height: 14),
                    ],

                    // Count-based selector
                    if (pricing.modelType == PricingModelType.countBased) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quantity / Count:',
                            style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rate: ₹${pricing.unitPrice}/unit',
                            style: const TextStyle(color: textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: accentBlue),
                            onPressed: _selectedQuantity > pricing.minQuantity
                                ? () => setState(() => _selectedQuantity -= 10)
                                : null,
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: surfaceWhite,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderSubtle),
                              ),
                              child: Text(
                                '$_selectedQuantity Units',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: accentBlue),
                            onPressed: () => setState(() => _selectedQuantity += 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],

                  if (filteredElements.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isBuyerMode ? Icons.shopping_bag_outlined : Icons.assignment_outlined,
                            size: 32,
                            color: textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isBuyerMode
                                ? 'Buyer will provide target link and details at checkout.'
                                : 'Worker will follow guidelines and submit verification proof.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: textSecondary, fontSize: 12),
                          ),
                        ],
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
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: lightBlueBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: accentBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  element.label.isNotEmpty ? element.label : widget.service.name,
                  style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

      case ElementType.paragraph:
        final content = element.properties['content']?.toString() ??
            element.properties['instructions']?.toString() ??
            widget.service.description;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notes_rounded, color: accentBlue, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    element.label.isNotEmpty ? element.label : 'Task Instructions & Guidelines',
                    style: const TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                content.isNotEmpty ? content : 'Complete the task as guided by admin.',
                style: const TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        );

      case ElementType.youtube:
        final vidUrl = element.properties['url']?.toString() ?? element.properties['videoUrl']?.toString() ?? '';
        final regExp = RegExp(r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})', caseSensitive: false);
        final match = regExp.firstMatch(vidUrl.trim());
        final ytId = match?.group(1);

        return Container(
          width: double.infinity,
          height: 130,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEF4444)),
            image: ytId != null
                ? DecorationImage(
                    image: NetworkImage('https://img.youtube.com/vi/$ytId/hqdefault.jpg'),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.black.withOpacity(0.35)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
              ),
              Positioned(
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    element.label.isNotEmpty ? element.label : 'Tutorial Video',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );

      case ElementType.audio:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: lightBlueBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: accentBlue, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.label.isNotEmpty ? element.label : 'Voice Guide (Audio)',
                      style: const TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text('Listen to audio note carefully to complete task',
                        style: TextStyle(color: textSecondary, fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.graphic_eq_rounded, color: accentBlue, size: 20),
            ],
          ),
        );

      case ElementType.actionButton:
        if (_isBuyerMode) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.link_rounded, color: accentBlue, size: 16),
                  const SizedBox(width: 6),
                  Text('${element.label} (Your Channel / Video / Link)',
                      style: const TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                enabled: true,
                style: const TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Target URL to promote',
                  labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
                  hintText: 'https://youtube.com/watch?v=... or @channel_link',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  filled: true,
                  fillColor: surfaceWhite,
                  prefixIcon: const Icon(Icons.link_rounded, color: accentBlue, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderSubtle)),
                ),
              ),
            ],
          );
        } else {
          return SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(
                element.properties['buttonText']?.toString() ?? element.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: () {},
            ),
          );
        }

      case ElementType.numberField:
        if (_isBuyerMode) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(element.label,
                        style: const TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('Selected: $_selectedQuantity',
                        style: const TextStyle(color: accentBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, color: accentBlue),
                      onPressed: _selectedQuantity > 10 ? () => setState(() => _selectedQuantity -= 10) : null,
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Text(
                          '$_selectedQuantity Units',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: accentBlue),
                      onPressed: () => setState(() => _selectedQuantity += 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();

      case ElementType.systemProof:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                element.label,
                style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'Worker screenshot & proof attachment required.',
                style: TextStyle(color: Color(0xFF92400E), fontSize: 11),
              ),
            ],
          ),
        );

      case ElementType.systemTimer:
        final dur = element.properties['durationSeconds'] ?? 60;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: lightBlueBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: accentBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Required Stay Time: ${dur}s',
                  style: const TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: surfaceWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderSubtle),
          ),
          child: Text(
            '${element.type.label}: ${element.label}',
            style: const TextStyle(color: textSecondary, fontSize: 11),
          ),
        );
    }
  }
}
