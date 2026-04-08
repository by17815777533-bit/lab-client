import '../core/network/api_client.dart';
import '../models/latest_lab_application.dart';
import '../features/lab_apply_audit/lab_apply_audit_models.dart';
import '../models/paged_result.dart';

class LabApplyAuditRepository {
  LabApplyAuditRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<LabApplyAuditRecord>> fetchApplications({
    int pageNum = 1,
    int pageSize = 10,
    int? labId,
    String? status,
    String? keyword,
  }) async {
    final response = await _apiClient.get(
      '/api/lab-applies',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'labId': labId,
        'status': status,
        'keyword': keyword,
      },
    );

    return PagedResult<LabApplyAuditRecord>.fromJson(
      response as Map<String, dynamic>,
      LabApplyAuditRecord.fromJson,
    );
  }

  Future<void> auditApplication({
    required int id,
    required String action,
    String? auditComment,
  }) {
    return _apiClient.post(
      '/api/lab-applies/$id/audit',
      data: <String, dynamic>{'action': action, 'auditComment': auditComment},
    );
  }

  Future<List<LatestLabApplication>> fetchLatestApplications({
    int limit = 5,
    int? labId,
  }) async {
    final response = await _apiClient.get(
      '/api/lab-applies/latest',
      queryParameters: <String, dynamic>{'limit': limit, 'labId': labId},
    );

    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (Map item) =>
              LatestLabApplication.fromJson(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }
}
