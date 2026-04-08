import '../core/utils/date_time_formatter.dart';

class LabApplication {
  LabApplication({
    required this.id,
    required this.labId,
    required this.labName,
    required this.planTitle,
    required this.status,
    required this.applyReason,
    required this.auditComment,
    required this.createTime,
  });

  final int id;
  final int? labId;
  final String? labName;
  final String? planTitle;
  final String status;
  final String? applyReason;
  final String? auditComment;
  final DateTime? createTime;

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return '待审核';
      case 'leader_approved':
        return '初审通过';
      case 'approved':
        return '已通过';
      case 'rejected':
        return '已驳回';
      default:
        return status;
    }
  }

  factory LabApplication.fromJson(Map<String, dynamic> json) {
    return LabApplication(
      id: (json['id'] as num?)?.toInt() ?? 0,
      labId: (json['labId'] as num?)?.toInt(),
      labName: json['labName']?.toString(),
      planTitle: json['planTitle']?.toString(),
      status: json['status']?.toString() ?? '',
      applyReason: json['applyReason']?.toString(),
      auditComment: json['auditComment']?.toString(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
    );
  }
}
