import '../core/utils/date_time_formatter.dart';
import 'practice_question_bank_item.dart';

class WrittenExamEnvironmentDetail {
  WrittenExamEnvironmentDetail({
    required this.key,
    required this.available,
    required this.label,
    required this.configuredCommand,
    required this.resolvedCommand,
    required this.message,
  });

  final String key;
  final bool available;
  final String? label;
  final String? configuredCommand;
  final String? resolvedCommand;
  final String? message;

  factory WrittenExamEnvironmentDetail.fromJson(
    String key,
    Map<String, dynamic> json,
  ) {
    return WrittenExamEnvironmentDetail(
      key: key,
      available: json['available'] == true,
      label: json['label']?.toString(),
      configuredCommand: json['configuredCommand']?.toString(),
      resolvedCommand: json['resolvedCommand']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

class WrittenExamConfigData {
  WrittenExamConfigData({
    required this.recruitmentOpen,
    required this.examTitle,
    required this.examDescription,
    required this.startTime,
    required this.endTime,
    required this.passScore,
    required this.questions,
    required this.environmentStatus,
    required this.environmentDetails,
  });

  final bool recruitmentOpen;
  final String? examTitle;
  final String? examDescription;
  final DateTime? startTime;
  final DateTime? endTime;
  final int passScore;
  final List<PracticeQuestionBankItem> questions;
  final Map<String, bool> environmentStatus;
  final List<WrittenExamEnvironmentDetail> environmentDetails;

  factory WrittenExamConfigData.fromJson(Map<String, dynamic> json) {
    final exam = json['exam'];
    final examMap = exam is Map ? exam.cast<String, dynamic>() : null;
    final statusMap = (json['environmentStatus'] is Map)
        ? (json['environmentStatus'] as Map).map(
            (key, value) => MapEntry(key.toString(), value == true),
          )
        : const <String, bool>{};
    final detailsMap = json['environmentDetails'];

    return WrittenExamConfigData(
      recruitmentOpen: json['recruitmentOpen'] == true,
      examTitle: examMap?['title']?.toString(),
      examDescription: examMap?['description']?.toString(),
      startTime: DateTimeFormatter.tryParse(examMap?['startTime']),
      endTime: DateTimeFormatter.tryParse(examMap?['endTime']),
      passScore: (examMap?['passScore'] as num?)?.toInt() ?? 60,
      questions: (json['questions'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (Map item) =>
                PracticeQuestionBankItem.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      environmentStatus: statusMap,
      environmentDetails: detailsMap is Map
          ? detailsMap.entries
              .where((entry) => entry.value is Map)
              .map(
                (entry) => WrittenExamEnvironmentDetail.fromJson(
                  entry.key.toString(),
                  (entry.value as Map).cast<String, dynamic>(),
                ),
              )
              .toList(growable: false)
          : const <WrittenExamEnvironmentDetail>[],
    );
  }
}

class WrittenExamAnswerRecord {
  WrittenExamAnswerRecord({
    required this.questionId,
    required this.questionType,
    required this.title,
    required this.fullScore,
    required this.score,
    required this.answer,
    required this.language,
    required this.code,
    required this.resultMessage,
  });

  final int? questionId;
  final String? questionType;
  final String title;
  final num? fullScore;
  final num? score;
  final String? answer;
  final String? language;
  final String? code;
  final String? resultMessage;

  factory WrittenExamAnswerRecord.fromJson(Map<String, dynamic> json) {
    return WrittenExamAnswerRecord(
      questionId: (json['questionId'] as num?)?.toInt(),
      questionType: json['questionType']?.toString(),
      title: json['title']?.toString() ?? '',
      fullScore: json['fullScore'] as num?,
      score: json['score'] as num?,
      answer: json['answer']?.toString(),
      language: json['language']?.toString(),
      code: json['code']?.toString(),
      resultMessage: json['resultMessage']?.toString(),
    );
  }
}

class WrittenExamSubmissionRecord {
  WrittenExamSubmissionRecord({
    required this.id,
    required this.realName,
    required this.studentId,
    required this.major,
    required this.totalScore,
    required this.aiRemark,
    required this.adminRemark,
    required this.status,
    required this.submitTime,
    required this.answerSheet,
  });

  final int id;
  final String? realName;
  final String? studentId;
  final String? major;
  final num? totalScore;
  final String? aiRemark;
  final String? adminRemark;
  final int status;
  final DateTime? submitTime;
  final List<WrittenExamAnswerRecord> answerSheet;

  factory WrittenExamSubmissionRecord.fromJson(Map<String, dynamic> json) {
    return WrittenExamSubmissionRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      realName: json['realName']?.toString(),
      studentId: json['studentId']?.toString(),
      major: json['major']?.toString(),
      totalScore: json['totalScore'] as num?,
      aiRemark: json['aiRemark']?.toString(),
      adminRemark: json['adminRemark']?.toString(),
      status: (json['status'] as num?)?.toInt() ?? 1,
      submitTime: DateTimeFormatter.tryParse(json['submitTime']),
      answerSheet: (json['answerSheet'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (Map item) =>
                WrittenExamAnswerRecord.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }
}

class WrittenExamSessionData {
  WrittenExamSessionData({
    required this.labName,
    required this.examTitle,
    required this.examDescription,
    required this.passScore,
    required this.alreadySubmitted,
    required this.questions,
    required this.submission,
    required this.environmentStatus,
  });

  final String? labName;
  final String? examTitle;
  final String? examDescription;
  final int? passScore;
  final bool alreadySubmitted;
  final List<PracticeQuestionBankItem> questions;
  final WrittenExamSubmissionRecord? submission;
  final Map<String, bool> environmentStatus;

  factory WrittenExamSessionData.fromJson(Map<String, dynamic> json) {
    final lab = json['lab'];
    final labMap = lab is Map ? lab.cast<String, dynamic>() : null;
    final exam = json['exam'];
    final examMap = exam is Map ? exam.cast<String, dynamic>() : null;
    final submission = json['submission'];

    return WrittenExamSessionData(
      labName: labMap?['labName']?.toString(),
      examTitle: examMap?['title']?.toString(),
      examDescription: examMap?['description']?.toString(),
      passScore: (examMap?['passScore'] as num?)?.toInt(),
      alreadySubmitted: json['alreadySubmitted'] == true,
      questions: (json['questions'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (Map item) =>
                PracticeQuestionBankItem.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      submission: submission is Map
          ? WrittenExamSubmissionRecord.fromJson(
              submission.cast<String, dynamic>(),
            )
          : null,
      environmentStatus: (json['environmentStatus'] is Map)
          ? (json['environmentStatus'] as Map).map(
              (key, value) => MapEntry(key.toString(), value == true),
            )
          : const <String, bool>{},
    );
  }
}
