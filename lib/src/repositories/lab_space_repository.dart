import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/attendance_record.dart';
import '../models/attendance_summary.dart';
import '../models/lab_daily_attendance_member.dart';
import '../models/lab_member_summary.dart';
import '../models/lab_space_overview.dart';
import '../models/paged_result.dart';
import '../models/space_file_item.dart';
import '../models/space_folder_node.dart';

class LabSpaceRepository {
  LabSpaceRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<LabSpaceOverview> fetchOverview({int? labId}) async {
    final response = await _apiClient.get(
      '/api/lab-space/overview',
      queryParameters: <String, dynamic>{'labId': labId},
    );
    return LabSpaceOverview.fromJson(response as Map<String, dynamic>);
  }

  Future<List<LabMemberSummary>> fetchActiveMembers({int? labId}) async {
    final response = await _apiClient.get(
      '/api/lab-members/active',
      queryParameters: <String, dynamic>{'labId': labId},
    );

    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => LabMemberSummary.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<AttendanceSummary> fetchAttendanceSummary({int? labId}) async {
    final response = await _apiClient.get(
      '/api/lab-space/attendance/summary',
      queryParameters: <String, dynamic>{'labId': labId},
    );
    return AttendanceSummary.fromJson(response as Map<String, dynamic>);
  }

  Future<PagedResult<AttendanceRecord>> fetchMyAttendance({
    int pageNum = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/lab-space/attendance/my',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );
    return PagedResult<AttendanceRecord>.fromJson(
      response as Map<String, dynamic>,
      AttendanceRecord.fromJson,
    );
  }

  Future<void> signIn({
    required String attendanceDate,
    required int status,
    String? reason,
  }) {
    return _apiClient.post(
      '/api/lab-space/attendance/sign-in',
      data: <String, dynamic>{
        'attendanceDate': attendanceDate,
        'status': status,
        'reason': reason,
      },
    );
  }

  Future<List<LabDailyAttendanceMember>> fetchDailyAttendance({
    int? labId,
    required String attendanceDate,
  }) async {
    final response = await _apiClient.get(
      '/api/lab-space/attendance/daily',
      queryParameters: <String, dynamic>{
        'labId': labId,
        'attendanceDate': attendanceDate,
      },
    );

    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) =>
              LabDailyAttendanceMember.fromJson(item.cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> confirmAttendance({
    required int? labId,
    required int userId,
    required String attendanceDate,
    required int status,
    String? reason,
  }) {
    return _apiClient.post(
      '/api/lab-space/attendance/confirm',
      data: <String, dynamic>{
        'labId': labId,
        'userId': userId,
        'attendanceDate': attendanceDate,
        'status': status,
        'reason': reason,
      },
    );
  }

  Future<List<SpaceFolderNode>> fetchFolders({int? labId}) async {
    final response = await _apiClient.get(
      '/api/lab-space/folders',
      queryParameters: <String, dynamic>{'labId': labId},
    );

    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => SpaceFolderNode.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<PagedResult<SpaceFileItem>> fetchFiles({
    int pageNum = 1,
    int pageSize = 10,
    int? labId,
    int? folderId,
    int? archiveFlag,
    String? keyword,
  }) async {
    final response = await _apiClient.get(
      '/api/lab-space/files',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'labId': labId,
        'folderId': folderId,
        'archiveFlag': archiveFlag,
        'keyword': keyword,
      },
    );
    return PagedResult<SpaceFileItem>.fromJson(
      response as Map<String, dynamic>,
      SpaceFileItem.fromJson,
    );
  }

  Future<List<SpaceFileItem>> fetchRecentFiles({
    int? labId,
    int limit = 6,
  }) async {
    final response = await _apiClient.get(
      '/api/lab-space/files/recent',
      queryParameters: <String, dynamic>{'labId': labId, 'limit': limit},
    );

    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => SpaceFileItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> uploadFile({
    required PlatformFile file,
    required int folderId,
    int? labId,
    int archiveFlag = 0,
  }) async {
    final multipartFile = await _toMultipartFile(file);
    await _apiClient.upload(
      '/api/lab-space/files/upload',
      file: multipartFile,
      fields: <String, dynamic>{
        'labId': labId,
        'folderId': folderId,
        'archiveFlag': archiveFlag,
      },
    );
  }

  Future<void> updateFileArchive({
    required int fileId,
    required int archiveFlag,
  }) {
    return _apiClient.post(
      '/api/lab-space/files/$fileId/archive',
      data: <String, dynamic>{'archiveFlag': archiveFlag},
    );
  }

  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    }

    if (file.path != null && file.path!.isNotEmpty) {
      return MultipartFile.fromFile(file.path!, filename: file.name);
    }

    throw ApiException('无法读取所选文件，请重新选择');
  }
}
