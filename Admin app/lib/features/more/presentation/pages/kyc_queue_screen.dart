import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/more_bloc.dart';

class KycQueueScreen extends StatefulWidget {
  const KycQueueScreen({super.key});

  @override
  State<KycQueueScreen> createState() => _KycQueueScreenState();
}

class _KycQueueScreenState extends State<KycQueueScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MoreBloc>().add(LoadKycQueueEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Management Queue'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocBuilder<MoreBloc, MoreState>(
        builder: (context, state) {
          if (state is MoreLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MoreError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<MoreBloc>().add(LoadKycQueueEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is KycQueueLoaded) {
            final items = state.items;
            if (items.isEmpty) {
              return const Center(child: Text('No pending KYC verifications in queue'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final kyc = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(kyc.workerName.isNotEmpty ? kyc.workerName.substring(0, 1).toUpperCase() : 'W'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kyc.workerName.isNotEmpty ? kyc.workerName : 'Worker ${kyc.workerId}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text('Worker ID: ${kyc.workerId}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                kyc.status,
                                style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Document: ${kyc.documentType}', style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                onPressed: () {
                                  context.read<MoreBloc>().add(VerifyKycEvent(kyc.id));
                                },
                                child: const Text('Approve & Verify'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
