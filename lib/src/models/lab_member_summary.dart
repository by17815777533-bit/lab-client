import '../core/utils/date_time_formatter.dart';

class LabMemberSummary {
  LabMemberSummary({
    required this.id,
    required this.realName,
    required this.studentId,
    required this.major,
    required this.memberRole,
    required this.joinDate,
    required this.username,
  });

  final int id;
  final String realName;
  final String? studentId;
  final String? major;
  final String? memberRole;
  final DateTime? joinDate;
  final String? username;

  String get memberRoleLabel => memberRole == 'lab_leader' ? '负责人' : '成员';

  factory LabMemberSummary.fromJson(Map<String, dynamic> json) {
    return LabMemberSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      realName: json['realName']?.toString() ?? '',
      studentId: json['studentId']?.toString(),
      major: json['major']?.toString(),
      memberRole: json['memberRole']?.toString(),
      joinDate: DateTimeFormatter.tryParse(json['joinDate']),
      username: json['username']?.toString(),
    );
  }
}
