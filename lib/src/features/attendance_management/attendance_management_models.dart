import '../../core/utils/date_time_formatter.dart';

class AttendanceTaskItem {
  AttendanceTaskItem({
    required this.id,
    required this.collegeId,
    required this.collegeName,
    required this.semesterName,
    required this.taskName,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.publishedBy,
    required this.publishedTime,
    required this.createdBy,
    required this.createTime,
    required this.updateTime,
    required this.scheduleCount,
  });

  final int id;
  final int? collegeId;
  final String? collegeName;
  final String semesterName;
  final String taskName;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String status;
  final int? publishedBy;
  final DateTime? publishedTime;
  final int? createdBy;
  final DateTime? createTime;
  final DateTime? updateTime;
  final int scheduleCount;

  bool get isPublished => status == 'published';
  String get statusLabel => isPublished ? '已发布' : '草稿';

  factory AttendanceTaskItem.fromJson(Map<String, dynamic> json) {
    return AttendanceTaskItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      collegeId: (json['collegeId'] as num?)?.toInt(),
      collegeName: json['collegeName']?.toString(),
      semesterName: json['semesterName']?.toString() ?? '',
      taskName: json['taskName']?.toString() ?? '',
      description: json['description']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      publishedBy: (json['publishedBy'] as num?)?.toInt(),
      publishedTime: DateTimeFormatter.tryParse(json['publishedTime']),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
      scheduleCount: (json['scheduleCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceScheduleItem {
  AttendanceScheduleItem({
    required this.id,
    required this.taskId,
    required this.weekDay,
    required this.signInStart,
    required this.signInEnd,
    required this.lateThresholdMinutes,
    required this.signCodeLength,
    required this.codeTtlMinutes,
    required this.status,
    required this.remark,
    required this.createTime,
    required this.updateTime,
  });

  final int? id;
  final int? taskId;
  final int weekDay;
  final String signInStart;
  final String signInEnd;
  final int lateThresholdMinutes;
  final int signCodeLength;
  final int codeTtlMinutes;
  final int status;
  final String? remark;
  final DateTime? createTime;
  final DateTime? updateTime;

  String get weekDayLabel {
    switch (weekDay) {
      case 1:
        return '周一';
      case 2:
        return '周二';
      case 3:
        return '周三';
      case 4:
        return '周四';
      case 5:
        return '周五';
      case 6:
        return '周六';
      case 7:
        return '周日';
      default:
        return '未知';
    }
  }

  factory AttendanceScheduleItem.fromJson(Map<String, dynamic> json) {
    return AttendanceScheduleItem(
      id: (json['id'] as num?)?.toInt(),
      taskId: (json['taskId'] as num?)?.toInt(),
      weekDay: (json['weekDay'] as num?)?.toInt() ?? 1,
      signInStart: json['signInStart']?.toString() ?? '19:00:00',
      signInEnd: json['signInEnd']?.toString() ?? '21:00:00',
      lateThresholdMinutes:
          (json['lateThresholdMinutes'] as num?)?.toInt() ?? 15,
      signCodeLength: (json['signCodeLength'] as num?)?.toInt() ?? 4,
      codeTtlMinutes: (json['codeTtlMinutes'] as num?)?.toInt() ?? 90,
      status: (json['status'] as num?)?.toInt() ?? 1,
      remark: json['remark']?.toString(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'weekDay': weekDay,
      'signInStart': signInStart,
      'signInEnd': signInEnd,
      'lateThresholdMinutes': lateThresholdMinutes,
      'signCodeLength': signCodeLength,
      'codeTtlMinutes': codeTtlMinutes,
      'remark': remark,
    };
  }
}

class AttendanceWorkflowSummary {
  AttendanceWorkflowSummary({
    required this.presentCount,
    required this.normalCount,
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
    required this.taskCount,
    required this.todaySessionCount,
    required this.photoCount,
  });

  final int presentCount;
  final int normalCount;
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
  final int taskCount;
  final int todaySessionCount;
  final int photoCount;

  factory AttendanceWorkflowSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceWorkflowSummary(
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      normalCount: (json['normalCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      leaveCount: (json['leaveCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      makeupPendingCount: (json['makeupPendingCount'] as num?)?.toInt() ?? 0,
      makeupApprovedCount:
          (json['makeupApprovedCount'] as num?)?.toInt() ?? 0,
      makeupRejectedCount:
          (json['makeupRejectedCount'] as num?)?.toInt() ?? 0,
      makeupCount: (json['makeupCount'] as num?)?.toInt() ?? 0,
      anomalyCount: (json['anomalyCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0,
      taskCount: (json['taskCount'] as num?)?.toInt() ?? 0,
      todaySessionCount: (json['todaySessionCount'] as num?)?.toInt() ?? 0,
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceLabSessionRecord {
  AttendanceLabSessionRecord({
    required this.userId,
    required this.realName,
    required this.studentId,
    required this.major,
    required this.memberRole,
    required this.signStatus,
    required this.signTime,
    required this.remark,
    required this.source,
    required this.reviewTime,
  });

  final int userId;
  final String realName;
  final String? studentId;
  final String? major;
  final String? memberRole;
  final String? signStatus;
  final DateTime? signTime;
  final String? remark;
  final String? source;
  final DateTime? reviewTime;

  String get statusLabel {
    switch (signStatus) {
      case 'normal':
        return '出勤';
      case 'late':
        return '迟到';
      case 'leave':
        return '请假';
      case 'absent':
        return '缺勤';
      case 'makeup_pending':
        return '待补签审核';
      case 'makeup_approved':
        return '补签通过';
      case 'makeup_rejected':
        return '补签驳回';
      case 'pending':
        return '待签到';
      default:
        return signStatus == null || signStatus!.isEmpty ? '未登记' : signStatus!;
    }
  }

  factory AttendanceLabSessionRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceLabSessionRecord(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      realName: json['realName']?.toString() ?? '',
      studentId: json['studentId']?.toString(),
      major: json['major']?.toString(),
      memberRole: json['memberRole']?.toString(),
      signStatus: json['signStatus']?.toString(),
      signTime: DateTimeFormatter.tryParse(json['signTime']),
      remark: json['remark']?.toString(),
      source: json['source']?.toString(),
      reviewTime: DateTimeFormatter.tryParse(json['reviewTime']),
    );
  }
}

class AttendanceLabCurrentSession {
  AttendanceLabCurrentSession({
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
    required this.normalCount,
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
    required this.sessionCode,
    required this.records,
  });

  final int id;
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
  final int normalCount;
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
  final String? sessionCode;
  final List<AttendanceLabSessionRecord> records;

  String get statusLabel {
    switch (status) {
      case 'pending':
        return '待开始';
      case 'active':
        return '进行中';
      case 'closed':
        return '已结束';
      default:
        return status == null || status!.isEmpty ? '未知状态' : status!;
    }
  }

  factory AttendanceLabCurrentSession.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'] as List<dynamic>? ?? const <dynamic>[];
    return AttendanceLabCurrentSession(
      id: (json['id'] as num?)?.toInt() ?? 0,
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
      normalCount: (json['normalCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      leaveCount: (json['leaveCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      makeupPendingCount: (json['makeupPendingCount'] as num?)?.toInt() ?? 0,
      makeupApprovedCount:
          (json['makeupApprovedCount'] as num?)?.toInt() ?? 0,
      makeupRejectedCount:
          (json['makeupRejectedCount'] as num?)?.toInt() ?? 0,
      makeupCount: (json['makeupCount'] as num?)?.toInt() ?? 0,
      anomalyCount: (json['anomalyCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0,
      sessionCode: json['sessionCode']?.toString(),
      records: rawRecords
          .whereType<Map>()
          .map(
            (item) =>
                AttendanceLabSessionRecord.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}
