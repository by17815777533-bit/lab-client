import '../core/network/api_client.dart';
import '../models/user_session.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      data: <String, dynamic>{'username': username, 'password': password},
    );

    return UserSession.fromJson(response as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _apiClient.post('/api/user/logout');
  }
}
