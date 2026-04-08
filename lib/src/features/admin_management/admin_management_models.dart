import '../../core/utils/date_time_formatter.dart';
import '../../models/lab_summary.dart';

class AdminManagerUser {
  AdminManagerUser({
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
    required this.labId,
    required this.canEdit,
    required this.createTime,
    required this.updateTime,
    required this.systemAccountCode,
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
  final int? labId;
  final int? canEdit;
  final DateTime? createTime;
  final DateTime? updateTime;
  final String? systemAccountCode;

  bool get isStudent => role == 'student';
  bool get editable => canEdit != 0;

  factory AdminManagerUser.fromJson(Map<String, dynamic> json) {
    return AdminManagerUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
      realName: json['realName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      studentId: json['studentId']?.toString(),
      college: json['college']?.toString(),
      major: json['major']?.toString(),
      grade: json['grade']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      labId: (json['labId'] as num?)?.toInt(),
      canEdit: (json['canEdit'] as num?)?.toInt(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
      systemAccountCode: json['systemAccountCode']?.toString(),
    );
  }
}

class LabAdminAssignment {
  LabAdminAssignment({
    required this.lab,
    required this.admin,
    required this.createTime,
    required this.updateTime,
  });

  final LabSummary lab;
  final AdminManagerUser? admin;
  final DateTime? createTime;
  final DateTime? updateTime;

  factory LabAdminAssignment.fromJson(Map<String, dynamic> json) {
    final rawLab = json['lab'];
    final rawAdmin = json['admin'];
    return LabAdminAssignment(
      lab: LabSummary.fromJson(
        (rawLab is Map ? rawLab.cast<String, dynamic>() : <String, dynamic>{}),
      ),
      admin: rawAdmin is Map
          ? AdminManagerUser.fromJson(rawAdmin.cast<String, dynamic>())
          : null,
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
    );
  }
}
