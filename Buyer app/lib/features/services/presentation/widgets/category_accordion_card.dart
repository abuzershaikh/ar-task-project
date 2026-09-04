import 'package:flutter/material.dart';
import '../../domain/models/service_model.dart';
import '../../../../core/utils/service_unit_helper.dart';

class CategoryAccordionCard extends StatefulWidget {
  final String categoryName;
  final IconData icon;
  final Color themeColor;
  final List<ServiceModel> services;
  final bool initialExpanded;
  final ValueChanged<ServiceModel> onSelectService;

  const CategoryAccordionCard({
    super.key,
    required this.categoryName,
    required this.icon,
    required this.themeColor,
    required this.services,
    this.initialExpanded = false,
    required this.onSelectService,
  });

  @override
  State<CategoryAccordionCard> createState() => _CategoryAccordionCardState();
}

class _CategoryAccordionCardState extends State<CategoryAccordionCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final activeServices = widget.services.where((s) => s.isActive).toList();
    if (activeServices.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isExpanded ? widget.themeColor.withOpacity(0.4) : const Color(0xFFE2E8F0),
          width: _isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isExpanded
                ? widget.themeColor.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Card (Tappable Accordion Tile)
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Category Icon Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.themeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.themeColor, size: 24),
                  ),
                  const SizedBox(width: 14),

                  // Title and sub-services count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activeServices.length} Services available',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expand / Collapse Chevron with Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isExpanded
                          ? widget.themeColor.withOpacity(0.1)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'Hide' : 'View',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isExpanded ? widget.themeColor : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _isExpanded ? widget.themeColor : const Color(0xFF64748B),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content Area (Sub-Services List)
          if (_isExpanded) ...[
            const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: activeServices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final service = activeServices[idx];
                final isAi = service.aiGeneratorEnabled;
                final price = service.pricing.buyerPrice;

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: InkWell(
                    onTap: () => widget.onSelectService(service),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Icon + Title + AI Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Icon(
                                  _getServiceSubIcon(service.code),
                                  size: 18,
                                  color: widget.themeColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (isAi) ...[
                                      const SizedBox(height: 3),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFBBF7D0)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified_rounded,
                                                size: 10, color: Color(0xFF16A34A)),
                                            SizedBox(width: 3),
                                            Text(
                                              'Unique Human Comments',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF15803D),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (service.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              service.description,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),
                          const Divider(color: Color(0xFFE2E8F0), height: 1),
                          const SizedBox(height: 8),

                          // Bottom Row: Price Rate & Order Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rate',
                                    style: TextStyle(
                                        fontSize: 9.5,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    ServiceUnitHelper.getRateLabel(service.name, price),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: widget.themeColor,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.themeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () => widget.onSelectService(service),
                                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                label: const Text(
                                  'Order',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  IconData _getServiceSubIcon(String code) {
    final c = code.toUpperCase();
    if (c.contains('REVIEW') || c.contains('RATING')) return Icons.star_rate_rounded;
    if (c.contains('COMMENT')) return Icons.chat_bubble_outline_rounded;
    if (c.contains('LIKE')) return Icons.thumb_up_alt_outlined;
    if (c.contains('SUBSCRIBE') || c.contains('SUB')) return Icons.notifications_active_outlined;
    if (c.contains('COMBO')) return Icons.auto_awesome_rounded;
    if (c.contains('INSTALL')) return Icons.get_app_rounded;
    if (c.contains('FOLLOW')) return Icons.person_add_alt_1_rounded;
    return Icons.check_circle_outline_rounded;
  }
}
