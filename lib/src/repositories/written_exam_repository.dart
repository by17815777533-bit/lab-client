import '../core/network/api_client.dart';
import '../models/paged_result.dart';
import '../models/practice_question_bank_item.dart';
import '../models/written_exam_lab.dart';
import '../models/written_exam_models.dart';
import '../models/written_exam_notification.dart';

class WrittenExamRepository {
  WrittenExamRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<WrittenExamNotification>> fetchNotifications() async {
    final response = await _apiClient.get(
      '/api/written-exam/student/notifications',
    );
    final list = response as List<dynamic>? ?? const <dynamic>[];
    return list
        .whereType<Map>()
        .map(
          (Map item) =>
              WrittenExamNotification.fromJson(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  Future<void> markNotificationRead(int id) {
    return _apiClient.post('/api/written-exam/student/notifications/read/$id');
  }

  Future<PagedResult<WrittenExamLab>> fetchLabs({
    int pageNum = 1,
    int pageSize = 6,
    String? labName,
    int? status,
  }) async {
    final response = await _apiClient.get(
      '/api/written-exam/student/labs',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'labName': labName,
        'status': status,
      },
    );

    return PagedResult<WrittenExamLab>.fromJson(
      response as Map<String, dynamic>,
      WrittenExamLab.fromJson,
    );
  }

  Future<WrittenExamSessionData> fetchStudentExam(int labId) async {
    final response = await _apiClient.get('/api/written-exam/student/exam/$labId');
    return WrittenExamSessionData.fromJson(response as Map<String, dynamic>);
  }

  Future<WrittenExamSubmissionRecord?> fetchStudentSubmission(int labId) async {
    final response = await _apiClient.get(
      '/api/written-exam/student/submission/$labId',
    );
    if (response == null) {
      return null;
    }
    return WrittenExamSubmissionRecord.fromJson(response as Map<String, dynamic>);
  }

  Future<WrittenExamSubmissionRecord> submitStudentExam({
    required int labId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _apiClient.post(
      '/api/written-exam/student/submit',
      data: <String, dynamic>{'labId': labId, 'answers': answers},
    );
    final map = response as Map<String, dynamic>;
    return WrittenExamSubmissionRecord.fromJson(map);
  }

  Future<WrittenExamConfigData> fetchAdminConfig() async {
    final response = await _apiClient.get('/api/written-exam/admin/config');
    return WrittenExamConfigData.fromJson(response as Map<String, dynamic>);
  }

  Future<void> saveAdminConfig({
    required bool recruitmentOpen,
    required String title,
    String? description,
    required String startTime,
    required String endTime,
    required int passScore,
    required List<PracticeQuestionBankItem> questions,
  }) {
    return _apiClient.post(
      '/api/written-exam/admin/config',
      data: <String, dynamic>{
        'recruitmentOpen': recruitmentOpen,
        'title': title,
        'description': description,
        'startTime': startTime,
        'endTime': endTime,
        'passScore': passScore,
        'questions': questions.map((item) => item.toPayload()).toList(),
      },
    );
  }

  Future<PagedResult<WrittenExamSubmissionRecord>> fetchAdminSubmissions({
    int pageNum = 1,
    int pageSize = 10,
    int? status,
    String? realName,
  }) async {
    final response = await _apiClient.get(
      '/api/written-exam/admin/submissions',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'status': status,
        'realName': realName,
      },
    );
    return PagedResult<WrittenExamSubmissionRecord>.fromJson(
      response as Map<String, dynamic>,
      WrittenExamSubmissionRecord.fromJson,
    );
  }

  Future<void> reviewSubmission({
    required int submissionId,
    required int status,
    String? adminRemark,
  }) {
    return _apiClient.post(
      '/api/written-exam/admin/review',
      data: <String, dynamic>{
        'submissionId': submissionId,
        'status': status,
        'adminRemark': adminRemark,
      },
    );
  }
}
