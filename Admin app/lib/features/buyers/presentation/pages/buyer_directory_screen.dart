import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/buyer_card.dart';
import '../bloc/buyers_bloc.dart';
import 'buyer_detail_screen.dart';

class BuyerDirectoryScreen extends StatefulWidget {
  const BuyerDirectoryScreen({super.key});

  @override
  State<BuyerDirectoryScreen> createState() => _BuyerDirectoryScreenState();
}

class _BuyerDirectoryScreenState extends State<BuyerDirectoryScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    context.read<BuyersBloc>().add(LoadBuyersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectAll(List<dynamic> items) {
    setState(() {
      final allSelected = items.isNotEmpty && items.every((item) => _selectedIds.contains(item.id));
      if (allSelected) {
        for (final item in items) {
          _selectedIds.remove(item.id);
        }
      } else {
        for (final item in items) {
          _selectedIds.add(item.id);
        }
      }
    });
  }

  void _confirmDeleteSelected(BuildContext context) {
    final count = _selectedIds.length;
    if (count == 0) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete $count Buyer${count > 1 ? 's' : ''}?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete $count selected buyer account${count > 1 ? 's' : ''}? This will cascade delete their campaigns, orders, tasks, and commercial wallet history. This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final idsToDelete = _selectedIds.toList();
              context.read<BuyersBloc>().add(BatchDeleteBuyersEvent(idsToDelete));
              setState(() {
                _selectedIds.clear();
                _isSelectionMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleting $count buyer${count > 1 ? 's' : ''}...'),
                  backgroundColor: const Color(0xFF0F172A),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSingle(BuildContext context, dynamic buyer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Buyer?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${buyer.name}" (${buyer.email.isNotEmpty ? buyer.email : buyer.id})? All associated campaigns, orders, and wallet records will be wiped.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BuyersBloc>().add(DeleteBuyerEvent(buyer.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleting buyer ${buyer.name}...'),
                  backgroundColor: const Color(0xFF0F172A),
                ),
              );
            },
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyersBloc, BuyersState>(
      builder: (context, state) {
        List<dynamic> currentFiltered = [];
        if (state is BuyersLoaded) {
          final query = _searchController.text.trim().toLowerCase();
          currentFiltered = state.buyers.where((b) {
            final matchesFilter = _selectedFilter == 'All' || b.status.toUpperCase() == _selectedFilter.toUpperCase();
            final matchesQuery = query.isEmpty ||
                b.name.toLowerCase().contains(query) ||
                b.email.toLowerCase().contains(query) ||
                b.id.toLowerCase().contains(query);
            return matchesFilter && matchesQuery;
          }).toList();
        }

        final bool isAllSelected = currentFiltered.isNotEmpty &&
            currentFiltered.every((b) => _selectedIds.contains(b.id));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F3FF),
          appBar: AppBar(
            titleSpacing: 14,
            elevation: 0,
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedIds.clear();
                      });
                    },
                  )
                : null,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: _isSelectionMode
                ? Row(
                    children: [
                      Text(
                        '${_selectedIds.length} Selected',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : const Row(
                    children: [
                      Icon(Icons.business_center_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Buyer Operations',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
            backgroundColor: Colors.transparent,
            actions: _isSelectionMode
                ? [
                    IconButton(
                      tooltip: isAllSelected ? 'Deselect All' : 'Select All',
                      icon: Icon(
                        isAllSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => _toggleSelectAll(currentFiltered),
                    ),
                    IconButton(
                      tooltip: 'Delete Selected',
                      icon: Icon(
                        Icons.delete_forever_rounded,
                        color: _selectedIds.isNotEmpty ? const Color(0xFFFCA5A5) : Colors.white38,
                        size: 24,
                      ),
                      onPressed: _selectedIds.isNotEmpty ? () => _confirmDeleteSelected(context) : null,
                    ),
                  ]
                : [
                    IconButton(
                      tooltip: 'Select / Delete Multiple',
                      icon: const Icon(Icons.checklist_rounded, color: Colors.white, size: 22),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      onPressed: () => context.read<BuyersBloc>().add(LoadBuyersEvent()),
                    ),
                  ],
          ),
          bottomNavigationBar: _isSelectionMode && _selectedIds.isNotEmpty
              ? SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: const Border(top: BorderSide(color: Color(0xFFDDD6FE), width: 1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.delete_forever_rounded, size: 20),
                            label: Text(
                              'Delete (${_selectedIds.length}) Buyers',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () => _confirmDeleteSelected(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedIds.clear();
                              _isSelectionMode = false;
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          body: _buildBody(state, currentFiltered),
        );
      },
    );
  }

  Widget _buildBody(BuyersState state, List<dynamic> filtered) {
    if (state is BuyersLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    if (state is BuyersError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              onPressed: () => context.read<BuyersBloc>().add(LoadBuyersEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is BuyersLoaded) {
      final allBuyers = state.buyers;
      final int activeCount = allBuyers.where((b) => b.status.toUpperCase() == 'ACTIVE').length;
      final double totalPlatformSpend = allBuyers.fold(0.0, (sum, b) => sum + b.totalSpend);
      final int flaggedCount = allBuyers.where((b) => b.status.toUpperCase() != 'ACTIVE').length;
      final String riskStatus = flaggedCount == 0 ? 'Safe 🟢' : '$flaggedCount Flagged ⚠️';
      final Color riskColor = flaggedCount == 0 ? const Color(0xFF16A34A) : const Color(0xFFD97706);

      return Column(
        children: [
          // ── 1. Top Metrics Strip ─────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC4B5FD), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A4F46E5),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricItem('Total Buyers', '${allBuyers.length}', const Color(0xFF1E1B4B)),
                Container(height: 24, width: 1, color: const Color(0xFFC4B5FD)),
                _buildMetricItem('Active', '$activeCount', const Color(0xFF16A34A)),
                Container(height: 24, width: 1, color: const Color(0xFFC4B5FD)),
                _buildMetricItem(
                  'Total Volume',
                  totalPlatformSpend >= 1000 ? '₹${(totalPlatformSpend / 1000).toStringAsFixed(1)}K' : '₹${totalPlatformSpend.toStringAsFixed(0)}',
                  const Color(0xFF4F46E5),
                ),
                Container(height: 24, width: 1, color: const Color(0xFFC4B5FD)),
                _buildMetricItem('Risk Status', riskStatus, riskColor),
              ],
            ),
          ),

          // ── 2. Compact Search Bar ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x064F46E5),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Color(0xFF1E1B4B), fontSize: 12),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by Buyer ID, Company, Email...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4F46E5), size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF6B7280), size: 16),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── 3. Filter Chips ──────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: ['All', 'ACTIVE', 'SUSPENDED', 'BLOCKED'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF4338CA),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF4F46E5),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFDDD6FE),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── 4. Buyer Cards List ──────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_center_outlined, size: 48, color: Color(0xFF9CA3AF)),
                        SizedBox(height: 10),
                        Text('No buyers matching criteria', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF4F46E5),
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      context.read<BuyersBloc>().add(LoadBuyersEvent());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final b = filtered[index];
                        final isSelected = _selectedIds.contains(b.id);
                        return BuyerCard(
                          buyerId: b.id,
                          companyName: b.name,
                          email: b.email,
                          avatarUrl: b.avatarUrl,
                          totalOrders: b.totalOrders,
                          activeCampaigns: b.activeCampaigns,
                          totalSpend: b.totalSpend,
                          status: b.status,
                          isSelectionMode: _isSelectionMode,
                          isSelected: isSelected,
                          onSelectChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedIds.add(b.id);
                              } else {
                                _selectedIds.remove(b.id);
                              }
                            });
                          },
                          onDelete: () => _confirmDeleteSingle(context, b),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                       builder: (_) => BuyerDetailScreen(
                                        buyerId: b.id,
                                        initialBuyer: b,
                                      ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(color: Color(0xFF4338CA), fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
