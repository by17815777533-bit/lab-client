import '../../core/utils/date_time_formatter.dart';

class LabExitApplicationRecord {
  LabExitApplicationRecord({
    required this.id,
    required this.userId,
    required this.labId,
    required this.reason,
    required this.status,
    required this.auditRemark,
    required this.auditBy,
    required this.auditTime,
    required this.createTime,
    required this.updateTime,
    required this.realName,
    required this.studentId,
    required this.major,
    required this.labName,
  });

  final int id;
  final int userId;
  final int labId;
  final String reason;
  final int status;
  final String? auditRemark;
  final int? auditBy;
  final DateTime? auditTime;
  final DateTime? createTime;
  final DateTime? updateTime;
  final String? realName;
  final String? studentId;
  final String? major;
  final String? labName;

  bool get isPending => status == 0;
  bool get isApproved => status == 1;
  bool get isRejected => status == 2;

  String get statusLabel {
    switch (status) {
      case 0:
        return '待审核';
      case 1:
        return '已通过';
      case 2:
        return '已驳回';
      default:
        return '状态 $status';
    }
  }

  factory LabExitApplicationRecord.fromJson(Map<String, dynamic> json) {
    return LabExitApplicationRecord(
      id: _toInt(json['id']),
      userId: _toInt(json['userId']),
      labId: _toInt(json['labId']),
      reason: json['reason']?.toString() ?? '',
      status: _toInt(json['status']),
      auditRemark: json['auditRemark']?.toString(),
      auditBy: _toNullableInt(json['auditBy']),
      auditTime: DateTimeFormatter.tryParse(json['auditTime']),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
      realName: json['realName']?.toString(),
      studentId: json['studentId']?.toString(),
      major: json['major']?.toString(),
      labName: json['labName']?.toString(),
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
