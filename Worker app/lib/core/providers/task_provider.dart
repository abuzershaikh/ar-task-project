import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<dynamic> _availableTasks = [];
  List<dynamic> _myTasks = [];
  bool _isLoading = false;
  String _selectedStage = 'assigned';
  Map<String, dynamic> _dashboardStats = {};
  String? _error;
  final Map<String, List<dynamic>> _stageTasksCache = {};
  int _myTasksRequestId = 0;

  List<dynamic> get availableTasks => _availableTasks;
  List<dynamic> get myTasks => _myTasks;
  bool get isLoading => _isLoading;
  String get selectedStage => _selectedStage;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  String? get error => _error;

  DateTime _extractDate(dynamic item, {bool includeUpdated = false}) {
    if (item is! Map) return DateTime.fromMillisecondsSinceEpoch(0);
    final raw = includeUpdated
        ? (item['updatedAt'] ??
            item['updated_at'] ??
            item['submittedAt'] ??
            item['submitted_at'] ??
            item['completedAt'] ??
            item['completed_at'] ??
            item['acceptedAt'] ??
            item['accepted_at'] ??
            item['assignedAt'] ??
            item['assigned_at'] ??
            item['createdAt'] ??
            item['created_at'])
        : (item['createdAt'] ??
            item['created_at'] ??
            item['updatedAt'] ??
            item['updated_at']);
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return DateTime.tryParse(raw.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  int _compareTasksDesc(dynamic a, dynamic b, {bool includeUpdated = false}) {
    final dateA = _extractDate(a, includeUpdated: includeUpdated);
    final dateB = _extractDate(b, includeUpdated: includeUpdated);
    final comp = dateB.compareTo(dateA);
    if (comp != 0) return comp;
    final idA = (a is Map ? (a['id'] ?? '') : '').toString();
    final idB = (b is Map ? (b['id'] ?? '') : '').toString();
    return idB.compareTo(idA);
  }

  Future<void> fetchAvailableTasks({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final rawTasks = await ApiService.getAvailableTasks();
      // Ensure distinct campaigns: Each worker can only see 1 task per campaign/order/app/url
      final seenCampaigns = <String>{};
      final seenPackages = <String>{};
      final seenUrls = <String>{};
      final uniqueTasks = <dynamic>[];
      for (final t in rawTasks) {
        if (t is Map) {
          final cId = (t['campaignId'] ?? t['orderId'] ?? t['id'] ?? '').toString();
          final reqs = t['requirements'] is Map ? t['requirements'] as Map : {};
          final meta = t['metadata'] is Map ? t['metadata'] as Map : {};
          final pkg = (reqs['packageId'] ?? meta['packageId'] ?? '').toString().trim().toLowerCase();
          String rawUrl = (reqs['targetUrl'] ?? meta['targetUrl'] ?? '').toString().trim().toLowerCase();
          String normUrl = '';
          if (rawUrl.isNotEmpty) {
            try {
              final uri = Uri.parse(rawUrl);
              normUrl = '${uri.scheme}://${uri.host}${uri.path}'.replaceAll(RegExp(r'/+$'), '');
            } catch (_) {
              normUrl = rawUrl.replaceAll(RegExp(r'/+$'), '');
            }
          }

          if (seenCampaigns.contains(cId)) continue;
          if (pkg.isNotEmpty && seenPackages.contains(pkg)) continue;
          if (normUrl.isNotEmpty && seenUrls.contains(normUrl)) continue;

          seenCampaigns.add(cId);
          if (pkg.isNotEmpty) seenPackages.add(pkg);
          if (normUrl.isNotEmpty) seenUrls.add(normUrl);
          uniqueTasks.add(t);
        } else {
          uniqueTasks.add(t);
        }
      }
      // Guarantee latest tasks are strictly at the top
      uniqueTasks.sort((a, b) => _compareTasksDesc(a, b, includeUpdated: false));
      _availableTasks = uniqueTasks;
      _error = null;
      debugPrint('[TaskProvider] Fetched ${_availableTasks.length} distinct available tasks successfully (newest top)');
    } catch (e) {
      debugPrint('[TaskProvider ERROR] fetchAvailableTasks failed: $e');
      if (!silent) {
        _error = e.toString().replaceAll('Exception: ', '');
        _availableTasks = [];
      }
    }
    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> fetchMyTasks(String stage, {bool forceRefresh = false}) async {
    _selectedStage = stage;
    final hasCached = _stageTasksCache.containsKey(stage);

    if (hasCached && !forceRefresh) {
      _myTasks = List<dynamic>.from(_stageTasksCache[stage]!);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } else {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    final currentReqId = ++_myTasksRequestId;

    try {
      final fetched = await ApiService.getMyTasks(stage);
      // Guarantee latest tasks are strictly at the top
      fetched.sort((a, b) => _compareTasksDesc(a, b, includeUpdated: true));

      // Guard against race condition: if user changed tab while request was ongoing, discard!
      if (currentReqId != _myTasksRequestId) {
        debugPrint('[TaskProvider] Discarding outdated fetchMyTasks for $stage (Req: $currentReqId vs $_myTasksRequestId)');
        return;
      }

      _stageTasksCache[stage] = fetched;
      _myTasks = fetched;
      _error = null;
      debugPrint('[TaskProvider] Fetched ${_myTasks.length} my tasks ($stage, newest top)');
    } catch (e) {
      debugPrint('[TaskProvider ERROR] fetchMyTasks failed: $e');
      if (currentReqId == _myTasksRequestId) {
        _error = e.toString().replaceAll('Exception: ', '');
        if (!hasCached) {
          _myTasks = [];
        }
      }
    } finally {
      if (currentReqId == _myTasksRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchDashboardStats() async {
    try {
      final res = await ApiService.getDashboard();
      if (res['success'] == true && res.containsKey('dashboard')) {
        _dashboardStats = res['dashboard'];
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Map<String, dynamic> _walletData = {};
  Map<String, dynamic> get walletData => _walletData;

  Future<void> fetchWalletData() async {
    try {
      final res = await ApiService.getWallet();
      if (res['success'] == true && res.containsKey('wallet')) {
        _walletData = res['wallet'];
      } else if (res['success'] == true && res.containsKey('earnings')) {
        _walletData = {'balance': 0.0, 'earnings': res['earnings']};
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> acceptTask(String taskId, {Map<String, dynamic>? taskData}) async {
    try {
      final res = await ApiService.acceptTask(taskId);
      if (res['success'] == true ||
          res['status'] == 'assigned' ||
          res['status'] == 'ASSIGNED' ||
          res['status'] == 'accepted' ||
          res['status'] == 'ACCEPTED') {
        _stageTasksCache.clear();

        final acceptedTaskId = taskId.trim();
        final campaignId = (taskData?['campaignId'] ??
                taskData?['campaign_id'] ??
                '')
            .toString()
            .trim();
        final orderId = (taskData?['orderId'] ??
                taskData?['order_id'] ??
                '')
            .toString()
            .trim();
        final orderUnitId = (taskData?['orderUnitId'] ??
                taskData?['order_unit_id'] ??
                '')
            .toString()
            .trim();

        _availableTasks.removeWhere((t) {
          final id = (t['id'] ?? '').toString().trim();
          final taskCampaign =
              (t['campaignId'] ?? t['campaign_id'] ?? '').toString().trim();
          final taskOrder =
              (t['orderId'] ?? t['order_id'] ?? '').toString().trim();
          final taskUnit =
              (t['orderUnitId'] ?? t['order_unit_id'] ?? '').toString().trim();

          return id == acceptedTaskId ||
              (campaignId.isNotEmpty && taskCampaign == campaignId) ||
              (orderId.isNotEmpty && taskOrder == orderId) ||
              (orderUnitId.isNotEmpty && taskUnit == orderUnitId);
        });
        notifyListeners();

        await fetchAvailableTasks();
        await fetchMyTasks('assigned', forceRefresh: true);
        return true;
      } else {
        _error = res['message']?.toString() ?? 'Failed to accept task';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[TaskProvider ERROR] acceptTask: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> startTask(String taskId) async {
    try {
      final res = await ApiService.startTask(taskId);
      if (res['success'] == true || res['status'] == 'IN_PROGRESS' || res['status'] == 'in_progress') {
        _stageTasksCache.clear();
        await fetchMyTasks('assigned', forceRefresh: true);
        return true;
      }
    } catch (e) {
      debugPrint('[TaskProvider ERROR] startTask: $e');
      _error = e.toString();
      notifyListeners();
    }
    return false;
  }

  Future<bool> submitTaskProof(String taskId, String textProof, String? imagePath) async {
    try {
      String? fileId;
      String? fileUrl;

      if (imagePath != null && imagePath.isNotEmpty) {
        final uploadRes = await ApiService.uploadFile(imagePath);
        if (uploadRes['success'] == true || uploadRes['url'] != null) {
          final fileData = uploadRes['file'] ?? {};
          fileId = fileData['id']?.toString() ?? uploadRes['fileId']?.toString() ?? 'proof-1';
          fileUrl = (uploadRes['url'] ?? fileData['url'] ?? '').toString();
          if (fileUrl.isEmpty) {
            final rawPath = (fileData['filePath'] ?? fileData['path'] ?? '').toString();
            if (rawPath.isNotEmpty) {
              fileUrl = rawPath.startsWith('http')
                  ? rawPath
                  : '${ApiService.baseUrl.replaceAll('/api/v1', '')}/${rawPath.replaceFirst(RegExp(r'^/+'), '')}';
            }
          }
        } else {
          throw Exception(uploadRes['message'] ?? 'Image upload failed');
        }
      }

      final res = await ApiService.submitTaskProof(taskId, {
        'data': {
          'textProof': textProof,
          'proofUrl': fileUrl ?? '',
          'screenshotUrl': fileUrl ?? '',
        },
        'proofs': (fileId != null || (fileUrl != null && fileUrl.isNotEmpty))
            ? [
                {
                  'fileId': fileId ?? 'proof-1',
                  'url': fileUrl ?? '',
                }
              ]
            : [],
      });

      if (res['success'] == true || res['status'] == 'SUBMITTED' || res['status'] == 'submitted') {
        _stageTasksCache.clear();
        fetchMyTasks(_selectedStage, forceRefresh: true);
        return true;
      } else {
        throw Exception(res['message'] ?? 'Failed to submit task proof');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
