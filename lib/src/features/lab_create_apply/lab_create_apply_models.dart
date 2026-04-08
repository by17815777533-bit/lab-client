import '../../core/utils/date_time_formatter.dart';

class LabCreateApplyCollegeOption {
  LabCreateApplyCollegeOption({required this.id, required this.collegeName});

  final int id;
  final String collegeName;

  factory LabCreateApplyCollegeOption.fromJson(Map<String, dynamic> json) {
    return LabCreateApplyCollegeOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      collegeName: json['collegeName']?.toString() ?? '',
    );
  }
}

class LabCreateApplyItem {
  LabCreateApplyItem({
    required this.id,
    required this.collegeId,
    required this.collegeName,
    required this.labName,
    required this.teacherName,
    required this.location,
    required this.contactEmail,
    required this.researchDirection,
    required this.applyReason,
    required this.status,
    required this.collegeAuditComment,
    required this.collegeAuditTime,
    required this.schoolAuditComment,
    required this.schoolAuditTime,
    required this.generatedLabId,
    required this.createTime,
    required this.updateTime,
  });

  final int id;
  final int? collegeId;
  final String? collegeName;
  final String labName;
  final String teacherName;
  final String? location;
  final String? contactEmail;
  final String researchDirection;
  final String applyReason;
  final String status;
  final String? collegeAuditComment;
  final DateTime? collegeAuditTime;
  final String? schoolAuditComment;
  final DateTime? schoolAuditTime;
  final int? generatedLabId;
  final DateTime? createTime;
  final DateTime? updateTime;

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
        return status;
    }
  }

  factory LabCreateApplyItem.fromJson(Map<String, dynamic> json) {
    return LabCreateApplyItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      collegeId: (json['collegeId'] as num?)?.toInt(),
      collegeName: json['collegeName']?.toString(),
      labName: json['labName']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? '',
      location: json['location']?.toString(),
      contactEmail: json['contactEmail']?.toString(),
      researchDirection: json['researchDirection']?.toString() ?? '',
      applyReason: json['applyReason']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      collegeAuditComment: json['collegeAuditComment']?.toString(),
      collegeAuditTime: DateTimeFormatter.tryParse(json['collegeAuditTime']),
      schoolAuditComment: json['schoolAuditComment']?.toString(),
      schoolAuditTime: DateTimeFormatter.tryParse(json['schoolAuditTime']),
      generatedLabId: (json['generatedLabId'] as num?)?.toInt(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
    );
  }
}
