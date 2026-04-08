import '../core/utils/date_time_formatter.dart';

class LatestLabApplication {
  LatestLabApplication({
    required this.id,
    required this.studentId,
    required this.major,
    required this.createTime,
    required this.studentName,
    required this.planTitle,
    required this.status,
  });

  final int id;
  final String? studentId;
  final String? major;
  final DateTime? createTime;
  final String? studentName;
  final String? planTitle;
  final String status;

  String get statusLabel {
    switch (status) {
      case 'leader_approved':
        return '初审通过';
      case 'approved':
        return '已通过';
      case 'rejected':
        return '已驳回';
      default:
        return '待审核';
    }
  }

  factory LatestLabApplication.fromJson(Map<String, dynamic> json) {
    return LatestLabApplication(
      id: (json['id'] as num?)?.toInt() ?? 0,
      studentId: json['studentId']?.toString(),
      major: json['major']?.toString(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      studentName: json['studentName']?.toString(),
      planTitle: json['planTitle']?.toString(),
      status: json['status']?.toString() ?? '',
    );
  }
}
