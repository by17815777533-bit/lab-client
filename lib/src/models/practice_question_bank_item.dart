import 'dart:convert';

class PracticeQuestionOption {
  PracticeQuestionOption({required this.label, required this.text});

  final String label;
  final String text;

  factory PracticeQuestionOption.fromJson(Map<String, dynamic> json) {
    return PracticeQuestionOption(
      label: json['label']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'label': label, 'text': text};
  }
}

class PracticeJudgeCase {
  PracticeJudgeCase({required this.input, required this.output});

  final String input;
  final String output;

  factory PracticeJudgeCase.fromJson(Map<String, dynamic> json) {
    return PracticeJudgeCase(
      input: json['input']?.toString() ?? '',
      output: json['output']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'input': input, 'output': output};
  }
}

class PracticeQuestionBankItem {
  PracticeQuestionBankItem({
    required this.id,
    required this.bankQuestionId,
    required this.questionType,
    required this.trackCode,
    required this.title,
    required this.content,
    required this.difficulty,
    required this.inputFormat,
    required this.outputFormat,
    required this.sampleInput,
    required this.sampleOutput,
    required this.tags,
    required this.analysisHint,
    required this.options,
    required this.correctAnswer,
    required this.acceptableAnswers,
    required this.allowedLanguages,
    required this.judgeCases,
    required this.score,
    required this.sortOrder,
  });

  final int id;
  final int? bankQuestionId;
  final String questionType;
  final String? trackCode;
  final String title;
  final String? content;
  final String? difficulty;
  final String? inputFormat;
  final String? outputFormat;
  final String? sampleInput;
  final String? sampleOutput;
  final List<String> tags;
  final String? analysisHint;
  final List<PracticeQuestionOption> options;
  final String? correctAnswer;
  final List<String> acceptableAnswers;
  final List<String> allowedLanguages;
  final List<PracticeJudgeCase> judgeCases;
  final int? score;
  final int? sortOrder;

  bool get isProgramming => questionType == 'programming';
  bool get isSingleChoice => questionType == 'single_choice';
  bool get isFillBlank => questionType == 'fill_blank';

  factory PracticeQuestionBankItem.fromJson(Map<String, dynamic> json) {
    final sampleCase = _parseSampleCase(json['sampleCase']);
    return PracticeQuestionBankItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bankQuestionId: (json['bankQuestionId'] as num?)?.toInt(),
      questionType: json['questionType']?.toString() ?? 'programming',
      trackCode: json['trackCode']?.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString(),
      difficulty: json['difficulty']?.toString(),
      inputFormat: json['inputFormat']?.toString(),
      outputFormat: json['outputFormat']?.toString(),
      sampleInput: sampleCase['input'],
      sampleOutput: sampleCase['output'],
      tags: _readStringList(json['tags']),
      analysisHint: json['analysisHint']?.toString(),
      options: _readOptions(json['options']),
      correctAnswer: json['correctAnswer']?.toString(),
      acceptableAnswers: _readStringList(json['acceptableAnswers']),
      allowedLanguages: _readStringList(json['allowedLanguages']),
      judgeCases: _readJudgeCases(json['judgeCases']),
      score: (json['score'] as num?)?.toInt(),
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'id': id == 0 ? null : id,
      'bankQuestionId': bankQuestionId,
      'questionType': questionType,
      'trackCode': trackCode,
      'title': title,
      'content': content,
      'difficulty': difficulty,
      'inputFormat': inputFormat,
      'outputFormat': outputFormat,
      'sampleCase': jsonEncode(<String, String?>{
        'input': sampleInput,
        'output': sampleOutput,
      }),
      'tags': tags,
      'analysisHint': analysisHint,
      'options': options.map((item) => item.toJson()).toList(),
      'correctAnswer': correctAnswer,
      'acceptableAnswers': acceptableAnswers,
      'allowedLanguages': allowedLanguages,
      'judgeCases': judgeCases.map((item) => item.toJson()).toList(),
      'score': score,
      'sortOrder': sortOrder,
    };
  }

  PracticeQuestionBankItem copyWith({
    int? id,
    int? bankQuestionId,
    String? questionType,
    String? trackCode,
    String? title,
    String? content,
    String? difficulty,
    String? inputFormat,
    String? outputFormat,
    String? sampleInput,
    String? sampleOutput,
    List<String>? tags,
    String? analysisHint,
    List<PracticeQuestionOption>? options,
    String? correctAnswer,
    List<String>? acceptableAnswers,
    List<String>? allowedLanguages,
    List<PracticeJudgeCase>? judgeCases,
    int? score,
    int? sortOrder,
  }) {
    return PracticeQuestionBankItem(
      id: id ?? this.id,
      bankQuestionId: bankQuestionId ?? this.bankQuestionId,
      questionType: questionType ?? this.questionType,
      trackCode: trackCode ?? this.trackCode,
      title: title ?? this.title,
      content: content ?? this.content,
      difficulty: difficulty ?? this.difficulty,
      inputFormat: inputFormat ?? this.inputFormat,
      outputFormat: outputFormat ?? this.outputFormat,
      sampleInput: sampleInput ?? this.sampleInput,
      sampleOutput: sampleOutput ?? this.sampleOutput,
      tags: tags ?? this.tags,
      analysisHint: analysisHint ?? this.analysisHint,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      acceptableAnswers: acceptableAnswers ?? this.acceptableAnswers,
      allowedLanguages: allowedLanguages ?? this.allowedLanguages,
      judgeCases: judgeCases ?? this.judgeCases,
      score: score ?? this.score,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static Map<String, String?> _parseSampleCase(dynamic value) {
    if (value is Map) {
      return <String, String?>{
        'input': value['input']?.toString(),
        'output': value['output']?.toString(),
      };
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return <String, String?>{
            'input': decoded['input']?.toString(),
            'output': decoded['output']?.toString(),
          };
        }
      } catch (_) {}
    }
    return const <String, String?>{'input': null, 'output': null};
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    return const <String>[];
  }

  static List<PracticeQuestionOption> _readOptions(dynamic value) {
    if (value is! List) {
      return const <PracticeQuestionOption>[];
    }
    return value
        .whereType<Map>()
        .map(
          (Map item) =>
              PracticeQuestionOption.fromJson(item.cast<String, dynamic>()),
        )
        .toList();
  }

  static List<PracticeJudgeCase> _readJudgeCases(dynamic value) {
    if (value is! List) {
      return const <PracticeJudgeCase>[];
    }
    return value
        .whereType<Map>()
        .map((Map item) => PracticeJudgeCase.fromJson(item.cast<String, dynamic>()))
        .toList();
  }
}
