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
      _availableTasks = await ApiService.getAvailableTasks();
    } catch (e) {
      _error = e.toString();
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
    } catch (e) {
      _error = e.toString();
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
        fetchAvailableTasks();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return false;
  }

  Future<bool> startTask(String taskId) async {
    try {
      final res = await ApiService.startTask(taskId);
      if (res['success'] == true || res['status'] == 'IN_PROGRESS' || res['status'] == 'in_progress') {
        fetchMyTasks(_selectedStage);
        return true;
      }
    } catch (e) {
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
        if (uploadRes['success'] == true && uploadRes['file'] != null) {
          final fileData = uploadRes['file'];
          fileId = fileData['id']?.toString() ?? fileData['fileId']?.toString();
          final rawPath = (fileData['filePath'] ?? fileData['path'] ?? '').toString();
          fileUrl = rawPath.startsWith('http')
              ? rawPath
              : '${ApiService.baseUrl.replaceAll('/api/v1', '')}$rawPath';
        }
      }

      final res = await ApiService.submitTaskProof(taskId, {
        'data': {
          'textProof': textProof,
        },
        'proofs': (fileId != null || fileUrl != null)
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
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return false;
  }
}
