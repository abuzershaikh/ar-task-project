import 'package:flutter/material.dart';

class TasksTab extends StatelessWidget {
  final String campaignId;

  const TasksTab({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Working'),
              Tab(text: 'Submitted'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: List.generate(
                6,
                (index) => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 10,
                  itemBuilder: (context, i) => _TaskItem(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Task #T-1024',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Under Review', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Worker: W-204', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('Submitted: 8 min ago', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}
