import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic> _profileData = {};
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get profileData => _profileData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.getProfile();
      if (data['success'] == true && data['data'] != null) {
        _profileData = data['data'];
      } else {
        _profileData = data;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.updateProfile(updateData);
      if (data['success'] == true) {
        await fetchProfile();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
