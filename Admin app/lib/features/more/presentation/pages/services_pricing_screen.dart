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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services & Pricing Engine'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _showAddServiceDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchServices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchServices, child: const Text('Retry')),
                    ],
                  ),
                )
              : _services.isEmpty
                  ? const Center(child: Text('No services found in catalog'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final item = _services[index];
                        final service = item['service'] ?? item;
                        final activePricing = item['activePricing'] ?? {};
                        final name = service['name'] ?? 'Service #${index + 1}';
                        final code = service['code'] ?? service['type'] ?? 'GENERIC';
                        final isActive = service['isActive'] ?? true;
                        final status = isActive ? 'ACTIVE' : 'INACTIVE';
                        final buyerPrice = (activePricing['buyerUnitPrice'] ?? 2.0).toString();
                        final margin = (activePricing['marginValue'] ?? 25.0).toString();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.shopping_bag, color: AppColors.primary),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(code),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'ACTIVE'
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.gray300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: status == 'ACTIVE' ? AppColors.success : AppColors.gray600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Current Pricing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    _buildPricingRow('Buyer Unit Price', '₹$buyerPrice'),
                                    _buildPricingRow('Platform Margin', '$margin%'),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => _showUpdatePricingDialog(context, service['id']?.toString() ?? ''),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Create New Pricing Version'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildPricingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Service Catalog Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Service Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Service Code (e.g. YOUTUBE_LIKE)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Buyer Unit Price (₹)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _marginController,
              decoration: const InputDecoration(labelText: 'Platform Margin (₹ or %)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
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
                    'marginValue': double.tryParse(_marginController.text.trim()) ?? 0.5,
                  },
                );
                _fetchServices();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create service: $e')),
                );
              }
            },
            child: const Text('Create'),
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
        title: const Text('Create New Pricing Version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'New Buyer Unit Price (₹)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: marginCtrl,
              decoration: const InputDecoration(labelText: 'New Margin Value'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final dio = getIt<DioClient>();
                await dio.post(
                  ApiEndpoints.servicePricingHistory(serviceId).replaceAll('/pricing-history', '/pricing'),
                  data: {
                    'buyerUnitPrice': double.tryParse(priceCtrl.text.trim()) ?? 2.0,
                    'marginType': 'FIXED',
                    'marginValue': double.tryParse(marginCtrl.text.trim()) ?? 0.5,
                  },
                );
                _fetchServices();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update pricing: $e')),
                );
              }
            },
            child: const Text('Update Pricing'),
          ),
        ],
      ),
    );
  }
}
