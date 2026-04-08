import '../core/network/api_client.dart';
import '../features/teacher_register_audit/teacher_register_audit_models.dart';
import '../models/paged_result.dart';

class TeacherRegisterAuditRepository {
  TeacherRegisterAuditRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<TeacherRegisterAuditRecord>> fetchApplications({
    int pageNum = 1,
    int pageSize = 10,
    String? status,
    String? keyword,
  }) async {
    final response = await _apiClient.get(
      '/api/teacher-register-applies',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'status': status,
        'keyword': keyword,
      },
    );
    return PagedResult<TeacherRegisterAuditRecord>.fromJson(
      response as Map<String, dynamic>,
      TeacherRegisterAuditRecord.fromJson,
    );
  }

  Future<void> auditApplication({
    required int id,
    required String action,
    String? auditComment,
  }) {
    return _apiClient.post(
      '/api/teacher-register-applies/$id/audit',
      data: <String, dynamic>{'action': action, 'auditComment': auditComment},
    );
  }
}
