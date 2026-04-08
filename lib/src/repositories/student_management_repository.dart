import '../core/network/api_client.dart';
import '../models/admin_student_record.dart';
import '../models/paged_result.dart';

class StudentManagementRepository {
  StudentManagementRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<AdminStudentRecord>> fetchStudents({
    int pageNum = 1,
    int pageSize = 10,
    String? keyword,
    String? realName,
    String? studentId,
    String? major,
  }) async {
    final response = await _apiClient.get(
      '/api/admin/users',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'keyword': keyword,
        'realName': realName,
        'studentId': studentId,
        'major': major,
      },
    );

    return PagedResult<AdminStudentRecord>.fromJson(
      response as Map<String, dynamic>,
      AdminStudentRecord.fromJson,
    );
  }

  Future<void> deleteStudent(int id) {
    return _apiClient.delete('/api/admin/users/$id');
  }
}
