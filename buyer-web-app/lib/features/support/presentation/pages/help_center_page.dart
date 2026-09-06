import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_router.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How are micro-worker tasks audited & proofs verified?',
      'a': 'Every single micro-task requires high-resolution screenshot evidence. Our automated audit engine analyzes device IDs, timestamps, and account handles to eliminate fraud and bots. You can also manually review submissions in your campaign dashboard before approving them.',
      'cat': 'Auditing',
    },
    {
      'q': 'How does the 100% Escrow Money-Back guarantee work?',
      'a': 'When you fund a campaign, budget is securely held in an automated escrow vault. If a task fails verification or is rejected for non-compliance, funds are automatically refunded back to your Marketing Pro wallet immediately.',
      'cat': 'Billing',
    },
    {
      'q': 'How does the Comment Generator work for YouTube & Instagram?',
      'a': 'Our platform prepares context-specific, human-like comments based on your channel topic, post theme, and tone (Supportive, Enthusiastic, Professional). Micro-workers receive unique, spam-free prompts to post.',
      'cat': 'Comments',
    },
    {
      'q': 'How fast do campaigns start after ordering?',
      'a': 'Orders enter our high-speed dispatch queue within 60 seconds of activation. Active Indian smartphone workers immediately receive notifications and begin downloading, rating, or engaging.',
      'cat': 'Delivery',
    },
    {
      'q': 'How do I download official receipts and campaign invoices?',
      'a': 'All completed and funded campaigns generate itemized statements with transaction reference IDs. You can view, inspect, and download official receipts directly from the Invoices & Billing section under your Profile.',
      'cat': 'Invoices',
    },
    {
      'q': 'Are the workers real human users or automated bots?',
      'a': '100% real human users. Every worker in the EarnPost network uses real Android hardware, unique IP addresses, and authentic Google & social media accounts. Automated bots and emulator farms are strictly blocked by hardware fingerprinting.',
      'cat': 'Quality',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((f) {
      final q = f['q']!.toLowerCase();
      final a = f['a']!.toLowerCase();
      final s = _searchQuery.toLowerCase();
      return q.contains(s) || a.contains(s);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF080C16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help Center & FAQs',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              hintText: 'Search questions, escrow, comments...',
              hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '${filteredFaqs.length} Articles',
                style: GoogleFonts.outfit(color: const Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // FAQ Accordion List
          if (filteredFaqs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text(
                'No matching questions found.\nTry a different search term or contact VIP Support.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
              ),
            )
          else
            ...filteredFaqs.map((faq) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    iconColor: const Color(0xFF38BDF8),
                    collapsedIconColor: const Color(0xFF64748B),
                    title: Text(
                      faq['q']!,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['a']!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),

          // Need More Help Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Color(0xFF38BDF8), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need Dedicated Help?',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Our VIP campaign managers are available 24/7.',
                        style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRouter.support),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Contact →',
                      style: GoogleFonts.outfit(color: const Color(0xFF080C16), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
