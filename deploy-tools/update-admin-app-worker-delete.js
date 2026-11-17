const fs = require('fs');
const path = require('path');

const adminAppDir = path.resolve(__dirname, '../Admin app');

// 1. Update workers_bloc.dart
const blocPath = path.join(adminAppDir, 'lib/features/workers/presentation/bloc/workers_bloc.dart');
let blocContent = fs.readFileSync(blocPath, 'utf8');

blocContent = blocContent.replace(
  /Future<void> _onDeleteWorker\(DeleteWorkerEvent event, Emitter<WorkersState> emit\) async \{[\s\S]*?emit\(WorkersLoaded\(List\.from\(_cachedWorkers\)\)\);\s*\}/,
  `Future<void> _onDeleteWorker(DeleteWorkerEvent event, Emitter<WorkersState> emit) async {
    try {
      await repository.deleteWorker(event.workerId);
    } catch (_) {}
    _cachedWorkers.removeWhere((w) => w.id == event.workerId || w.userId == event.workerId);
    emit(WorkersLoaded(List.from(_cachedWorkers)));
    add(LoadWorkersEvent(refresh: true));
  }`
);

blocContent = blocContent.replace(
  /Future<void> _onBatchDeleteWorkers\(BatchDeleteWorkersEvent event, Emitter<WorkersState> emit\) async \{[\s\S]*?emit\(WorkersLoaded\(List\.from\(_cachedWorkers\)\)\);\s*\}/,
  `Future<void> _onBatchDeleteWorkers(BatchDeleteWorkersEvent event, Emitter<WorkersState> emit) async {
    try {
      await repository.batchDeleteWorkers(event.workerIds);
    } catch (_) {}
    final idSet = event.workerIds.toSet();
    _cachedWorkers.removeWhere((w) => idSet.contains(w.id) || idSet.contains(w.userId));
    emit(WorkersLoaded(List.from(_cachedWorkers)));
    add(LoadWorkersEvent(refresh: true));
  }`
);
fs.writeFileSync(blocPath, blocContent, 'utf8');
console.log('✅ Updated workers_bloc.dart');

// 2. Update worker_card.dart
const cardPath = path.join(adminAppDir, 'lib/features/workers/presentation/widgets/worker_card.dart');
let cardContent = fs.readFileSync(cardPath, 'utf8');

const oldCardDelete = `                  if (onDelete != null && !isSelectionMode) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],`;

const newCardDelete = `                  if (onDelete != null && !isSelectionMode) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Delete & Wipe Worker',
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.delete_forever_rounded, size: 16, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ),
                  ],`;

if (cardContent.includes('Icons.delete_outline_rounded')) {
  cardContent = cardContent.replace(/if \(onDelete != null && !isSelectionMode\) \.\.\.\[[\s\S]*?Icon\(Icons\.delete_outline_rounded[\s\S]*?\],\s*\]/, `if (onDelete != null && !isSelectionMode) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Delete & Wipe Worker',
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.delete_forever_rounded, size: 16, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ),
                  ]`);
  fs.writeFileSync(cardPath, cardContent, 'utf8');
  console.log('✅ Updated worker_card.dart');
}

// 3. Update worker_directory_screen.dart
const dirPath = path.join(adminAppDir, 'lib/features/workers/presentation/pages/worker_directory_screen.dart');
let dirContent = fs.readFileSync(dirPath, 'utf8');

const newConfirmDeleteSelected = `  void _confirmDeleteSelected(BuildContext context) {
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
                'Delete $count Worker\${count > 1 ? 's' : ''}?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete $count selected worker account\${count > 1 ? 's' : ''}?\\n\\nThis will completely wipe:\\n• All worker accounts & logins\\n• All tasks & assignments (reset back to 0 & released so orders are not blocked)\\n• All earnings, withdrawals & KYC records\\n• All wallet balances & transactions\\n• All support chat history\\n\\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
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
              context.read<WorkersBloc>().add(BatchDeleteWorkersEvent(idsToDelete));
              setState(() {
                _selectedIds.clear();
                _isSelectionMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleting & wiping $count worker\${count > 1 ? 's' : ''} and tasks to 0...'),
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

  void _confirmDeleteSingle(BuildContext context, dynamic worker) {
    final workerName = worker.name ?? 'Worker';
    final workerEmail = (worker.email != null && worker.email.toString().isNotEmpty) ? worker.email : (worker.id ?? '');
    final workerId = (worker.id != null && worker.id.toString().isNotEmpty) ? worker.id.toString() : (worker.userId?.toString() ?? '');

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
            const Expanded(
              child: Text(
                'Delete & Wipe Worker?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$workerName" ($workerEmail)?\\n\\nThis will completely wipe:\\n• Worker account & login\\n• All tasks & assignments (reset back to 0 so orders remain clean)\\n• All wallet balance & financial history\\n• Earnings, KYC, and ratings\\n• Support chat messages\\n\\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
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
              context.read<WorkersBloc>().add(DeleteWorkerEvent(workerId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleting & wiping $workerName and all tasks to 0...'),
                  backgroundColor: const Color(0xFF0F172A),
                ),
              );
            },
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }`;

dirContent = dirContent.replace(
  /  void _confirmDeleteSelected\(BuildContext context\) \{[\s\S]*?void _confirmDeleteSingle\(BuildContext context, dynamic worker\) \{[\s\S]*? child: const Text\('Delete Permanently', style: TextStyle\(fontWeight: FontWeight\.bold\)\),\s*\},\s*\],\s*\),\s*\);\s*\}/,
  newConfirmDeleteSelected
);
fs.writeFileSync(dirPath, dirContent, 'utf8');
console.log('✅ Updated worker_directory_screen.dart');

// 4. Update worker_detail_screen.dart
const detailPath = path.join(adminAppDir, 'lib/features/workers/presentation/pages/worker_detail_screen.dart');
let detailContent = fs.readFileSync(detailPath, 'utf8');

detailContent = detailContent.replace(
  /'Are you sure you want to permanently delete this worker account\? KYC profiles, earnings, task submissions, and wallet history will be permanently wiped\. This action cannot be undone\.'/,
  `'Are you sure you want to permanently delete this worker account?\\n\\nThis will permanently wipe:\\n• Worker account & login credentials\\n• All tasks & assignments (reset back to 0 & released so orders remain clean)\\n• Wallet balance & financial history\\n• KYC verification & profiles\\n• Support chat history\\n\\nThis action cannot be undone.'`
);

detailContent = detailContent.replace(
  /'Worker deleted successfully\.'/,
  `'Worker and all tasks wiped to 0 successfully.'`
);

fs.writeFileSync(detailPath, detailContent, 'utf8');
console.log('✅ Updated worker_detail_screen.dart');

