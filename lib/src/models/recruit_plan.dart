import '../core/utils/date_time_formatter.dart';

class RecruitPlan {
  RecruitPlan({
    required this.id,
    required this.labId,
    required this.title,
    required this.labName,
    required this.collegeName,
    required this.location,
    required this.requireSkill,
    required this.quota,
    required this.requirement,
    required this.status,
    required this.createdBy,
    required this.createTime,
    required this.updateTime,
    required this.startTime,
    required this.endTime,
  });

  final int id;
  final int? labId;
  final String title;
  final String? labName;
  final String? collegeName;
  final String? location;
  final String? requireSkill;
  final int quota;
  final String? requirement;
  final String? status;
  final int? createdBy;
  final DateTime? createTime;
  final DateTime? updateTime;
  final DateTime? startTime;
  final DateTime? endTime;

  bool get isOpen => status == 'open';
  bool get isDraft => status == 'draft';
  bool get isClosed => status == 'closed';

  String get statusLabel {
    switch (status) {
      case 'open':
        return '开放中';
      case 'closed':
        return '已关闭';
      default:
        return '草稿';
    }
  }

  factory RecruitPlan.fromJson(Map<String, dynamic> json) {
    return RecruitPlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      labId: (json['labId'] as num?)?.toInt(),
      title: json['title']?.toString() ?? '',
      labName: json['labName']?.toString(),
      collegeName: json['collegeName']?.toString(),
      location: json['location']?.toString(),
      requireSkill: json['requireSkill']?.toString(),
      quota: (json['quota'] as num?)?.toInt() ?? 0,
      requirement: json['requirement']?.toString(),
      status: json['status']?.toString(),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
      startTime: DateTimeFormatter.tryParse(json['startTime']),
      endTime: DateTimeFormatter.tryParse(json['endTime']),
    );
  }
}
