import '../../core/utils/date_time_formatter.dart';

class LabApplyAuditRecord {
  LabApplyAuditRecord({
    required this.id,
    required this.labId,
    required this.studentUserId,
    required this.recruitPlanId,
    required this.applyReason,
    required this.researchInterest,
    required this.skillSummary,
    required this.status,
    required this.auditBy,
    required this.auditTime,
    required this.auditComment,
    required this.createTime,
    required this.labName,
    required this.planTitle,
    required this.studentName,
    required this.studentId,
    required this.major,
    required this.grade,
    required this.phone,
    required this.email,
  });

  final int id;
  final int? labId;
  final int? studentUserId;
  final int? recruitPlanId;
  final String? applyReason;
  final String? researchInterest;
  final String? skillSummary;
  final String status;
  final int? auditBy;
  final DateTime? auditTime;
  final String? auditComment;
  final DateTime? createTime;
  final String? labName;
  final String? planTitle;
  final String? studentName;
  final String? studentId;
  final String? major;
  final String? grade;
  final String? phone;
  final String? email;

  bool get isSubmitted => status == 'submitted';
  bool get isLeaderApproved => status == 'leader_approved';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  bool get canLeaderApprove => isSubmitted;
  bool get canApprove => isSubmitted || isLeaderApproved;
  bool get canReject => !isApproved && !isRejected;

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
        return status.isEmpty ? '-' : status;
    }
  }

  factory LabApplyAuditRecord.fromJson(Map<String, dynamic> json) {
    return LabApplyAuditRecord(
      id: _toInt(json['id']),
      labId: _toNullableInt(json['labId']),
      studentUserId: _toNullableInt(json['studentUserId']),
      recruitPlanId: _toNullableInt(json['recruitPlanId']),
      applyReason: json['applyReason']?.toString(),
      researchInterest: json['researchInterest']?.toString(),
      skillSummary: json['skillSummary']?.toString(),
      status: json['status']?.toString() ?? '',
      auditBy: _toNullableInt(json['auditBy']),
      auditTime: DateTimeFormatter.tryParse(json['auditTime']),
      auditComment: json['auditComment']?.toString(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      labName: json['labName']?.toString(),
      planTitle: json['planTitle']?.toString(),
      studentName: json['studentName']?.toString(),
      studentId: json['studentId']?.toString(),
      major: json['major']?.toString(),
      grade: json['grade']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
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
