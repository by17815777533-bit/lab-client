import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../core/network/api_client.dart';
import '../models/paged_result.dart';
import '../features/attendance/attendance_models.dart';
import '../features/attendance_management/attendance_management_models.dart';
import '../features/lab_create_apply/lab_create_apply_models.dart';

class AttendanceWorkflowRepository {
  AttendanceWorkflowRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AttendanceCurrentSession> fetchCurrentSession() async {
    final response = await _apiClient.get(
      '/api/attendance-workflow/student/session/current',
    );
    return AttendanceCurrentSession.fromJson(response as Map<String, dynamic>);
  }

  Future<void> signIn({required String signCode, String? remark}) {
    return _apiClient.post(
      '/api/attendance-workflow/student/session/sign-in',
      data: <String, dynamic>{'signCode': signCode, 'remark': remark},
    );
  }

  Future<void> requestMakeup({String? remark}) {
    return _apiClient.post(
      '/api/attendance-workflow/student/session/makeup',
      data: <String, dynamic>{'remark': remark},
    );
  }

  Future<PagedResult<AttendanceHistoryRecord>> fetchHistory({
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.get(
      '/api/attendance-workflow/student/history',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );
    return PagedResult<AttendanceHistoryRecord>.fromJson(
      response as Map<String, dynamic>,
      AttendanceHistoryRecord.fromJson,
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

  Future<PagedResult<AttendanceTaskItem>> fetchTaskPage({
    int pageNum = 1,
    int pageSize = 10,
    int? collegeId,
    String? keyword,
  }) async {
    final response = await _apiClient.get(
      '/api/attendance-workflow/tasks',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'collegeId': collegeId,
        'keyword': keyword,
      },
    );

    return PagedResult<AttendanceTaskItem>.fromJson(
      response as Map<String, dynamic>,
      AttendanceTaskItem.fromJson,
    );
  }

  Future<void> saveTask({
    int? id,
    required int? collegeId,
    required String semesterName,
    required String taskName,
    String? description,
    required String startDate,
    required String endDate,
  }) {
    return _apiClient.post(
      '/api/attendance-workflow/tasks',
      data: <String, dynamic>{
        'id': id,
        'collegeId': collegeId,
        'semesterName': semesterName,
        'taskName': taskName,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
      },
    );
  }

  Future<void> publishTask(int taskId) {
    return _apiClient.post('/api/attendance-workflow/tasks/$taskId/publish');
  }

  Future<List<AttendanceScheduleItem>> fetchTaskSchedules(int taskId) async {
    final response = await _apiClient.get(
      '/api/attendance-workflow/tasks/$taskId/schedules',
    );
    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) =>
              AttendanceScheduleItem.fromJson(item.cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> saveTaskSchedules(
    int taskId,
    List<AttendanceScheduleItem> schedules,
  ) {
    return _apiClient.post(
      '/api/attendance-workflow/tasks/$taskId/schedules',
      data: <Map<String, dynamic>>[
        for (final item in schedules) item.toJson(),
      ],
    );
  }

  Future<AttendanceWorkflowSummary> fetchSummary({
    int? taskId,
    int? labId,
  }) async {
    final response = await _apiClient.get(
      '/api/attendance-workflow/summary',
      queryParameters: <String, dynamic>{'taskId': taskId, 'labId': labId},
    );
    return AttendanceWorkflowSummary.fromJson(
      response as Map<String, dynamic>,
    );
  }

  Future<AttendanceLabCurrentSession> fetchCurrentLabSession() async {
    final response = await _apiClient.get(
      '/api/attendance-workflow/lab/session/current',
    );
    return AttendanceLabCurrentSession.fromJson(
      response as Map<String, dynamic>,
    );
  }

  Future<void> reviewLabRecord({
    required int sessionId,
    required int userId,
    required String signStatus,
    String? remark,
  }) {
    return _apiClient.post(
      '/api/attendance-workflow/lab/records/review',
      data: <String, dynamic>{
        'sessionId': sessionId,
        'userId': userId,
        'signStatus': signStatus,
        'remark': remark,
      },
    );
  }

  Future<Map<String, dynamic>> uploadCurrentSessionPhoto({
    required PlatformFile file,
    String? remark,
  }) async {
    final multipartFile = await _toMultipartFile(file);
    final response = await _apiClient.upload(
      '/api/attendance-workflow/lab/session/current/photo',
      file: multipartFile,
      fields: <String, dynamic>{'remark': remark},
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return response.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> setSessionDuty({
    required int sessionId,
    required int dutyAdminUserId,
    int? backupAdminUserId,
    String? remark,
  }) async {
    final response = await _apiClient.post(
      '/api/attendance-workflow/duty/sessions/$sessionId',
      data: <String, dynamic>{
        'dutyAdminUserId': dutyAdminUserId,
        'backupAdminUserId': backupAdminUserId,
        'remark': remark,
      },
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return response.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    }
    if (file.path != null && file.path!.isNotEmpty) {
      return MultipartFile.fromFile(file.path!, filename: file.name);
    }
    throw Exception('无法读取所选文件');
  }
}
