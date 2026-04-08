import '../core/network/api_client.dart';
import '../models/paged_result.dart';
import '../models/recruit_plan.dart';

class PlanRepository {
  PlanRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<RecruitPlan>> fetchActivePlans({int? labId}) async {
    final response = await _apiClient.get(
      '/api/recruit-plans/active',
      queryParameters: <String, dynamic>{'labId': labId},
    );

    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => RecruitPlan.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<PagedResult<RecruitPlan>> fetchPlanPage({
    int pageNum = 1,
    int pageSize = 10,
    int? labId,
    String? status,
    String? keyword,
  }) async {
    final response = await _apiClient.get(
      '/api/recruit-plans',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'labId': labId,
        'status': status,
        'keyword': keyword,
      },
    );

    return PagedResult<RecruitPlan>.fromJson(
      response as Map<String, dynamic>,
      RecruitPlan.fromJson,
    );
  }

  Future<void> createPlan({
    required int labId,
    required String title,
    required String startTime,
    required String endTime,
    required int quota,
    String? requirement,
    required String status,
  }) {
    return _apiClient.post(
      '/api/recruit-plans',
      data: <String, dynamic>{
        'labId': labId,
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
        'quota': quota,
        'requirement': requirement,
        'status': status,
      },
    );
  }

  Future<void> updatePlan({
    required int id,
    required int labId,
    required String title,
    required String startTime,
    required String endTime,
    required int quota,
    String? requirement,
    required String status,
  }) {
    return _apiClient.put(
      '/api/recruit-plans/$id',
      data: <String, dynamic>{
        'labId': labId,
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
        'quota': quota,
        'requirement': requirement,
        'status': status,
      },
    );
  }

  Future<void> deletePlan(int id) {
    return _apiClient.delete('/api/recruit-plans/$id');
  }
}
