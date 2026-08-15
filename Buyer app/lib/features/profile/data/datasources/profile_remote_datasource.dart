import '../../../../core/network/dio_client.dart';
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
    final response = await client.get('/buyer/profile');
    final data = Map<String, dynamic>.from(response.data['profile'] ?? response.data['user'] ?? response.data);
    return ProfileModel.fromJson(data);
  }

  @override
  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    final response = await client.put('/buyer/profile', data: data);
    final responseData = Map<String, dynamic>.from(response.data['profile'] ?? response.data['user'] ?? response.data);
    return ProfileModel.fromJson(responseData);
  }
}
