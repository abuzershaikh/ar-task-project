import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/di/injection.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> updateProfile(Map<String, dynamic> data);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient client;

  ProfileRemoteDataSourceImpl(this.client);

  @override
  Future<ProfileModel> getProfile() async {
    try {
      final response = await client.get('/buyer/profile');
      final dynamic raw = response.data;
      Map<String, dynamic> data;

      if (raw is Map<String, dynamic>) {
        if (raw['profile'] is Map<String, dynamic>) {
          data = raw['profile'];
        } else if (raw['buyer'] is Map<String, dynamic>) {
          data = raw['buyer'];
        } else if (raw['user'] is Map<String, dynamic>) {
          data = raw['user'];
        } else if (raw['data'] is Map<String, dynamic>) {
          data = raw['data'];
        } else {
          data = raw;
        }
      } else {
        data = {};
      }

      final profile = ProfileModel.fromJson(data);

      // Cache basics locally
      _cacheLocally(profile);

      return profile;
    } catch (e) {
      // Return cached fallback if network error
      return _loadFallbackProfile();
    }
  }

  @override
  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    Response? response;
    try {
      response = await client.put('/buyer/profile', data: data);
    } catch (_) {
      // Fallback to PATCH if PUT not accepted
      response = await client.patch('/buyer/profile', data: data);
    }

    final dynamic raw = response.data;
    Map<String, dynamic> responseData;

    if (raw is Map<String, dynamic>) {
      if (raw['profile'] is Map<String, dynamic>) {
        responseData = raw['profile'];
      } else if (raw['buyer'] is Map<String, dynamic>) {
        responseData = raw['buyer'];
      } else if (raw['user'] is Map<String, dynamic>) {
        responseData = raw['user'];
      } else if (raw['data'] is Map<String, dynamic>) {
        responseData = raw['data'];
      } else {
        responseData = raw;
      }
    } else {
      responseData = data;
    }

    final updated = ProfileModel.fromJson(responseData);
    _cacheLocally(updated);
    return updated;
  }

  Future<void> _cacheLocally(ProfileModel profile) async {
    try {
      final secureStorage = getIt<SecureStorageService>();
      final localStorage = getIt<LocalStorageService>();
      if (profile.name.isNotEmpty) {
        await secureStorage.saveUserName(profile.name);
        await localStorage.saveUserName(profile.name);
      }
      if (profile.email.isNotEmpty) {
        await secureStorage.saveUserEmail(profile.email);
        await localStorage.saveUserEmail(profile.email);
      }
      if (profile.avatarUrl.isNotEmpty) {
        await secureStorage.saveUserPhoto(profile.avatarUrl);
        await localStorage.saveUserPhoto(profile.avatarUrl);
      }
    } catch (_) {}
  }

  Future<ProfileModel> _loadFallbackProfile() async {
    try {
      final secureStorage = getIt<SecureStorageService>();
      final localStorage = getIt<LocalStorageService>();
      final name = await secureStorage.getUserName() ?? localStorage.getUserName() ?? 'Buyer Account';
      final email = await secureStorage.getUserEmail() ?? localStorage.getUserEmail() ?? 'buyer@taskpost.com';
      final photo = await secureStorage.getUserPhoto() ?? localStorage.getUserPhoto() ?? '';
      final id = await secureStorage.getUserId() ?? '';

      return ProfileModel(
        id: id,
        email: email,
        name: name,
        phone: '',
        companyName: '',
        website: '',
        bio: '',
        avatarUrl: photo,
        billingAddress: '',
        industry: 'Technology & E-Commerce',
      );
    } catch (_) {
      return ProfileModel(
        id: '',
        email: 'buyer@taskpost.com',
        name: 'Buyer Account',
        phone: '',
        companyName: '',
        website: '',
        bio: '',
        avatarUrl: '',
        billingAddress: '',
      );
    }
  }
}
