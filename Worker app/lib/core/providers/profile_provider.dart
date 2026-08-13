import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic> _profileData = {};
  bool _isLoading = false;

  Map<String, dynamic> get profileData => _profileData;
  bool get isLoading => _isLoading;

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
    } catch (_) {}
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
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
