import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/network/api_client.dart';
import '../models/paged_result.dart';
import '../features/lab_create_apply/lab_create_apply_models.dart';

class LabCreateApplyRepository {
  LabCreateApplyRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<LabCreateApplyItem>> fetchApplyPage({
    int pageNum = 1,
    int pageSize = 10,
    String? status,
    String? keyword,
  }) async {
    final response = await _apiClient.get(
      '/api/lab-create-applies',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'status': status,
        'keyword': keyword,
      },
    );

    return PagedResult<LabCreateApplyItem>.fromJson(
      response as Map<String, dynamic>,
      LabCreateApplyItem.fromJson,
    );
  }

  Future<List<LabCreateApplyCollegeOption>> fetchCollegeOptions() async {
    final response = await _apiClient.get('/api/colleges/options');
    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) => LabCreateApplyCollegeOption.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  Future<void> createApply({
    required int collegeId,
    required String labName,
    required String teacherName,
    String? location,
    String? contactEmail,
    required String researchDirection,
    required String applyReason,
  }) {
    return _apiClient.post(
      '/api/lab-create-applies',
      data: <String, dynamic>{
        'collegeId': collegeId,
        'labName': labName,
        'teacherName': teacherName,
        'location': location,
        'contactEmail': contactEmail,
        'researchDirection': researchDirection,
        'applyReason': applyReason,
      },
    );
  }
}

final labCreateApplyRepositoryProvider = Provider<LabCreateApplyRepository>((
  ref,
) {
  final bootstrap = ref.read(appBootstrapProvider);
  return LabCreateApplyRepository(
    ApiClient(
      storage: bootstrap.storage,
      settingsController: bootstrap.settingsController,
    ),
  );
});
