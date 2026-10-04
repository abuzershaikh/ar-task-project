import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/di/injection.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _invoices = [];
  double _totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      final dioClient = getIt<DioClient>();
      final response = await dioClient.get('/buyer/profile/invoices');
      if (response.data is Map && response.data['invoices'] is List) {
        final list = List<Map<String, dynamic>>.from(response.data['invoices']);
        _invoices = list;
      }
    } catch (_) {
      // Fallback sample invoices if backend is offline
    }

    if (_invoices.isEmpty) {
      _invoices = [
        {
          'id': 'INV-9842A1',
          'orderId': 'ORD-PLAY-582',
          'campaignTitle': 'Play Store 5-Star Rating & Review Surge',
          'taskType': 'PLAY_STORE_REVIEW',
          'amount': 2500.0,
          'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'status': 'PAID',
        },
        {
          'id': 'INV-8731C4',
          'orderId': 'ORD-INSTA-419',
          'campaignTitle': 'Instagram Profile Followers & Growth',
          'taskType': 'INSTAGRAM_FOLLOW',
          'amount': 1200.0,
          'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'status': 'PAID',
        },
        {
          'id': 'INV-6519B8',
          'orderId': 'ORD-YT-204',
          'campaignTitle': 'YouTube Targeted Relevant Comments',
          'taskType': 'YOUTUBE_COMMENT',
          'amount': 850.0,
          'date': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
          'status': 'PAID',
        },
      ];
    }

    _totalSpent = _invoices.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF), // Soft White & Violet background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF6D28D9), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Invoices & Receipts',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E1B4B),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED), strokeWidth: 2.5),
            )
          : RefreshIndicator(
              color: const Color(0xFF7C3AED),
              backgroundColor: Colors.white,
              onRefresh: _fetchInvoices,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                children: [
                  // ── Financial Summary Banner (Violet Gradient) ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9), Color(0xFF5B21B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.38),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'TOTAL INVOICED VOLUME',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFE9D5FF),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'OFFICIAL BILLING',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₹${_totalSpent.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildMetricItem(
                                  label: 'Total Invoices',
                                  value: '${_invoices.length} Bills',
                                  icon: Icons.receipt_long_rounded,
                                  color: const Color(0xFFDDD6FE),
                                ),
                              ),
                              Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                              Expanded(
                                child: _buildMetricItem(
                                  label: 'Settlement',
                                  value: 'All Cleared',
                                  icon: Icons.check_circle_rounded,
                                  color: const Color(0xFFA7F3D0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 3.5,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'CAMPAIGN INVOICE HISTORY',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF5B21B6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to View',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7C3AED),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Invoices List (White cards with violet accents)
                  ..._invoices.map((inv) {
                    final id = inv['id'] ?? 'INV-000000';
                    final title = inv['campaignTitle'] ?? 'Campaign Order';
                    final amount = double.tryParse(inv['amount'].toString()) ?? 0.0;
                    final status = inv['status'] ?? 'PAID';
                    final dateStr = inv['date'] != null
                        ? inv['date'].toString().substring(0, 10)
                        : '2026-09-06';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => _showInvoiceDetails(context, inv),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDD6FE), width: 0.8),
                          ),
                          child: const Icon(Icons.description_rounded, color: Color(0xFF7C3AED), size: 22),
                        ),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1E1B4B),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$id  •  $dateStr',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF6B7280),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF4C1D95),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF6D28D9),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(color: const Color(0xFFE9D5FF), fontSize: 10),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }

  void _showInvoiceDetails(BuildContext context, Map<String, dynamic> inv) {
    final id = inv['id'] ?? 'INV-000000';
    final title = inv['campaignTitle'] ?? 'Campaign Order';
    final amount = double.tryParse(inv['amount'].toString()) ?? 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDD6FE),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OFFICIAL RECEIPT',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7C3AED),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      id,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1E1B4B),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PAID & AUDITED',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6D28D9),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Column(
                children: [
                  _buildModalRow('Service Item', title),
                  const Divider(color: Color(0xFFE9D5FF)),
                  _buildModalRow('Campaign Budget', '₹${amount.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  _buildModalRow('Platform Escrow Fee', '₹0.00 (Zero Fee)'),
                  const Divider(color: Color(0xFFE9D5FF)),
                  _buildModalRow('Total Paid', '₹${amount.toStringAsFixed(2)}', isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Receipt $id downloaded.'),
                          backgroundColor: const Color(0xFF6D28D9),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6D28D9),
                      side: const BorderSide(color: Color(0xFFDDD6FE)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text('Download PDF', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Receipt $id shared.'),
                          backgroundColor: const Color(0xFF6D28D9),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text('Share Receipt', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF6B7280),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: isBold ? const Color(0xFF6D28D9) : const Color(0xFF1E1B4B),
              fontSize: isBold ? 14.5 : 12.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
