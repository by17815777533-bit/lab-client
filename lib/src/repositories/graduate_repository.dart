import '../core/network/api_client.dart';
import '../models/outstanding_graduate.dart';
import '../models/paged_result.dart';

class GraduateRepository {
  GraduateRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<OutstandingGraduate>> fetchGraduates({
    int pageNum = 1,
    int pageSize = 10,
    int? labId,
  }) async {
    final response = await _apiClient.get(
      '/api/graduate/list',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'labId': labId,
      },
    );

    return PagedResult<OutstandingGraduate>.fromJson(
      response as Map<String, dynamic>,
      OutstandingGraduate.fromJson,
    );
  }

  Future<void> addGraduate({
    required String name,
    required String major,
    required String graduationYear,
    String? company,
    String? position,
    String? description,
    String? avatarUrl,
  }) {
    return _apiClient.post(
      '/api/graduate/add',
      data: <String, dynamic>{
        'name': name,
        'major': major,
        'graduationYear': graduationYear,
        'company': company,
        'position': position,
        'description': description,
        'avatarUrl': avatarUrl,
      },
    );
  }

  Future<void> updateGraduate({
    required int id,
    int? labId,
    required String name,
    required String major,
    required String graduationYear,
    String? company,
    String? position,
    String? description,
    String? avatarUrl,
  }) {
    return _apiClient.put(
      '/api/graduate/update',
      data: <String, dynamic>{
        'id': id,
        'labId': labId,
        'name': name,
        'major': major,
        'graduationYear': graduationYear,
        'company': company,
        'position': position,
        'description': description,
        'avatarUrl': avatarUrl,
      },
    );
  }

  Future<void> deleteGraduate(int id) {
    return _apiClient.delete('/api/graduate/$id');
  }
}
