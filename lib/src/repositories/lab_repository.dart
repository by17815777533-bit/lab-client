import '../core/network/api_client.dart';
import '../models/lab_stats.dart';
import '../models/lab_summary.dart';
import '../models/paged_result.dart';

class LabRepository {
  LabRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<LabSummary>> fetchLabs({
    int pageNum = 1,
    int pageSize = 50,
    int? status,
    String? keyword,
  }) async {
    final response = await _apiClient.get(
      '/api/labs/list',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'status': status,
        'labName': keyword,
      },
    );

    return PagedResult<LabSummary>.fromJson(
      response as Map<String, dynamic>,
      LabSummary.fromJson,
    );
  }

  Future<LabSummary> fetchLabDetail(int labId) async {
    final response = await _apiClient.get('/api/labs/$labId');
    return LabSummary.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateManagedLabInfo({
    required int id,
    required String labName,
    String? labCode,
    int? collegeId,
    String? labDesc,
    String? teacherName,
    String? location,
    String? contactEmail,
    String? requireSkill,
    required int recruitNum,
    required int currentNum,
    required int status,
    String? foundingDate,
    String? awards,
    String? basicInfo,
    String? advisors,
    String? currentAdmins,
  }) {
    return _apiClient.put(
      '/api/labs/update-info',
      data: <String, dynamic>{
        'id': id,
        'labName': labName,
        'labCode': labCode,
        'collegeId': collegeId,
        'labDesc': labDesc,
        'teacherName': teacherName,
        'location': location,
        'contactEmail': contactEmail,
        'requireSkill': requireSkill,
        'recruitNum': recruitNum,
        'currentNum': currentNum,
        'status': status,
        'foundingDate': foundingDate,
        'awards': awards,
        'basicInfo': basicInfo,
        'advisors': advisors,
        'currentAdmins': currentAdmins,
      },
    );
  }

  Future<LabStats> fetchLabStats() async {
    final response = await _apiClient.get('/api/labs/stats');
    return LabStats.fromJson(response as Map<String, dynamic>);
  }
}
