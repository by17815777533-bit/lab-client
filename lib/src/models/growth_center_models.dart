import '../core/utils/date_time_formatter.dart';

class GrowthTrackSummary {
  GrowthTrackSummary({
    required this.code,
    required this.name,
    required this.shortName,
    required this.subtitle,
    required this.description,
    required this.fitScene,
    required this.recommendedKeyword,
    required this.interviewPosition,
    required this.tags,
    required this.courses,
    required this.books,
    required this.competitions,
    required this.certificates,
    required this.competencies,
    required this.matchScore,
  });

  final String code;
  final String name;
  final String? shortName;
  final String? subtitle;
  final String? description;
  final String? fitScene;
  final String? recommendedKeyword;
  final String? interviewPosition;
  final List<String> tags;
  final List<String> courses;
  final List<String> books;
  final List<String> competitions;
  final List<String> certificates;
  final List<Map<String, dynamic>> competencies;
  final int? matchScore;

  factory GrowthTrackSummary.fromJson(Map<String, dynamic> json) {
    return GrowthTrackSummary(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: json['shortName']?.toString(),
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      fitScene: json['fitScene']?.toString(),
      recommendedKeyword: json['recommendedKeyword']?.toString(),
      interviewPosition: json['interviewPosition']?.toString(),
      tags: _stringList(json['tags']),
      courses: _stringList(json['courses']),
      books: _stringList(json['books']),
      competitions: _stringList(json['competitions']),
      certificates: _stringList(json['certificates']),
      competencies: _mapList(json['competencies']),
      matchScore: (json['matchScore'] as num?)?.toInt(),
    );
  }
}

class GrowthTrackStage {
  GrowthTrackStage({
    required this.id,
    required this.stageNo,
    required this.phaseCode,
    required this.title,
    required this.duration,
    required this.goal,
    required this.resourceName,
    required this.resourceUrl,
    required this.practiceKeyword,
    required this.actionHint,
    required this.focusSkills,
  });

  final int id;
  final int? stageNo;
  final String? phaseCode;
  final String title;
  final String? duration;
  final String? goal;
  final String? resourceName;
  final String? resourceUrl;
  final String? practiceKeyword;
  final String? actionHint;
  final List<String> focusSkills;

  factory GrowthTrackStage.fromJson(Map<String, dynamic> json) {
    return GrowthTrackStage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      stageNo: (json['stageNo'] as num?)?.toInt(),
      phaseCode: json['phaseCode']?.toString(),
      title: json['title']?.toString() ?? '',
      duration: json['duration']?.toString(),
      goal: json['goal']?.toString(),
      resourceName: json['resourceName']?.toString(),
      resourceUrl: json['resourceUrl']?.toString(),
      practiceKeyword: json['practiceKeyword']?.toString(),
      actionHint: json['actionHint']?.toString(),
      focusSkills: _stringList(json['focusSkills']),
    );
  }
}

class GrowthTrackDetail {
  GrowthTrackDetail({
    required this.track,
    required this.stages,
  });

  final GrowthTrackSummary track;
  final List<GrowthTrackStage> stages;

  factory GrowthTrackDetail.fromJson(Map<String, dynamic> json) {
    return GrowthTrackDetail(
      track: GrowthTrackSummary.fromJson(
        (json['track'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      stages: _mapList(json['stages'])
          .map(GrowthTrackStage.fromJson)
          .toList(growable: false),
    );
  }
}

class GrowthAssessmentOptionView {
  GrowthAssessmentOptionView({
    required this.id,
    required this.optionKey,
    required this.optionTitle,
    required this.optionDesc,
  });

  final int id;
  final String optionKey;
  final String optionTitle;
  final String optionDesc;

  factory GrowthAssessmentOptionView.fromJson(Map<String, dynamic> json) {
    return GrowthAssessmentOptionView(
      id: (json['id'] as num?)?.toInt() ?? 0,
      optionKey: json['optionKey']?.toString() ?? '',
      optionTitle: json['optionTitle']?.toString() ?? '',
      optionDesc: json['optionDesc']?.toString() ?? '',
    );
  }
}

class GrowthAssessmentQuestionView {
  GrowthAssessmentQuestionView({
    required this.id,
    required this.questionNo,
    required this.dimension,
    required this.title,
    required this.description,
    required this.options,
  });

  final int id;
  final int? questionNo;
  final String? dimension;
  final String title;
  final String? description;
  final List<GrowthAssessmentOptionView> options;

  factory GrowthAssessmentQuestionView.fromJson(Map<String, dynamic> json) {
    return GrowthAssessmentQuestionView(
      id: (json['id'] as num?)?.toInt() ?? 0,
      questionNo: (json['questionNo'] as num?)?.toInt(),
      dimension: json['dimension']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      options: _mapList(json['options'])
          .map(GrowthAssessmentOptionView.fromJson)
          .toList(growable: false),
    );
  }
}

class GrowthAssessmentQuestionSet {
  GrowthAssessmentQuestionSet({
    required this.versionNo,
    required this.questions,
  });

  final int versionNo;
  final List<GrowthAssessmentQuestionView> questions;

  factory GrowthAssessmentQuestionSet.fromJson(Map<String, dynamic> json) {
    return GrowthAssessmentQuestionSet(
      versionNo: (json['versionNo'] as num?)?.toInt() ?? 1,
      questions: _mapList(json['questions'])
          .map(GrowthAssessmentQuestionView.fromJson)
          .toList(growable: false),
    );
  }
}

class GrowthResultView {
  GrowthResultView({
    required this.id,
    required this.summary,
    required this.topTracks,
    required this.ranking,
    required this.answerCount,
    required this.createTime,
  });

  final int id;
  final String? summary;
  final List<GrowthTrackSummary> topTracks;
  final List<GrowthTrackSummary> ranking;
  final int answerCount;
  final DateTime? createTime;

  factory GrowthResultView.fromJson(Map<String, dynamic> json) {
    return GrowthResultView(
      id: (json['id'] as num?)?.toInt() ?? 0,
      summary: json['summary']?.toString(),
      topTracks: _mapList(json['topTracks'])
          .map(GrowthTrackSummary.fromJson)
          .toList(growable: false),
      ranking: _mapList(json['ranking'])
          .map(GrowthTrackSummary.fromJson)
          .toList(growable: false),
      answerCount: (json['answerCount'] as num?)?.toInt() ?? 0,
      createTime: DateTimeFormatter.tryParse(json['createTime']),
    );
  }
}

class GrowthDashboard {
  GrowthDashboard({
    required this.hasResult,
    required this.assessmentVersion,
    required this.tracks,
    required this.latestResult,
  });

  final bool hasResult;
  final int assessmentVersion;
  final List<GrowthTrackSummary> tracks;
  final GrowthResultView? latestResult;

  factory GrowthDashboard.fromJson(Map<String, dynamic> json) {
    return GrowthDashboard(
      hasResult: json['hasResult'] == true,
      assessmentVersion: (json['assessmentVersion'] as num?)?.toInt() ?? 1,
      tracks: _mapList(json['tracks'])
          .map(GrowthTrackSummary.fromJson)
          .toList(growable: false),
      latestResult: json['latestResult'] is Map
          ? GrowthResultView.fromJson(
              (json['latestResult'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((dynamic item) => item.toString()).toList();
  }
  return const <String>[];
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((Map item) => item.cast<String, dynamic>())
      .toList();
}
