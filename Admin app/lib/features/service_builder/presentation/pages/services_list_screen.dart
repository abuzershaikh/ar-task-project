import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/service_builder_bloc.dart';
import '../bloc/service_builder_event.dart';
import '../bloc/service_builder_state.dart';
import 'service_builder_screen.dart';
import 'task_expiry_settings_screen.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  // Professional Blue Theme Colors
  static const Color primaryBlue = Color(0xFF1E40AF); // Deep Royal Blue
  static const Color accentBlue = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color lightBlueBg = Color(0xFFEFF6FF); // Soft Blue Tint
  static const Color surfaceWhite = Colors.white;
  static const Color backgroundLight = Color(0xFFF8FAFC); // Clean Light Slate
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate
  static const Color textSecondary = Color(0xFF64748B); // Slate Muted
  static const Color borderSubtle = Color(0xFFE2E8F0); // Subtle Border

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

  Future<void> _navigateToBuilder(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) {
      context.read<ServiceBuilderBloc>().add(LoadServicesEvent());
    }
  }

  void _showCreateServiceModal() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: lightBlueBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Icon(Icons.add_task_rounded, color: accentBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Service',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Configure title & description to launch Service Studio',
                            style: TextStyle(color: textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: textSecondary, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: borderSubtle, height: 1),
                const SizedBox(height: 20),

                // Service Title
                const Text(
                  'Service Title / Name *',
                  style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a service title' : null,
                  decoration: InputDecoration(
                    hintText: 'e.g. YouTube Watch & Subscribe',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: backgroundLight,
                    prefixIcon: const Icon(Icons.title_rounded, color: accentBlue, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: accentBlue, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Service Description
                const Text(
                  'Short Description (Shown to Buyers) *',
                  style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: textPrimary, fontSize: 13),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a description' : null,
                  decoration: InputDecoration(
                    hintText: 'Brief summary of what workers will execute for the buyer...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    filled: true,
                    fillColor: backgroundLight,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 36),
                      child: Icon(Icons.notes_rounded, color: accentBlue, size: 18),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: accentBlue, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: accentBlue.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text(
                      'Initialize & Open Studio',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final draftCode = 'SVC_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                        Navigator.pop(ctx);
                        _navigateToBuilder(
                          ServiceBuilderScreen(
                            draftCode: draftCode,
                            draftName: nameCtrl.text.trim(),
                            draftDescription: descCtrl.text.trim(),
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
      ),
    );
  }

  IconData _getServiceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('playstore') || lower.contains('play store') || lower.contains('play_store')) {
      return Icons.shop_two_rounded;
    }
    if (lower.contains('youtube') || lower.contains('video') || lower.contains('watch')) {
      return Icons.play_circle_fill_rounded;
    }
    if (lower.contains('insta') || lower.contains('follow') || lower.contains('like')) {
      return Icons.camera_alt_rounded;
    }
    if (lower.contains('app') || lower.contains('install') || lower.contains('download')) {
      return Icons.get_app_rounded;
    }
    return Icons.layers_rounded;
  }

  Color _getServiceColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('playstore') || lower.contains('play store') || lower.contains('play_store')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('youtube') || lower.contains('video')) return const Color(0xFFEF4444);
    if (lower.contains('insta')) return const Color(0xFFEC4899);
    if (lower.contains('app')) return const Color(0xFF10B981);
    return accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderSubtle, height: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: lightBlueBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(Icons.layers_rounded, color: accentBlue, size: 19),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Services & Pricing Engine',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Manage catalog, pricing, & worker rules',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Task Expiry & Timeout Settings',
            icon: const Icon(Icons.timer_outlined, color: primaryBlue, size: 22),
            onPressed: () {
              _navigateToBuilder(const TaskExpirySettingsScreen());
            },
          ),
          IconButton(
            tooltip: 'Refresh Services',
            icon: const Icon(Icons.refresh_rounded, color: accentBlue, size: 22),
            onPressed: () => context.read<ServiceBuilderBloc>().add(LoadServicesEvent()),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Service', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        onPressed: _showCreateServiceModal,
      ),
      body: BlocListener<ServiceBuilderBloc, ServiceBuilderState>(
        listener: (context, state) {
          if (state is ServiceDeletedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            context.read<ServiceBuilderBloc>().add(LoadServicesEvent());
          }
        },
        child: BlocBuilder<ServiceBuilderBloc, ServiceBuilderState>(
          builder: (context, state) {
            if (state is ServiceBuilderLoading) {
              return const Center(
                child: CircularProgressIndicator(color: accentBlue),
              );
            } else if (state is ServiceCatalogLoaded) {
              final allServices = state.services;
              final filteredServices = allServices.where((s) {
                final q = _searchController.text.toLowerCase().trim();
                final matchesQuery = q.isEmpty ||
                    s.name.toLowerCase().contains(q) ||
                    s.description.toLowerCase().contains(q);
                if (_selectedFilter == 'All') return matchesQuery;
                if (_selectedFilter == 'YouTube') return matchesQuery && s.name.toLowerCase().contains('youtube');
                if (_selectedFilter == 'PlayStore') {
                  final lowerName = s.name.toLowerCase();
                  final lowerCode = s.code.toLowerCase();
                  return matchesQuery &&
                      (lowerName.contains('playstore') ||
                          lowerName.contains('play store') ||
                          lowerName.contains('app') ||
                          lowerName.contains('install') ||
                          lowerName.contains('download') ||
                          lowerName.contains('rating') ||
                          lowerName.contains('review') ||
                          lowerCode.contains('playstore') ||
                          lowerCode.contains('app'));
                }
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
                  const SizedBox(height: 10),

                  // ── 1. Clean White Dashboard Metrics Bar ──────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildMetricItem('Total Services', '${allServices.length}', primaryBlue, Icons.apps_rounded)),
                        Container(height: 28, width: 1, color: borderSubtle),
                        Expanded(child: _buildMetricItem('Active', '$activeCount', const Color(0xFF10B981), Icons.check_circle_rounded)),
                        Container(height: 28, width: 1, color: borderSubtle),
                        Expanded(child: _buildMetricItem('Turnaround', '24-72h', const Color(0xFF0EA5E9), Icons.timer_outlined)),
                        Container(height: 28, width: 1, color: borderSubtle),
                        Expanded(child: _buildMetricItem('Engine', 'Live', const Color(0xFF8B5CF6), Icons.bolt_rounded)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── 2. Search & Category Filters Bar ────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: textPrimary, fontSize: 13),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search services, tags, pricing...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: accentBlue, size: 18),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: textSecondary, size: 16),
                                  onPressed: () => setState(() => _searchController.clear()),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Category Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        {'name': 'All', 'icon': Icons.apps_rounded},
                        {'name': 'YouTube', 'icon': Icons.play_circle_fill_rounded},
                        {'name': 'PlayStore', 'icon': Icons.shop_two_rounded},
                        {'name': 'Social', 'icon': Icons.camera_alt_rounded},
                      ].map((chip) {
                        final filter = chip['name'] as String;
                        final icon = chip['icon'] as IconData;
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setState(() => _selectedFilter = filter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? accentBlue : surfaceWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? accentBlue : borderSubtle,
                                ),
                                boxShadow: isSelected
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : (filter == 'PlayStore'
                                            ? const Color(0xFF10B981)
                                            : (filter == 'YouTube'
                                                ? const Color(0xFFEF4444)
                                                : (filter == 'Social'
                                                    ? const Color(0xFFEC4899)
                                                    : accentBlue))),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    filter,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── 3. Services Clean White Cards List ─────────────────
                  Expanded(
                    child: filteredServices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: lightBlueBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.search_off_rounded, size: 36, color: accentBlue),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No matching services found',
                                  style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Try a different search or create a new service',
                                  style: TextStyle(color: textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Create Service',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: _showCreateServiceModal,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: accentBlue,
                            onRefresh: () async {
                              context.read<ServiceBuilderBloc>().add(LoadServicesEvent());
                            },
                            child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 2, 14, 90),
                            itemCount: filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = filteredServices[index];
                              final iconColor = _getServiceColor(service.name);
                              final iconData = _getServiceIcon(service.name);
                              final pricing = service.pricing;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: surfaceWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderSubtle),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.025),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _navigateToBuilder(
                                    ServiceBuilderScreen(serviceId: service.id),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row: Icon + Title + Version + Status
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(9),
                                              decoration: BoxDecoration(
                                                color: iconColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: iconColor.withOpacity(0.2)),
                                              ),
                                              child: Icon(iconData, color: iconColor, size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    service.name,
                                                    style: const TextStyle(
                                                      color: textPrimary,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: -0.2,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    service.description.isNotEmpty
                                                        ? service.description
                                                        : 'No description provided.',
                                                    style: const TextStyle(color: textSecondary, fontSize: 11),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: service.isActive
                                                    ? const Color(0xFFECFDF5)
                                                    : const Color(0xFFFFFBEB),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: service.isActive
                                                      ? const Color(0xFFA7F3D0)
                                                      : const Color(0xFFFDE68A),
                                                ),
                                              ),
                                              child: Text(
                                                service.isActive ? 'ACTIVE' : 'DRAFT',
                                                style: TextStyle(
                                                  color: service.isActive
                                                      ? const Color(0xFF059669)
                                                      : const Color(0xFFD97706),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Pricing Pills Row
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _buildPill(
                                              'Buyer: ₹${pricing.buyerPrice.toStringAsFixed(0)}',
                                              lightBlueBg,
                                              primaryBlue,
                                              const Color(0xFFBFDBFE),
                                            ),
                                            _buildPill(
                                              'Margin: ${pricing.adminMarginPercent.toStringAsFixed(0)}%',
                                              const Color(0xFFF5F3FF),
                                              const Color(0xFF7C3AED),
                                              const Color(0xFFDDD6FE),
                                            ),
                                            _buildPill(
                                              'Worker: ₹${pricing.workerReward.toStringAsFixed(1)}',
                                              const Color(0xFFECFDF5),
                                              const Color(0xFF059669),
                                              const Color(0xFFA7F3D0),
                                            ),
                                            if (service.aiGeneratorEnabled)
                                              _buildPill(
                                                '✨ AI Powered',
                                                const Color(0xFFFAF5FF),
                                                const Color(0xFF9333EA),
                                                const Color(0xFFE9D5FF),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(color: borderSubtle, height: 1),
                                        const SizedBox(height: 10),

                                        // Footer Bar
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Code: ${service.code} • v${service.currentVersion}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Delete button
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline_rounded,
                                                    color: Color(0xFFEF4444),
                                                    size: 18,
                                                  ),
                                                  tooltip: 'Delete Service',
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(6),
                                                  onPressed: () =>
                                                      _showDeleteConfirmation(context, service.name, service.id),
                                                ),
                                                const SizedBox(width: 6),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: lightBlueBg,
                                                    foregroundColor: primaryBlue,
                                                    elevation: 0,
                                                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  icon: const Icon(Icons.tune_rounded, size: 14, color: primaryBlue),
                                                  label: const Text(
                                                    'Open Studio',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                  onPressed: () => _navigateToBuilder(
                                                    ServiceBuilderScreen(serviceId: service.id),
                                                  ),
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
                  ),
                ],
              );
            } else if (state is ServiceBuilderError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: const TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => context.read<ServiceBuilderBloc>().add(LoadServicesEvent()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            // Auto-reload catalog when returning from editor in ServiceEditingState or any unhandled state
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<ServiceBuilderBloc>().add(LoadServicesEvent());
              }
            });
            return const Center(
              child: CircularProgressIndicator(color: accentBlue),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String serviceName, String serviceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete Service?',
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$serviceName"',
              style: const TextStyle(color: accentBlue, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Past campaigns & orders will NOT be affected.',
                      style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This service will be removed from the catalog and buyers will no longer be able to place new orders for it.',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  Widget _buildMetricItem(String label, String value, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPill(String text, Color bgColor, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
