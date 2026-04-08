import 'dart:convert';

class GradPathQuestionOption {
  GradPathQuestionOption({required this.label, required this.text});

  final String label;
  final String text;

  factory GradPathQuestionOption.fromJson(Map<String, dynamic> json) {
    return GradPathQuestionOption(
      label: json['label']?.toString() ?? '',
      text: json['text']?.toString() ?? json['content']?.toString() ?? '',
    );
  }
}

class GradPathQuestion {
  GradPathQuestion({
    required this.id,
    required this.questionType,
    required this.trackCode,
    required this.title,
    required this.content,
    required this.difficulty,
    required this.tags,
    required this.analysisHint,
    required this.inputFormat,
    required this.outputFormat,
    required this.sampleInput,
    required this.sampleOutput,
    required this.allowedLanguages,
    required this.options,
  });

  final int id;
  final String questionType;
  final String trackCode;
  final String title;
  final String content;
  final String? difficulty;
  final List<String> tags;
  final String? analysisHint;
  final String? inputFormat;
  final String? outputFormat;
  final String? sampleInput;
  final String? sampleOutput;
  final List<String> allowedLanguages;
  final List<GradPathQuestionOption> options;

  bool get isProgramming => questionType == 'programming';
  bool get isSingleChoice => questionType == 'single_choice';
  bool get isFillBlank => questionType == 'fill_blank';

  factory GradPathQuestion.fromJson(Map<String, dynamic> json) {
    final sampleCase = _parseSampleCase(json['sampleCase']);
    return GradPathQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      questionType: json['questionType']?.toString() ?? 'programming',
      trackCode: json['trackCode']?.toString() ?? 'backend',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      difficulty: json['difficulty']?.toString(),
      tags: _readStringList(json['tags']),
      analysisHint: json['analysisHint']?.toString(),
      inputFormat: json['inputFormat']?.toString(),
      outputFormat: json['outputFormat']?.toString(),
      sampleInput: sampleCase['input'],
      sampleOutput: sampleCase['output'],
      allowedLanguages: _readStringList(json['allowedLanguages']),
      options: _readOptions(json['options']),
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
      } catch (_) {
        return <String, String?>{'input': value, 'output': null};
      }
    }

    return const <String, String?>{'input': null, 'output': null};
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    return const <String>[];
  }

  static List<GradPathQuestionOption> _readOptions(dynamic value) {
    if (value is! List) {
      return const <GradPathQuestionOption>[];
    }
    return value
        .whereType<Map>()
        .map(
          (Map item) =>
              GradPathQuestionOption.fromJson(item.cast<String, dynamic>()),
        )
        .toList();
  }
}
