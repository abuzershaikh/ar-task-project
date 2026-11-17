const fs = require('fs');
const path = require('path');

const dirPath = path.resolve(__dirname, '../Admin app/lib/features/workers/presentation/pages/worker_directory_screen.dart');
let dirContent = fs.readFileSync(dirPath, 'utf8');

const startMarker = '  void _confirmDeleteSelected(BuildContext context) {';
const endMarker = '  bool _isWorkerMatchingFilter(dynamic w, String filter) {';

const startIndex = dirContent.indexOf(startMarker);
const endIndex = dirContent.indexOf(endMarker);

if (startIndex === -1 || endIndex === -1) {
  console.error('Markers not found!');
  process.exit(1);
}

const replacement = `  void _confirmDeleteSelected(BuildContext context) {
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
  }

`;

const newDirContent = dirContent.substring(0, startIndex) + replacement + dirContent.substring(endIndex);
fs.writeFileSync(dirPath, newDirContent, 'utf8');
console.log('✅ Updated worker_directory_screen.dart successfully!');

