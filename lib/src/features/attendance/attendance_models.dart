import '../../core/utils/date_time_formatter.dart';

class AttendanceRecordSnapshot {
  AttendanceRecordSnapshot({
    required this.id,
    required this.signStatus,
    required this.signTime,
    required this.remark,
    required this.source,
    required this.reviewTime,
  });

  final int? id;
  final String? signStatus;
  final DateTime? signTime;
  final String? remark;
  final String? source;
  final DateTime? reviewTime;

  String get statusLabel => AttendanceStatusFormatter.label(signStatus);

  factory AttendanceRecordSnapshot.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordSnapshot(
      id: (json['id'] as num?)?.toInt(),
      signStatus: json['signStatus']?.toString(),
      signTime: DateTimeFormatter.tryParse(json['signTime']),
      remark: json['remark']?.toString(),
      source: json['source']?.toString(),
      reviewTime: DateTimeFormatter.tryParse(json['reviewTime']),
    );
  }
}

class AttendanceCurrentSession {
  AttendanceCurrentSession({
    required this.available,
    required this.id,
    required this.taskId,
    required this.scheduleId,
    required this.labId,
    required this.sessionDate,
    required this.status,
    required this.signStartTime,
    required this.signEndTime,
    required this.lateTime,
    required this.codeExpireTime,
    required this.publishTime,
    required this.photoCount,
    required this.dutyAdminUserId,
    required this.backupAdminUserId,
    required this.dutyRemark,
    required this.presentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.absentCount,
    required this.makeupPendingCount,
    required this.makeupApprovedCount,
    required this.makeupRejectedCount,
    required this.makeupCount,
    required this.anomalyCount,
    required this.totalCount,
    required this.attendanceRate,
    required this.canSignIn,
    required this.myRecord,
  });

  final bool available;
  final int? id;
  final int? taskId;
  final int? scheduleId;
  final int? labId;
  final DateTime? sessionDate;
  final String? status;
  final DateTime? signStartTime;
  final DateTime? signEndTime;
  final DateTime? lateTime;
  final DateTime? codeExpireTime;
  final DateTime? publishTime;
  final int photoCount;
  final int? dutyAdminUserId;
  final int? backupAdminUserId;
  final String? dutyRemark;
  final int presentCount;
  final int lateCount;
  final int leaveCount;
  final int absentCount;
  final int makeupPendingCount;
  final int makeupApprovedCount;
  final int makeupRejectedCount;
  final int makeupCount;
  final int anomalyCount;
  final int totalCount;
  final double attendanceRate;
  final bool canSignIn;
  final AttendanceRecordSnapshot? myRecord;

  String get statusLabel => AttendanceStatusFormatter.sessionLabel(status);

  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';

  factory AttendanceCurrentSession.fromJson(Map<String, dynamic> json) {
    return AttendanceCurrentSession(
      available: json['available'] == true,
      id: (json['id'] as num?)?.toInt(),
      taskId: (json['taskId'] as num?)?.toInt(),
      scheduleId: (json['scheduleId'] as num?)?.toInt(),
      labId: (json['labId'] as num?)?.toInt(),
      sessionDate: DateTimeFormatter.tryParse(json['sessionDate']),
      status: json['status']?.toString(),
      signStartTime: DateTimeFormatter.tryParse(json['signStartTime']),
      signEndTime: DateTimeFormatter.tryParse(json['signEndTime']),
      lateTime: DateTimeFormatter.tryParse(json['lateTime']),
      codeExpireTime: DateTimeFormatter.tryParse(json['codeExpireTime']),
      publishTime: DateTimeFormatter.tryParse(json['publishTime']),
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      dutyAdminUserId: (json['dutyAdminUserId'] as num?)?.toInt(),
      backupAdminUserId: (json['backupAdminUserId'] as num?)?.toInt(),
      dutyRemark: json['dutyRemark']?.toString(),
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      leaveCount: (json['leaveCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      makeupPendingCount: (json['makeupPendingCount'] as num?)?.toInt() ?? 0,
      makeupApprovedCount: (json['makeupApprovedCount'] as num?)?.toInt() ?? 0,
      makeupRejectedCount: (json['makeupRejectedCount'] as num?)?.toInt() ?? 0,
      makeupCount: (json['makeupCount'] as num?)?.toInt() ?? 0,
      anomalyCount: (json['anomalyCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      attendanceRate: _toDouble(json['attendanceRate']),
      canSignIn: json['canSignIn'] == true,
      myRecord: json['myRecord'] is Map<String, dynamic>
          ? AttendanceRecordSnapshot.fromJson(
              json['myRecord'] as Map<String, dynamic>,
            )
          : json['myRecord'] is Map
          ? AttendanceRecordSnapshot.fromJson(
              (json['myRecord'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }
}

class AttendanceHistoryRecord {
  AttendanceHistoryRecord({
    required this.id,
    required this.sessionId,
    required this.taskId,
    required this.labId,
    required this.labName,
    required this.sessionDate,
    required this.signStatus,
    required this.signCode,
    required this.signTime,
    required this.remark,
    required this.source,
    required this.reviewTime,
  });

  final int id;
  final int? sessionId;
  final int? taskId;
  final int? labId;
  final String? labName;
  final DateTime? sessionDate;
  final String? signStatus;
  final String? signCode;
  final DateTime? signTime;
  final String? remark;
  final String? source;
  final DateTime? reviewTime;

  String get statusLabel => AttendanceStatusFormatter.label(signStatus);

  factory AttendanceHistoryRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sessionId: (json['sessionId'] as num?)?.toInt(),
      taskId: (json['taskId'] as num?)?.toInt(),
      labId: (json['labId'] as num?)?.toInt(),
      labName: json['labName']?.toString(),
      sessionDate: DateTimeFormatter.tryParse(json['sessionDate']),
      signStatus: json['signStatus']?.toString(),
      signCode: json['signCode']?.toString(),
      signTime: DateTimeFormatter.tryParse(json['signTime']),
      remark: json['remark']?.toString(),
      source: json['source']?.toString(),
      reviewTime: DateTimeFormatter.tryParse(json['reviewTime']),
    );
  }
}

class AttendanceStatusFormatter {
  static String sessionLabel(String? status) {
    switch (status) {
      case 'pending':
        return '待发布';
      case 'active':
        return '进行中';
      case 'closed':
        return '已结束';
      default:
        return status == null || status.isEmpty ? '未知状态' : status;
    }
  }

  static String label(String? status) {
    switch (status) {
      case 'normal':
        return '出勤';
      case 'late':
        return '迟到';
      case 'leave':
        return '请假';
      case 'absent':
        return '缺勤';
      case 'makeup_pending':
        return '补签待审';
      case 'makeup_approved':
        return '补签通过';
      case 'makeup_rejected':
        return '补签驳回';
      case 'pending':
        return '待确认';
      case 'exempt':
        return '免考勤';
      default:
        return status == null || status.isEmpty ? '未知状态' : status;
    }
  }

  static ColorToken color(String? status) {
    switch (status) {
      case 'normal':
      case 'makeup_approved':
        return ColorToken.success;
      case 'late':
      case 'makeup_pending':
        return ColorToken.warning;
      case 'leave':
        return ColorToken.info;
      case 'absent':
      case 'makeup_rejected':
        return ColorToken.danger;
      default:
        return ColorToken.neutral;
    }
  }
}

enum ColorToken { success, warning, info, danger, neutral }
