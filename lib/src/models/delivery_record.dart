import '../core/utils/date_time_formatter.dart';

class DeliveryRecord {
  DeliveryRecord({
    required this.id,
    required this.userId,
    required this.labId,
    required this.skillTags,
    required this.reason,
    required this.attachmentUrl,
    required this.deliveryAttemptCount,
    required this.withdrawCount,
    required this.createTime,
    required this.status,
    required this.comment,
    required this.updateTime,
    required this.isAdmitted,
    required this.admitTime,
    required this.studentName,
    required this.studentId,
    required this.college,
    required this.major,
    required this.phone,
    required this.email,
    required this.resumeUrl,
    required this.labName,
  });

  final int id;
  final int? userId;
  final int? labId;
  final String? skillTags;
  final String? reason;
  final String? attachmentUrl;
  final int deliveryAttemptCount;
  final int withdrawCount;
  final DateTime? createTime;
  final int status;
  final String? comment;
  final DateTime? updateTime;
  final int isAdmitted;
  final DateTime? admitTime;
  final String? studentName;
  final String? studentId;
  final String? college;
  final String? major;
  final String? phone;
  final String? email;
  final String? resumeUrl;
  final String? labName;

  int get displayStatus {
    if (status == 3) {
      return 6;
    }
    if (status == 2) {
      return 2;
    }
    if (isAdmitted == 1) {
      return 1;
    }
    if (isAdmitted == 2) {
      return 3;
    }
    if (isAdmitted == 3) {
      return 5;
    }
    if (status == 1) {
      return 4;
    }
    return 0;
  }

  String get statusLabel {
    switch (displayStatus) {
      case 1:
        return '已加入';
      case 2:
        return '已拒绝';
      case 3:
        return '待学生确认';
      case 4:
        return '审核通过';
      case 5:
        return 'offer 已关闭';
      case 6:
        return '已撤销';
      default:
        return '待审核';
    }
  }

  bool get canAudit => displayStatus == 0;
  bool get hasResume => (resumeUrl ?? '').trim().isNotEmpty;
  bool get canPreviewResume =>
      hasResume && !(resumeUrl ?? '').trim().startsWith('protected:');
  List<String> get attachmentPaths => (attachmentUrl ?? '')
      .split(',')
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
  bool get showsProfileResume =>
      hasResume && !attachmentPaths.contains((resumeUrl ?? '').trim());
  String get displayStudentId =>
      (studentId ?? '').trim().isEmpty ? '-' : studentId!.trim();
  String get displayStudentName =>
      (studentName ?? '').trim().isEmpty ? '未命名学生' : studentName!.trim();
  String get displayLabName =>
      (labName ?? '').trim().isEmpty ? '未绑定实验室' : labName!.trim();
  String get displayReason {
    final text = (reason ?? '').trim();
    return text.isEmpty ? '未填写投递说明' : text;
  }

  factory DeliveryRecord.fromJson(Map<String, dynamic> json) {
    return DeliveryRecord(
      id: _toInt(json['id']),
      userId: _toNullableInt(json['userId']),
      labId: _toNullableInt(json['labId']),
      skillTags: json['skillTags']?.toString(),
      reason: json['reason']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      deliveryAttemptCount: _toInt(json['deliveryAttemptCount'], fallback: 1),
      withdrawCount: _toInt(json['withdrawCount']),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      status: _toInt(json['status']),
      comment: json['comment']?.toString(),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
      isAdmitted: _toInt(json['isAdmitted']),
      admitTime: DateTimeFormatter.tryParse(json['admitTime']),
      studentName: json['studentName']?.toString(),
      studentId: json['studentId']?.toString(),
      college: json['college']?.toString(),
      major: json['major']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      resumeUrl: json['resumeUrl']?.toString(),
      labName: json['labName']?.toString(),
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
