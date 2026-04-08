import '../core/network/api_client.dart';
import '../features/admin_management/admin_management_models.dart';

class AdminManagementRepository {
  AdminManagementRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<LabAdminAssignment>> fetchLabsWithAdmin() async {
    final response = await _apiClient.get('/api/labs/list-with-admin');
    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) => LabAdminAssignment.fromJson(item.cast<String, dynamic>()),
        )
        .toList();
  }

  Future<List<AdminManagerUser>> fetchStudentCandidates() async {
    final response = await _apiClient.get('/api/user/student/list');
    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => AdminManagerUser.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> assignAdminToLab({required int labId, required int userId}) {
    return _apiClient.post(
      '/api/admin-management/assign',
      data: <String, dynamic>{'labId': labId, 'userId': userId},
    );
  }

  Future<void> removeAdminFromLab(int labId) {
    return _apiClient.delete('/api/admin-management/remove/$labId');
  }

  Future<List<AdminManagerUser>> fetchAdminAccounts() async {
    final response = await _apiClient.get('/api/admin/list');
    if (response is List<dynamic>) {
      return response
          .whereType<Map>()
          .map(
            (item) => AdminManagerUser.fromJson(item.cast<String, dynamic>()),
          )
          .toList();
    }
    if (response is Map<String, dynamic>) {
      final records =
          response['records'] as List<dynamic>? ?? const <dynamic>[];
      return records
          .whereType<Map>()
          .map(
            (item) => AdminManagerUser.fromJson(item.cast<String, dynamic>()),
          )
          .toList();
    }
    if (response is Map) {
      final map = response.cast<String, dynamic>();
      final records = map['records'] as List<dynamic>? ?? const <dynamic>[];
      return records
          .whereType<Map>()
          .map(
            (item) => AdminManagerUser.fromJson(item.cast<String, dynamic>()),
          )
          .toList();
    }
    return <AdminManagerUser>[];
  }

  Future<void> addAdmin({
    required String username,
    required String password,
    required String realName,
    required String email,
    required String phone,
    required int labId,
  }) {
    return _apiClient.post(
      '/api/user/admin/add',
      data: <String, dynamic>{
        'username': username,
        'password': password,
        'realName': realName,
        'email': email,
        'phone': phone,
        'labId': labId,
      },
    );
  }

  Future<void> updateAdmin({
    required int id,
    String? password,
    required String realName,
    required String email,
    required String phone,
    required int labId,
  }) {
    return _apiClient.put(
      '/api/user/admin/$id',
      data: <String, dynamic>{
        'password': password,
        'realName': realName,
        'email': email,
        'phone': phone,
        'labId': labId,
      },
    );
  }

  Future<void> deleteAdmin(int id) {
    return _apiClient.delete('/api/user/admin/$id');
  }
}
