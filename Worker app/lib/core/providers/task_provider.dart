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
      _dashboardStats = await ApiService.getDashboard();
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
