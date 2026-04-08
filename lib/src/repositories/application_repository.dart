import '../core/network/api_client.dart';
import '../models/lab_application.dart';
import '../models/paged_result.dart';

class ApplicationRepository {
  ApplicationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<LabApplication>> fetchMyApplications({
    int pageNum = 1,
    int pageSize = 10,
    String? status,
  }) async {
    final response = await _apiClient.get(
      '/api/lab-applies/my',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'status': status,
      },
    );

    return PagedResult<LabApplication>.fromJson(
      response as Map<String, dynamic>,
      LabApplication.fromJson,
    );
  }

  Future<void> createApplication({
    required int labId,
    required int recruitPlanId,
    required String applyReason,
    String? researchInterest,
    String? skillSummary,
  }) {
    return _apiClient.post(
      '/api/lab-applies',
      data: <String, dynamic>{
        'labId': labId,
        'recruitPlanId': recruitPlanId,
        'applyReason': applyReason,
        'researchInterest': researchInterest,
        'skillSummary': skillSummary,
      },
    );
  }
}
