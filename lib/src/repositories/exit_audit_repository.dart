import '../core/network/api_client.dart';
import '../features/exit_audit/exit_audit_models.dart';
import '../models/paged_result.dart';

class ExitAuditRepository {
  ExitAuditRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<ExitAuditApplicationRecord>> fetchApplications({
    int pageNum = 1,
    int pageSize = 8,
    int? labId,
    int? status,
    String? realName,
  }) async {
    final response = await _apiClient.get(
      '/api/lab-space/exit-application/list',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'labId': labId,
        'status': status,
        'realName': realName,
      },
    );
    return PagedResult<ExitAuditApplicationRecord>.fromJson(
      response as Map<String, dynamic>,
      ExitAuditApplicationRecord.fromJson,
    );
  }

  Future<void> auditApplication({
    required int id,
    required int status,
    String? auditRemark,
  }) {
    return _apiClient.post(
      '/api/lab-space/exit-application/audit',
      data: <String, dynamic>{
        'id': id,
        'status': status,
        'auditRemark': auditRemark,
      },
    );
  }
}
