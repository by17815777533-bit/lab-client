import '../core/utils/date_time_formatter.dart';

class AdminStudentRecord {
  AdminStudentRecord({
    required this.id,
    required this.username,
    required this.realName,
    required this.role,
    required this.studentId,
    required this.college,
    required this.major,
    required this.grade,
    required this.phone,
    required this.email,
    required this.avatar,
    required this.resume,
    required this.labId,
    required this.canEdit,
    required this.createTime,
    required this.updateTime,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  final int id;
  final String username;
  final String realName;
  final String role;
  final String? studentId;
  final String? college;
  final String? major;
  final String? grade;
  final String? phone;
  final String? email;
  final String? avatar;
  final String? resume;
  final int? labId;
  final int? canEdit;
  final DateTime? createTime;
  final DateTime? updateTime;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  int get totalDeliveries => pendingCount + approvedCount + rejectedCount;
  bool get hasResume => (resume ?? '').trim().isNotEmpty;
  bool get canPreviewResume =>
      hasResume && !(resume ?? '').trim().startsWith('protected:');
  String get displayStudentId =>
      (studentId ?? '').trim().isEmpty ? username : studentId!.trim();
  String get initials =>
      realName.trim().isEmpty ? '学' : realName.trim().substring(0, 1);

  factory AdminStudentRecord.fromJson(Map<String, dynamic> json) {
    return AdminStudentRecord(
      id: _toInt(json['id']),
      username: json['username']?.toString() ?? '',
      realName: json['realName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      studentId: json['studentId']?.toString(),
      college: json['college']?.toString(),
      major: json['major']?.toString(),
      grade: json['grade']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
      resume: json['resume']?.toString(),
      labId: _toNullableInt(json['labId']),
      canEdit: _toNullableInt(json['canEdit']),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
      pendingCount: _toInt(json['pendingCount']),
      approvedCount: _toInt(json['approvedCount']),
      rejectedCount: _toInt(json['rejectedCount']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }
}
