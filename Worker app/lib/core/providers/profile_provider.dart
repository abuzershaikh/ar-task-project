import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic> _profileData = {};
  Map<String, dynamic> _scoreData = {};
  Map<String, dynamic> _kycData = {};
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get profileData => _profileData;
  Map<String, dynamic> get scoreData => _scoreData;
  Map<String, dynamic> get kycData => _kycData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get kycStatus {
    final status = _kycData['status'] ?? _profileData['kycStatus'] ?? 'DRAFT';
    return status.toString().toUpperCase();
  }

  bool get isKycVerified => kycStatus == 'VERIFIED';
  bool get isKycSubmitted => kycStatus == 'SUBMITTED' || kycStatus == 'UNDER_REVIEW' || kycStatus == 'VERIFIED';

  Map<String, dynamic> get bankDetails {
    if (_profileData['bankDetails'] is Map && (_profileData['bankDetails'] as Map).isNotEmpty) {
      return Map<String, dynamic>.from(_profileData['bankDetails']);
    }
    if (_kycData.isNotEmpty) {
      return _kycData;
    }
    if (_profileData['kyc'] is Map && (_profileData['kyc'] as Map).isNotEmpty) {
      return Map<String, dynamic>.from(_profileData['kyc']);
    }
    return {};
  }

  bool get hasPayoutDetails {
    final bd = bankDetails;
    final upi = bd['upiId']?.toString().trim() ?? '';
    final acc = bd['accountNumber']?.toString().trim() ?? '';
    final paypal = bd['paypalId']?.toString().trim() ?? '';
    return upi.isNotEmpty || acc.isNotEmpty || paypal.isNotEmpty;
  }

  double get liveQualityScore {
    // 1. Check _scoreData from /worker/score
    final scoreObj = _scoreData['score'];
    if (scoreObj is Map) {
      final val = scoreObj['overallScore'] ?? scoreObj['totalScore'];
      if (val != null) {
        final parsed = double.tryParse(val.toString());
        if (parsed != null) return parsed;
      }
    }
    // 2. Check _profileData['score'] from /worker/profile
    final profileScore = _profileData['score'];
    if (profileScore is Map) {
      final val = profileScore['totalScore'] ?? profileScore['overallScore'];
      if (val != null) {
        final parsed = double.tryParse(val.toString());
        if (parsed != null) return parsed;
      }
    }
    // 3. Check if new worker with 0 completed and 0 rejected
    final completed = int.tryParse(_profileData['totalTasksCompleted']?.toString() ?? '') ?? 0;
    final rejected = int.tryParse(_profileData['totalTasksRejected']?.toString() ?? '') ?? 0;
    if (completed == 0 && rejected == 0) {
      return 60.0; // Official starter score for new workers
    }
    return 0.0;
  }

  double get liveRating {
    final ratingVal = _profileData['averageRating'];
    if (ratingVal != null) {
      final parsed = double.tryParse(ratingVal.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    final scoreObj = _scoreData['score'];
    if (scoreObj is Map && scoreObj['breakdown'] is Map) {
      final bRating = scoreObj['breakdown']['rating'];
      if (bRating != null) {
        final parsed = double.tryParse(bRating.toString());
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return 0.0;
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getScore().catchError((_) => <String, dynamic>{}),
        ApiService.getKycStatus().catchError((_) => <String, dynamic>{}),
      ]);
      final profileRes = results[0];
      final scoreRes = results[1];
      final kycRes = results[2];

      if (profileRes['success'] == true && profileRes['worker'] != null) {
        _profileData = Map<String, dynamic>.from(profileRes['worker']);
      } else if (profileRes['success'] == true && profileRes['data'] != null) {
        _profileData = Map<String, dynamic>.from(profileRes['data']);
      } else if (profileRes.isNotEmpty) {
        _profileData = Map<String, dynamic>.from(profileRes);
      }

      if (scoreRes['success'] == true && scoreRes['score'] != null) {
        _scoreData = Map<String, dynamic>.from(scoreRes);
        _profileData['score'] = scoreRes['score'];
      }

      if (kycRes['success'] == true && kycRes['kyc'] is Map) {
        _kycData = Map<String, dynamic>.from(kycRes['kyc']);
      } else if (_profileData['kyc'] is Map) {
        _kycData = Map<String, dynamic>.from(_profileData['kyc']);
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
