import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/currency_service.dart';

/// Reusable Sleek Toggle Switch for INR (₹) and USD ($)
/// Designed with glassmorphic obsidian styling for Buyer App
class CurrencyToggleSwitch extends StatelessWidget {
  final bool compact;
  final VoidCallback? onToggled;

  const CurrencyToggleSwitch({
    super.key,
    this.compact = false,
    this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    final currencyService = CurrencyService.instance;

    return ValueListenableBuilder<String>(
      valueListenable: currencyService.currencyNotifier,
      builder: (context, activeCurrency, _) {
        final isUSD = activeCurrency == 'USD';

        return GestureDetector(
          onTap: () {
            currencyService.switchToggle();
            onToggled?.call();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: compact ? 30 : 34,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUSD ? const Color(0xFF38BDF8).withValues(alpha: 0.6) : const Color(0xFF6366F1).withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isUSD ? const Color(0xFF38BDF8) : const Color(0xFF6366F1)).withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // INR Tab
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
                  decoration: BoxDecoration(
                    gradient: !isUSD
                        ? const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹',
                        style: GoogleFonts.outfit(
                          color: !isUSD ? Colors.white : const Color(0xFF94A3B8),
                          fontSize: compact ? 12 : 13,
                          fontWeight: !isUSD ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 3),
                        Text(
                          'INR',
                          style: GoogleFonts.outfit(
                            color: !isUSD ? Colors.white : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: !isUSD ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 2),

                // USD Tab
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
                  decoration: BoxDecoration(
                    gradient: isUSD
                        ? const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$',
                        style: GoogleFonts.outfit(
                          color: isUSD ? Colors.white : const Color(0xFF94A3B8),
                          fontSize: compact ? 12 : 13,
                          fontWeight: isUSD ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 3),
                        Text(
                          'USD',
                          style: GoogleFonts.outfit(
                            color: isUSD ? Colors.white : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: isUSD ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
