import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<dynamic> _availableTasks = [];
  List<dynamic> _myTasks = [];
  bool _isLoading = false;
  String _selectedStage = 'submitted';
  Map<String, dynamic> _dashboardStats = {};
  String? _error;

  List<dynamic> get availableTasks => _availableTasks;
  List<dynamic> get myTasks => _myTasks;
  bool get isLoading => _isLoading;
  String get selectedStage => _selectedStage;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  String? get error => _error;

  Future<void> fetchAvailableTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final rawTasks = await ApiService.getAvailableTasks();
      // Ensure distinct campaigns: Each worker can only see 1 task per campaign/order
      final seenCampaigns = <String>{};
      final uniqueTasks = <dynamic>[];
      for (final t in rawTasks) {
        if (t is Map) {
          final cId = (t['campaignId'] ?? t['orderId'] ?? t['id']).toString();
          if (!seenCampaigns.contains(cId)) {
            seenCampaigns.add(cId);
            uniqueTasks.add(t);
          }
        } else {
          uniqueTasks.add(t);
        }
      }
      _availableTasks = uniqueTasks;
      debugPrint('[TaskProvider] Fetched ${_availableTasks.length} distinct available tasks successfully');
    } catch (e) {
      debugPrint('[TaskProvider ERROR] fetchAvailableTasks failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _availableTasks = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyTasks(String stage) async {
    _selectedStage = stage;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _myTasks = await ApiService.getMyTasks(stage);
      debugPrint('[TaskProvider] Fetched ${_myTasks.length} my tasks ($stage)');
    } catch (e) {
      debugPrint('[TaskProvider ERROR] fetchMyTasks failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _myTasks = [];
    }
    _isLoading = false;
    notifyListeners();
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

  Future<bool> acceptTask(String taskId) async {
    try {
      final res = await ApiService.acceptTask(taskId);
      if (res['success'] == true || res['status'] == 'assigned' || res['status'] == 'ASSIGNED') {
        await fetchAvailableTasks();
        await fetchMyTasks('assigned');
        return true;
      }
    } catch (e) {
      debugPrint('[TaskProvider ERROR] acceptTask: $e');
      _error = e.toString();
      notifyListeners();
    }
    return false;
  }

  Future<bool> startTask(String taskId) async {
    try {
      final res = await ApiService.startTask(taskId);
      if (res['success'] == true || res['status'] == 'IN_PROGRESS' || res['status'] == 'in_progress') {
        await fetchMyTasks('assigned');
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
        fetchMyTasks(_selectedStage);
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
