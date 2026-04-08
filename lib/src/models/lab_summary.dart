import '../core/utils/date_time_formatter.dart';

class LabSummary {
  LabSummary({
    required this.id,
    required this.labName,
    required this.labCode,
    required this.collegeId,
    required this.labDesc,
    required this.teacherName,
    required this.location,
    required this.contactEmail,
    required this.requireSkill,
    required this.recruitNum,
    required this.currentNum,
    required this.status,
    required this.foundingDate,
    required this.awards,
    required this.basicInfo,
    required this.advisors,
    required this.currentAdmins,
    required this.createTime,
    required this.updateTime,
  });

  final int id;
  final String labName;
  final String? labCode;
  final int? collegeId;
  final String? labDesc;
  final String? teacherName;
  final String? location;
  final String? contactEmail;
  final String? requireSkill;
  final int recruitNum;
  final int currentNum;
  final int status;
  final String? foundingDate;
  final String? awards;
  final String? basicInfo;
  final String? advisors;
  final String? currentAdmins;
  final DateTime? createTime;
  final DateTime? updateTime;

  bool get isOpen => status == 1;
  String get statusLabel => isOpen ? '开放' : '关闭';

  factory LabSummary.fromJson(Map<String, dynamic> json) {
    return LabSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      labName: json['labName']?.toString() ?? '',
      labCode: json['labCode']?.toString(),
      collegeId: (json['collegeId'] as num?)?.toInt(),
      labDesc: json['labDesc']?.toString(),
      teacherName: json['teacherName']?.toString(),
      location: json['location']?.toString(),
      contactEmail: json['contactEmail']?.toString(),
      requireSkill: json['requireSkill']?.toString(),
      recruitNum: (json['recruitNum'] as num?)?.toInt() ?? 0,
      currentNum: (json['currentNum'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      foundingDate: json['foundingDate']?.toString(),
      awards: json['awards']?.toString(),
      basicInfo: json['basicInfo']?.toString(),
      advisors: json['advisors']?.toString(),
      currentAdmins: json['currentAdmins']?.toString(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
    );
  }
}
