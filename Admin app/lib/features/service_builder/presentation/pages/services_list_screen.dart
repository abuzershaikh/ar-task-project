import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<ServiceBuilderBloc>().add(LoadServicesEvent());
  }

  void _createNewServiceDirectly() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final defaultCode = 'SERVICE_$timestamp';
    final defaultName = 'New Custom Service #$timestamp';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceBuilderScreen(
          draftCode: defaultCode,
          draftName: defaultName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services & Pricing Catalog'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ServiceBuilderBloc>().add(LoadServicesEvent()),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0F172A),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create New Service', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _createNewServiceDirectly,
      ),
      body: BlocBuilder<ServiceBuilderBloc, ServiceBuilderState>(
        builder: (context, state) {
          if (state is ServiceBuilderLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          } else if (state is ServiceCatalogLoaded) {
            if (state.services.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.dashboard_customize_rounded, size: 64, color: Colors.white30),
                    const SizedBox(height: 16),
                    const Text('No services configured yet.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Open Drag & Drop Studio'),
                      onPressed: _createNewServiceDirectly,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.services.length,
              itemBuilder: (context, index) {
                final service = state.services[index];
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceBuilderScreen(serviceId: service.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  service.code,
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: service.isActive ? AppColors.success.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'V${service.currentVersion} • ${service.isActive ? "ACTIVE" : "INACTIVE"}',
                                  style: TextStyle(
                                    color: service.isActive ? AppColors.success : Colors.redAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            service.name,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.description,
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                          const Divider(color: Colors.white12, height: 24),

                          // Financial Pricing Summary Grid
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Buyer Price', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                  Text('₹${service.pricing.buyerPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Admin Margin', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                  Text('${service.pricing.adminMarginPercent.toStringAsFixed(0)}%',
                                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Worker Reward', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                  Text('₹${service.pricing.workerReward.toStringAsFixed(1)}',
                                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent,
                                  foregroundColor: Colors.black,
                                ),
                                icon: const Icon(Icons.drag_indicator_rounded, size: 16),
                                label: const Text('Template Studio', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    ),
                  ),
                );
              },
            );
          } else if (state is ServiceBuilderError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
