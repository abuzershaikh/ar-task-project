import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<dynamic> _availableTasks = [];
  List<dynamic> _myTasks = [];
  bool _isLoading = false;
  String _selectedStage = 'submitted';
  Map<String, dynamic> _dashboardStats = {};

  List<dynamic> get availableTasks => _availableTasks;
  List<dynamic> get myTasks => _myTasks;
  bool get isLoading => _isLoading;
  String get selectedStage => _selectedStage;
  Map<String, dynamic> get dashboardStats => _dashboardStats;

  Future<void> fetchAvailableTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _availableTasks = await ApiService.getAvailableTasks();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyTasks(String stage) async {
    _selectedStage = stage;
    _isLoading = true;
    notifyListeners();
    try {
      _myTasks = await ApiService.getMyTasks(stage);
    } catch (_) {}
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
    } catch (_) {}
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
    } catch (_) {}
  }

  Future<bool> acceptTask(String taskId) async {
    try {
      final res = await ApiService.acceptTask(taskId);
      if (res['success'] == true || res['status'] == 'assigned' || res['status'] == 'ASSIGNED') {
        fetchAvailableTasks();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> startTask(String taskId) async {
    try {
      final res = await ApiService.startTask(taskId);
      if (res['success'] == true || res['status'] == 'IN_PROGRESS' || res['status'] == 'in_progress') {
        fetchMyTasks(_selectedStage);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> submitTaskProof(String taskId, String textProof, String? imageUrl) async {
    try {
      final res = await ApiService.submitTaskProof(taskId, {
        'textProof': textProof,
        'imageUrl': imageUrl,
      });
      if (res['success'] == true || res['status'] == 'SUBMITTED' || res['status'] == 'submitted') {
        fetchMyTasks('submitted');
        return true;
      }
    } catch (_) {}
    return false;
  }
}
