import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/buyers_bloc.dart';
import '../../../../core/theme/app_colors.dart';

class BuyersScreen extends StatefulWidget {
  const BuyersScreen({super.key});

  @override
  State<BuyersScreen> createState() => _BuyersScreenState();
}

class _BuyersScreenState extends State<BuyersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BuyersBloc>().add(LoadBuyersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<BuyersBloc, BuyersState>(
        builder: (context, state) {
          if (state is BuyersLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BuyersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: () {
                      context.read<BuyersBloc>().add(LoadBuyersEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is BuyersLoaded) {
            final buyers = state.buyers;
            if (buyers.isEmpty) {
              return const Center(child: Text('No buyers found.'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BuyersBloc>().add(RefreshBuyersEvent());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: buyers.length,
                itemBuilder: (context, index) {
                  final buyer = buyers[index];
                  return _BuyerCard(
                    buyerId: buyer.id,
                    companyName: buyer.name,
                    balance: buyer.totalSpend.toInt(), // using totalSpend as proxy for now
                    activeOrders: buyer.activeCampaigns,
                    totalOrders: buyer.totalOrders,
                    apiEnabled: false, // Update if API enabled is added to model
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feature coming soon')),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const Center(child: Text('No data'));
        },
      ),
    );
  }
}

class _BuyerCard extends StatelessWidget {
  final String buyerId;
  final String companyName;
  final int balance;
  final int activeOrders;
  final int totalOrders;
  final bool apiEnabled;
  final VoidCallback onTap;

  const _BuyerCard({
    required this.buyerId,
    required this.companyName,
    required this.balance,
    required this.activeOrders,
    required this.totalOrders,
    required this.apiEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: AppColors.info,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                companyName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (apiEnabled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.api,
                                      size: 12,
                                      color: AppColors.secondary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'API',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          buyerId,
                          style: const TextStyle(
                            color: AppColors.gray500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withAlpha(51)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, 
                      color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray600,
                          ),
                        ),
                        Text(
                          '₹${balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Active Orders',
                      value: activeOrders.toString(),
                      color: AppColors.info,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.history,
                      label: 'Total Orders',
                      value: totalOrders.toString(),
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.gray500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
