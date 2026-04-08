import '../core/utils/date_time_formatter.dart';

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.attendanceDate,
    required this.status,
    required this.reason,
    required this.confirmTime,
  });

  final int id;
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
        return '待确认';
    }
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      attendanceDate: json['attendanceDate']?.toString(),
      status: (json['status'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString(),
      confirmTime: DateTimeFormatter.tryParse(json['confirmTime']),
    );
  }
}
