import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/service_builder_bloc.dart';
import '../bloc/service_builder_event.dart';
import '../bloc/service_builder_state.dart';
import 'service_builder_screen.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<ServiceBuilderBloc>().add(LoadServicesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateServiceModal() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_task_rounded, color: Colors.cyanAccent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Service',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Set title & description to launch Template Studio',
                                style: TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 22),

                    // Quick Template Starters
                    const Text('Quick Template Starters:',
                        style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          backgroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Colors.redAccent),
                          label: const Text('YouTube Subscribe', style: TextStyle(fontSize: 10, color: Colors.white)),
                          avatar: const Icon(Icons.play_circle_fill_rounded, color: Colors.redAccent, size: 12),
                          onPressed: () {
                            setModalState(() {
                              nameCtrl.text = 'YouTube Video Watch & Subscribe';
                              descCtrl.text =
                                  'Watch video for 60s, subscribe to channel and upload screenshot proof.';
                            });
                          },
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Colors.lightBlueAccent),
                          label: const Text('Telegram Channel Join', style: TextStyle(fontSize: 10, color: Colors.white)),
                          avatar: const Icon(Icons.send_rounded, color: Colors.lightBlueAccent, size: 12),
                          onPressed: () {
                            setModalState(() {
                              nameCtrl.text = 'Telegram Channel Member Join';
                              descCtrl.text = 'Join official telegram channel, stay member and submit screenshot.';
                            });
                          },
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Colors.pinkAccent),
                          label: const Text('Instagram Follow & Like', style: TextStyle(fontSize: 10, color: Colors.white)),
                          avatar: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 12),
                          onPressed: () {
                            setModalState(() {
                              nameCtrl.text = 'Instagram Follow & Like Post';
                              descCtrl.text = 'Follow profile, like recent post and submit proof screenshot.';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Service Title
                    const Text('Service Title / Name *',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a service title' : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. YouTube Watch & Subscribe',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Service Description
                    const Text('Short Description (Shown to Buyers) *',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter description' : null,
                      decoration: InputDecoration(
                        hintText: 'Brief summary of what workers will execute for the buyer...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Initialize & Open Studio',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final draftCode = 'SVC_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceBuilderScreen(
                                  draftCode: draftCode,
                                  draftName: nameCtrl.text.trim(),
                                  draftDescription: descCtrl.text.trim(),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getServiceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('youtube') || lower.contains('video') || lower.contains('watch')) {
      return Icons.play_circle_fill_rounded;
    }
    if (lower.contains('telegram') || lower.contains('channel') || lower.contains('group')) {
      return Icons.send_rounded;
    }
    if (lower.contains('insta') || lower.contains('follow') || lower.contains('like')) {
      return Icons.camera_alt_rounded;
    }
    if (lower.contains('app') || lower.contains('install') || lower.contains('download')) {
      return Icons.get_app_rounded;
    }
    return Icons.design_services_rounded;
  }

  Color _getServiceColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('youtube') || lower.contains('video')) return Colors.redAccent;
    if (lower.contains('telegram')) return Colors.lightBlueAccent;
    if (lower.contains('insta')) return Colors.pinkAccent;
    if (lower.contains('app')) return Colors.greenAccent;
    return Colors.cyanAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        titleSpacing: 14,
        title: const Row(
          children: [
            Icon(Icons.layers_rounded, color: Colors.cyanAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Services & Pricing Engine',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
            onPressed: () => context.read<ServiceBuilderBloc>().add(LoadServicesEvent()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        onPressed: _showCreateServiceModal,
      ),
      body: BlocListener<ServiceBuilderBloc, ServiceBuilderState>(
        listener: (context, state) {
          if (state is ServiceDeletedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<ServiceBuilderBloc>().add(LoadServicesEvent());
          }
        },
        child: BlocBuilder<ServiceBuilderBloc, ServiceBuilderState>(
          builder: (context, state) {
            if (state is ServiceBuilderLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            } else if (state is ServiceCatalogLoaded) {
              final allServices = state.services;
              final filteredServices = allServices.where((s) {
                final q = _searchController.text.toLowerCase().trim();
                final matchesQuery = q.isEmpty ||
                    s.name.toLowerCase().contains(q) ||
                    s.description.toLowerCase().contains(q);
                if (_selectedFilter == 'All') return matchesQuery;
                if (_selectedFilter == 'YouTube') return matchesQuery && s.name.toLowerCase().contains('youtube');
                if (_selectedFilter == 'Telegram') return matchesQuery && s.name.toLowerCase().contains('telegram');
                if (_selectedFilter == 'Social') {
                  return matchesQuery &&
                      (s.name.toLowerCase().contains('insta') ||
                          s.name.toLowerCase().contains('twitter') ||
                          s.name.toLowerCase().contains('facebook'));
                }
                return matchesQuery;
              }).toList();

              final int activeCount = allServices.where((s) => s.isActive).length;

              return Column(
                children: [
                  // ── 1. Compact Dashboard Stats Bar ──────────────────────
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricItem('Services', '${allServices.length}', Colors.white),
                        Container(height: 24, width: 1, color: Colors.white12),
                        _buildMetricItem('Active', '$activeCount', Colors.greenAccent),
                        Container(height: 24, width: 1, color: Colors.white12),
                        _buildMetricItem('Delivery', '24-72h', Colors.cyanAccent),
                        Container(height: 24, width: 1, color: Colors.white12),
                        _buildMetricItem('Pricing', 'Live Mode', Colors.amberAccent),
                      ],
                    ),
                  ),

                  // ── 2. Search & Category Filters Bar ────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search services, tags, pricing...',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 16),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 14),
                                        onPressed: () => setState(() => _searchController.clear()),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Filter Category Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: ['All', 'YouTube', 'Telegram', 'Social'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.black : Colors.white70,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.cyanAccent,
                            backgroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            onSelected: (_) => setState(() => _selectedFilter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── 3. Services Compact Cards List ─────────────────────
                  Expanded(
                    child: filteredServices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 48, color: Colors.white24),
                                const SizedBox(height: 10),
                                const Text('No matching services found.',
                                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyanAccent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Create Service',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: _showCreateServiceModal,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                            itemCount: filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = filteredServices[index];
                              final iconColor = _getServiceColor(service.name);
                              final iconData = _getServiceIcon(service.name);
                              final pricing = service.pricing;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ServiceBuilderScreen(serviceId: service.id),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Top Header: Icon + Title + Version + Status
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: iconColor.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(iconData, color: iconColor, size: 16),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    service.name,
                                                    style: const TextStyle(
                                                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    service.description.isNotEmpty
                                                        ? service.description
                                                        : 'No description provided.',
                                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: service.isActive
                                                    ? Colors.green.withOpacity(0.15)
                                                    : Colors.red.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                service.isActive ? 'ACTIVE' : 'DRAFT',
                                                style: TextStyle(
                                                  color: service.isActive ? Colors.greenAccent : Colors.redAccent,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // Middle Row: Pricing Pills
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            _buildTag(
                                                'Buyer: ₹${pricing.buyerPrice.toStringAsFixed(0)}', Colors.cyanAccent),
                                            _buildTag(
                                                'Margin: ${pricing.adminMarginPercent.toStringAsFixed(0)}%', Colors.tealAccent),
                                            _buildTag(
                                                'Worker: ₹${pricing.workerReward.toStringAsFixed(1)}', Colors.amberAccent),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // Bottom Action Bar
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'V${service.currentVersion}',
                                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Delete button
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline_rounded,
                                                      color: Colors.redAccent, size: 18),
                                                  tooltip: 'Delete Service',
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(6),
                                                  onPressed: () =>
                                                      _showDeleteConfirmation(context, service.name, service.id),
                                                ),
                                                const SizedBox(width: 6),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.cyanAccent,
                                                    foregroundColor: Colors.black,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  icon: const Icon(Icons.tune_rounded, size: 12),
                                                  label: const Text('Open Studio',
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => ServiceBuilderScreen(serviceId: service.id),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
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
                  ),
                ],
              );
            } else if (state is ServiceBuilderError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String serviceName, String serviceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Delete Service?',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$serviceName"',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Past campaigns & orders will NOT be affected.',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This service will be removed from the catalog and no new orders can be created for it.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ServiceBuilderBloc>().add(DeleteServiceEvent(serviceId));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
      ),
    );
  }
}
