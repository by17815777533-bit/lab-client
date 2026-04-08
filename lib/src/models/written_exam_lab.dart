import '../core/utils/date_time_formatter.dart';

class WrittenExamLab {
  WrittenExamLab({
    required this.id,
    required this.labName,
    required this.labDesc,
    required this.requireSkill,
    required this.hasWrittenExam,
    required this.writtenExamTitle,
    required this.writtenExamStartTime,
    required this.writtenExamEndTime,
    required this.writtenExamPassScore,
    required this.writtenExamOpen,
    required this.writtenExamWithinWindow,
    required this.myExamStatus,
    required this.myExamScore,
    required this.canTakeWrittenExam,
    required this.canDeliver,
    required this.interviewLockedReason,
  });

  final int id;
  final String labName;
  final String? labDesc;
  final String? requireSkill;
  final bool hasWrittenExam;
  final String? writtenExamTitle;
  final DateTime? writtenExamStartTime;
  final DateTime? writtenExamEndTime;
  final num? writtenExamPassScore;
  final bool writtenExamOpen;
  final bool writtenExamWithinWindow;
  final int myExamStatus;
  final num? myExamScore;
  final bool canTakeWrittenExam;
  final bool canDeliver;
  final String? interviewLockedReason;

  String get statusLabel {
    switch (myExamStatus) {
      case 1:
        return '待审核';
      case 2:
        return '已通过';
      case 3:
        return '未通过';
      default:
        return hasWrittenExam ? '未参加' : '无需笔试';
    }
  }

  factory WrittenExamLab.fromJson(Map<String, dynamic> json) {
    return WrittenExamLab(
      id: (json['id'] as num?)?.toInt() ?? 0,
      labName: json['labName']?.toString() ?? '',
      labDesc: json['labDesc']?.toString(),
      requireSkill: json['requireSkill']?.toString(),
      hasWrittenExam: json['hasWrittenExam'] == true,
      writtenExamTitle: json['writtenExamTitle']?.toString(),
      writtenExamStartTime: DateTimeFormatter.tryParse(
        json['writtenExamStartTime'],
      ),
      writtenExamEndTime: DateTimeFormatter.tryParse(
        json['writtenExamEndTime'],
      ),
      writtenExamPassScore: json['writtenExamPassScore'] as num?,
      writtenExamOpen: json['writtenExamOpen'] == true,
      writtenExamWithinWindow: json['writtenExamWithinWindow'] == true,
      myExamStatus: (json['myExamStatus'] as num?)?.toInt() ?? 0,
      myExamScore: json['myExamScore'] as num?,
      canTakeWrittenExam: json['canTakeWrittenExam'] == true,
      canDeliver: json['canDeliver'] == true,
      interviewLockedReason: json['interviewLockedReason']?.toString(),
    );
  }
}
