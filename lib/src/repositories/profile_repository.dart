import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserProfile> fetchProfile() async {
    final response = await _apiClient.get('/api/access/profile');
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    required String realName,
    required String email,
    String? major,
    String? resume,
  }) async {
    await _apiClient.put(
      '/api/user/info',
      data: <String, dynamic>{
        'realName': realName,
        'email': email,
        'major': major,
        'resume': resume,
      },
    );

    return fetchProfile();
  }

  Future<UserProfile> updateAvatar(String avatarPath) async {
    await _apiClient.put(
      '/api/user/avatar',
      data: <String, dynamic>{'avatar': avatarPath},
    );

    return fetchProfile();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _apiClient.put(
      '/api/user/password',
      data: <String, dynamic>{
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<String> uploadFile({
    required PlatformFile file,
    required String scene,
  }) async {
    final multipartFile = await _toMultipartFile(file);
    final response = await _apiClient.upload(
      '/api/file/upload',
      file: multipartFile,
      fields: <String, dynamic>{'scene': scene},
    );

    final map = response as Map<String, dynamic>;
    return map['url']?.toString() ?? map['path']?.toString() ?? '';
  }

  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    }

    if (file.path != null && file.path!.isNotEmpty) {
      return MultipartFile.fromFile(file.path!, filename: file.name);
    }

    throw ApiException('无法读取所选文件，请重新选择');
  }
}
