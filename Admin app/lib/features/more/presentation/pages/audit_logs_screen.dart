import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = getIt<DioClient>();
      final resp = await dio.get(
        ApiEndpoints.auditLogs,
        queryParameters: {'limit': 100, 'page': 1},
      );

      final data = resp.data;
      List<dynamic> rawItems = [];
      if (data is Map<String, dynamic>) {
        rawItems = data['items'] ?? data['logs'] ?? [];
      } else if (data is List) {
        rawItems = data;
      }

      final parsed = rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList();

      setState(() {
        _logs = parsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  String _categorizeAction(String action, String entityType) {
    final act = action.toUpperCase();
    final ent = entityType.toUpperCase();

    if (act.contains('CAMPAIGN') || act.contains('ORDER') || ent.contains('ORDER')) {
      return 'Campaigns';
    }
    if (act.contains('SETTING') || ent.contains('SETTING')) {
      return 'Settings';
    }
    if (act.contains('WORKER') || ent.contains('WORKER')) {
      return 'Workers';
    }
    if (act.contains('BUYER') || ent.contains('BUYER')) {
      return 'Buyers';
    }
    if (act.contains('PAYOUT') || act.contains('WALLET') || act.contains('FINANCIAL')) {
      return 'Financial';
    }
    if (act.contains('REVIEW') || act.contains('KYC') || act.contains('TASK')) {
      return 'Reviews & KYC';
    }
    return 'System';
  }

  IconData _getActionIcon(String action) {
    final act = action.toUpperCase();
    if (act.contains('PAUSE')) return Icons.pause_circle_filled_rounded;
    if (act.contains('RESUME')) return Icons.play_circle_filled_rounded;
    if (act.contains('CANCEL')) return Icons.cancel_rounded;
    if (act.contains('SETTING')) return Icons.tune_rounded;
    if (act.contains('APPROVE') || act.contains('VERIF')) return Icons.check_circle_rounded;
    if (act.contains('REJECT') || act.contains('BAN') || act.contains('SUSPEND')) return Icons.block_rounded;
    if (act.contains('WALLET') || act.contains('PAYOUT')) return Icons.account_balance_wallet_rounded;
    return Icons.history_rounded;
  }

  Color _getActionColor(String action) {
    final act = action.toUpperCase();
    if (act.contains('CANCEL') || act.contains('BAN') || act.contains('REJECT') || act.contains('DELETE')) {
      return const Color(0xFFDC2626);
    }
    if (act.contains('PAUSE') || act.contains('SUSPEND') || act.contains('WARN')) {
      return const Color(0xFFD97706);
    }
    if (act.contains('RESUME') || act.contains('APPROVE') || act.contains('VERIF') || act.contains('ACTIVE')) {
      return const Color(0xFF059669);
    }
    if (act.contains('SETTING') || act.contains('UPDATE')) {
      return const Color(0xFF0284C7);
    }
    return const Color(0xFF6366F1);
  }

  String _formatActionTitle(String action) {
    return action.replaceAll('_', ' ').toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _buildDescription(Map<String, dynamic> log) {
    final meta = log['metadata'];
    final newState = log['newState'];
    final entityType = log['entityType'] ?? '';
    final entityId = log['entityId'] ?? '';

    if (meta is Map && meta['reason'] != null && meta['reason'].toString().isNotEmpty) {
      return 'Reason: ${meta['reason']} (${entityType}: $entityId)';
    }

    if (newState != null) {
      if (newState is Map) {
        final entries = newState.entries.take(3).map((e) => '${e.key}: ${e.value}').join(', ');
        return 'Updated $entityType ($entityId) → $entries';
      }
      return 'Updated $entityType ($entityId) to $newState';
    }

    if (entityId.toString().isNotEmpty) {
      return 'Target $entityType: $entityId';
    }

    return 'Action logged on $entityType';
  }

  List<Map<String, dynamic>> _getFilteredLogs() {
    final q = _searchController.text.trim().toLowerCase();

    return _logs.where((log) {
      final action = (log['action'] ?? '').toString();
      final entityType = (log['entityType'] ?? '').toString();
      final entityId = (log['entityId'] ?? '').toString();
      final category = _categorizeAction(action, entityType);

      final matchesFilter = _selectedFilter == 'All' || category == _selectedFilter;

      final matchesQuery = q.isEmpty ||
          action.toLowerCase().contains(q) ||
          entityType.toLowerCase().contains(q) ||
          entityId.toLowerCase().contains(q) ||
          (log['actorId'] ?? '').toString().toLowerCase().contains(q);

      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'System Audit Logs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Logs',
            onPressed: _fetchAuditLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'Search by action, entity ID, or target...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF059669), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                          onPressed: () {
                            setState(() => _searchController.clear());
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Filter Pills
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  'Campaigns',
                  'Settings',
                  'Workers',
                  'Buyers',
                  'Financial',
                  'Reviews & KYC',
                ].map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF059669),
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Audit Log Stream
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 44),
                              const SizedBox(height: 10),
                              Text(
                                'Error loading audit logs: $_errorMessage',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _fetchAuditLogs,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredLogs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFECFDF5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified_outlined, size: 48, color: Color(0xFF059669)),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'No Audit Logs Found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF064E3B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Important administrator actions (like campaign pauses, cancels, setting updates, or status changes) will be safely recorded and tracked here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF059669),
                            onRefresh: _fetchAuditLogs,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                              itemCount: filteredLogs.length,
                              itemBuilder: (context, index) {
                                return _buildRealAuditLogItem(filteredLogs[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealAuditLogItem(Map<String, dynamic> log) {
    final action = (log['action'] ?? 'UNKNOWN_ACTION').toString();
    final entityType = (log['entityType'] ?? '').toString();
    final actorRole = (log['actorRole'] ?? 'ADMIN').toString();
    final color = _getActionColor(action);
    final icon = _getActionIcon(action);
    final category = _categorizeAction(action, entityType);
    final description = _buildDescription(log);
    final timeStr = _formatDateTime(log['createdAt']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showLogDetailsDialog(log),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _formatActionTitle(action),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 0.6),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_outlined, size: 13, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                          Text(
                            actorRole,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogDetailsDialog(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          _formatActionTitle((log['action'] ?? 'Audit Log Details').toString()),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Action', log['action']?.toString() ?? 'N/A'),
              _buildDetailRow('Entity Type', log['entityType']?.toString() ?? 'N/A'),
              _buildDetailRow('Entity ID', log['entityId']?.toString() ?? 'N/A'),
              _buildDetailRow('Actor Role', log['actorRole']?.toString() ?? 'ADMIN'),
              _buildDetailRow('Actor ID', log['actorId']?.toString() ?? 'N/A'),
              _buildDetailRow('Timestamp', log['createdAt']?.toString() ?? 'N/A'),
              if (log['metadata'] != null) ...[
                const SizedBox(height: 8),
                const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log['metadata'].toString(),
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
              if (log['newState'] != null) ...[
                const SizedBox(height: 8),
                const Text('New State:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log['newState'].toString(),
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }
}
