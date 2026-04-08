import '../core/network/api_client.dart';
import '../features/exit_application/exit_application_models.dart';
import '../models/paged_result.dart';

class LabExitApplicationRepository {
  LabExitApplicationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<LabExitApplicationRecord>> fetchMyApplications({
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.get(
      '/api/lab-space/exit-application/my',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );
    return PagedResult<LabExitApplicationRecord>.fromJson(
      response as Map<String, dynamic>,
      LabExitApplicationRecord.fromJson,
    );
  }

  Future<void> submitExitApplication({required String reason}) {
    return _apiClient.post(
      '/api/lab-space/exit-application',
      data: <String, dynamic>{'reason': reason.trim()},
    );
  }
}
