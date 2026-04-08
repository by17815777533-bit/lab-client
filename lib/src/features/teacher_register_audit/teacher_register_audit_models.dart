import '../../core/utils/date_time_formatter.dart';

class TeacherRegisterAuditRecord {
  TeacherRegisterAuditRecord({
    required this.id,
    required this.teacherNo,
    required this.realName,
    required this.collegeId,
    required this.title,
    required this.phone,
    required this.email,
    required this.applyReason,
    required this.status,
    required this.collegeAuditBy,
    required this.collegeAuditTime,
    required this.collegeAuditComment,
    required this.schoolAuditBy,
    required this.schoolAuditTime,
    required this.schoolAuditComment,
    required this.generatedUserId,
    required this.createTime,
    required this.collegeName,
    required this.generatedUserName,
  });

  final int id;
  final String teacherNo;
  final String realName;
  final int? collegeId;
  final String? title;
  final String? phone;
  final String email;
  final String? applyReason;
  final String status;
  final int? collegeAuditBy;
  final DateTime? collegeAuditTime;
  final String? collegeAuditComment;
  final int? schoolAuditBy;
  final DateTime? schoolAuditTime;
  final String? schoolAuditComment;
  final int? generatedUserId;
  final DateTime? createTime;
  final String? collegeName;
  final String? generatedUserName;

  bool get isSubmitted => status == 'submitted';
  bool get isCollegeApproved => status == 'college_approved';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  bool get canCollegeApprove => isSubmitted;
  bool get canSchoolApprove => isCollegeApproved;
  bool get canReject => isSubmitted || isCollegeApproved;

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return '待学院审核';
      case 'college_approved':
        return '待学校审核';
      case 'approved':
        return '已通过';
      case 'rejected':
        return '已驳回';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  factory TeacherRegisterAuditRecord.fromJson(Map<String, dynamic> json) {
    return TeacherRegisterAuditRecord(
      id: _toInt(json['id']),
      teacherNo: json['teacherNo']?.toString() ?? '',
      realName: json['realName']?.toString() ?? '',
      collegeId: _toNullableInt(json['collegeId']),
      title: json['title']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString() ?? '',
      applyReason: json['applyReason']?.toString(),
      status: json['status']?.toString() ?? '',
      collegeAuditBy: _toNullableInt(json['collegeAuditBy']),
      collegeAuditTime: DateTimeFormatter.tryParse(json['collegeAuditTime']),
      collegeAuditComment: json['collegeAuditComment']?.toString(),
      schoolAuditBy: _toNullableInt(json['schoolAuditBy']),
      schoolAuditTime: DateTimeFormatter.tryParse(json['schoolAuditTime']),
      schoolAuditComment: json['schoolAuditComment']?.toString(),
      generatedUserId: _toNullableInt(json['generatedUserId']),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      collegeName: json['collegeName']?.toString(),
      generatedUserName: json['generatedUserName']?.toString(),
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
