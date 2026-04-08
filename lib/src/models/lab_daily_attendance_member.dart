import '../core/utils/date_time_formatter.dart';

class LabDailyAttendanceMember {
  LabDailyAttendanceMember({
    required this.userId,
    required this.realName,
    required this.studentId,
    required this.major,
    required this.attendanceDate,
    required this.status,
    required this.reason,
    required this.confirmTime,
  });

  final int userId;
  final String realName;
  final String? studentId;
  final String? major;
  final String? attendanceDate;
  final int status;
  final String? reason;
  final DateTime? confirmTime;

  String get statusLabel {
    switch (status) {
      case 1:
        return '出勤';
      case 2:
        return '迟到';
      case 3:
        return '请假';
      case 4:
        return '缺勤';
      case 5:
        return '补签';
      case 6:
        return '免考勤';
      default:
        return '未登记';
    }
  }

  factory LabDailyAttendanceMember.fromJson(Map<String, dynamic> json) {
    return LabDailyAttendanceMember(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      realName: json['realName']?.toString() ?? '',
      studentId: json['studentId']?.toString(),
      major: json['major']?.toString(),
      attendanceDate: json['attendanceDate']?.toString(),
      status: (json['status'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString(),
      confirmTime: DateTimeFormatter.tryParse(json['confirmTime']),
    );
  }
}
