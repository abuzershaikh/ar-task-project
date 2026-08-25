import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';

class ServicesPricingScreen extends StatefulWidget {
  const ServicesPricingScreen({super.key});

  @override
  State<ServicesPricingScreen> createState() => _ServicesPricingScreenState();
}

class _ServicesPricingScreenState extends State<ServicesPricingScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _services = [];
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _marginController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    _marginController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = getIt<DioClient>();
      final response = await dio.get(ApiEndpoints.services);
      final list = (response.data['services'] as List?) ?? [];
      setState(() {
        _services = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getServiceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('youtube') || lower.contains('video')) return Icons.play_circle_fill_rounded;
    if (lower.contains('telegram')) return Icons.send_rounded;
    if (lower.contains('insta')) return Icons.camera_alt_rounded;
    return Icons.layers_rounded;
  }

  Color _getServiceColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('youtube') || lower.contains('video')) return Colors.redAccent;
    if (lower.contains('telegram')) return Colors.lightBlueAccent;
    if (lower.contains('insta')) return Colors.pinkAccent;
    return Colors.cyanAccent;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _services.where((item) {
      final q = _searchController.text.toLowerCase().trim();
      if (q.isEmpty) return true;
      final service = item['service'] ?? item;
      final name = (service['name'] ?? '').toString().toLowerCase();
      final code = (service['code'] ?? '').toString().toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        titleSpacing: 14,
        title: const Row(
          children: [
            Icon(Icons.monetization_on_rounded, color: Colors.amberAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Pricing Catalog Engine',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
            onPressed: _fetchServices,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddServiceDialog(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                        onPressed: _fetchServices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
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
                            hintText: 'Search service or code...',
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

                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No services found in catalog', style: TextStyle(color: Colors.white54, fontSize: 13)))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final service = item['service'] ?? item;
                                final activePricing = item['activePricing'] ?? {};
                                final name = service['name'] ?? 'Service #${index + 1}';
                                final code = service['code'] ?? service['type'] ?? 'SVC';
                                final isActive = service['isActive'] ?? true;
                                final double buyerPrice = double.tryParse((activePricing['buyerUnitPrice'] ?? 2.0).toString()) ?? 2.0;
                                final double margin = double.tryParse((activePricing['marginValue'] ?? 25.0).toString()) ?? 25.0;
                                final double workerReward = double.tryParse((activePricing['workerReward'] ?? (buyerPrice * 0.75)).toString()) ?? (buyerPrice * 0.75);
                                final iconColor = _getServiceColor(name);
                                final iconData = _getServiceIcon(name);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header: Icon + Title + Code + Status
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
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
                                                    name,
                                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    code,
                                                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isActive ? 'ACTIVE' : 'INACTIVE',
                                                style: TextStyle(
                                                  color: isActive ? Colors.greenAccent : Colors.redAccent,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // Financial Chips Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildPricingChip('Buyer Unit', '₹${buyerPrice.toStringAsFixed(0)}', Colors.cyanAccent),
                                            _buildPricingChip('Margin', '${margin.toStringAsFixed(0)}%', Colors.tealAccent),
                                            _buildPricingChip('Worker Payout', '₹${workerReward.toStringAsFixed(1)}', Colors.amberAccent),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF334155),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              onPressed: () => _showUpdatePricingDialog(context, service['id']?.toString() ?? ''),
                                              child: const Text('Edit Rate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPricingChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8.5)),
          Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Service Entry', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Service Code (e.g. YT_WATCH)',
                  labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Buyer Unit Price (₹)',
                  labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _marginController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Platform Margin (%)',
                  labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final dio = getIt<DioClient>();
                await dio.post(
                  ApiEndpoints.services,
                  data: {
                    'code': _codeController.text.trim(),
                    'name': _nameController.text.trim(),
                    'buyerUnitPrice': double.tryParse(_priceController.text.trim()) ?? 2.0,
                    'marginValue': double.tryParse(_marginController.text.trim()) ?? 25.0,
                  },
                );
                _fetchServices();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create service: $e')),
                );
              }
            },
            child: const Text('Create Service'),
          ),
        ],
      ),
    );
  }

  void _showUpdatePricingDialog(BuildContext context, String serviceId) {
    if (serviceId.isEmpty) return;
    final priceCtrl = TextEditingController();
    final marginCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Pricing Rate', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'New Buyer Unit Price (₹)',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                filled: true,
                fillColor: Color(0xFF0F172A),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: marginCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'New Margin % (e.g. 25)',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                filled: true,
                fillColor: Color(0xFF0F172A),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final dio = getIt<DioClient>();
                await dio.post(
                  ApiEndpoints.servicePricingHistory(serviceId).replaceAll('/pricing-history', '/pricing'),
                  data: {
                    'buyerUnitPrice': double.tryParse(priceCtrl.text.trim()) ?? 2.0,
                    'marginType': 'PERCENTAGE',
                    'marginValue': double.tryParse(marginCtrl.text.trim()) ?? 25.0,
                  },
                );
                _fetchServices();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update pricing: $e')),
                );
              }
            },
            child: const Text('Save Rate'),
          ),
        ],
      ),
    );
  }
}

