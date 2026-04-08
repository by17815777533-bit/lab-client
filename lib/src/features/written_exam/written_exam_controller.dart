import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/paged_result.dart';
import '../../models/practice_question_bank_item.dart';
import '../../models/written_exam_lab.dart';
import '../../models/written_exam_models.dart';
import '../../models/written_exam_notification.dart';
import '../../repositories/written_exam_repository.dart';

class WrittenExamAnswerDraft {
  WrittenExamAnswerDraft({
    required this.questionId,
    required this.questionType,
    required this.answer,
    required this.language,
    required this.code,
  });

  final int questionId;
  final String questionType;
  String answer;
  String language;
  String code;

  factory WrittenExamAnswerDraft.fromQuestion(
    PracticeQuestionBankItem question,
  ) {
    final defaultLanguage = question.allowedLanguages.isNotEmpty
        ? question.allowedLanguages.first
        : 'java';
    return WrittenExamAnswerDraft(
      questionId: question.id,
      questionType: question.questionType,
      answer: '',
      language: defaultLanguage,
      code: question.isProgramming ? _templateFor(defaultLanguage) : '',
    );
  }

  factory WrittenExamAnswerDraft.fromSubmission({
    required PracticeQuestionBankItem question,
    required WrittenExamAnswerRecord answerRecord,
  }) {
    final defaultLanguage = question.allowedLanguages.isNotEmpty
        ? question.allowedLanguages.first
        : 'java';
    return WrittenExamAnswerDraft(
      questionId: question.id,
      questionType: question.questionType,
      answer: answerRecord.answer ?? '',
      language: answerRecord.language ?? defaultLanguage,
      code: answerRecord.code ?? '',
    );
  }

  static String _templateFor(String language) {
    switch (language) {
      case 'python':
        return 'import sys\n\n# 在这里开始编写你的代码\n';
      case 'c':
        return '#include <stdio.h>\n\nint main(void) {\n  // 在这里开始编写你的代码\n  return 0;\n}\n';
      case 'cpp':
        return '#include <bits/stdc++.h>\nusing namespace std;\n\nint main() {\n  // 在这里开始编写你的代码\n  return 0;\n}\n';
      case 'java':
      default:
        return 'import java.util.*;\n\npublic class Main {\n  public static void main(String[] args) {\n    Scanner scanner = new Scanner(System.in);\n    // 在这里开始编写你的代码\n  }\n}\n';
    }
  }
}

class WrittenExamController extends ChangeNotifier {
  WrittenExamController(this._repository);

  final WrittenExamRepository _repository;

  bool _loadingHub = false;
  bool _loadingSession = false;
  bool _submitting = false;
  String? _errorMessage;
  List<WrittenExamNotification> _notifications =
      const <WrittenExamNotification>[];
  PagedResult<WrittenExamLab>? _labsPage;
  int _pageNum = 1;
  final int _pageSize = 6;
  String _keyword = '';
  WrittenExamSessionData? _session;
  int? _labId;
  final Map<int, WrittenExamAnswerDraft> _drafts =
      <int, WrittenExamAnswerDraft>{};

  bool get loadingHub => _loadingHub;
  bool get loadingSession => _loadingSession;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  List<WrittenExamNotification> get notifications => _notifications;
  List<WrittenExamLab> get labs => _labsPage?.records ?? <WrittenExamLab>[];
  int get pageNum => _pageNum;
  int get totalPages => _labsPage?.pages ?? 0;
  int get total => _labsPage?.total ?? 0;
  String get keyword => _keyword;
  WrittenExamSessionData? get session => _session;
  int? get labId => _labId;
  Map<int, WrittenExamAnswerDraft> get drafts =>
      Map<int, WrittenExamAnswerDraft>.unmodifiable(_drafts);

  Future<void> loadHub() async {
    _loadingHub = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _repository.fetchNotifications(),
        _repository.fetchLabs(
          pageNum: _pageNum,
          pageSize: _pageSize,
          labName: _keyword.trim().isEmpty ? null : _keyword.trim(),
        ),
      ]);
      _notifications = results[0] as List<WrittenExamNotification>;
      _labsPage = results[1] as PagedResult<WrittenExamLab>;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '笔试中心加载失败，请稍后重试';
    } finally {
      _loadingHub = false;
      notifyListeners();
    }
  }

  Future<void> refreshHub() => loadHub();

  Future<void> loadSession(int labId) async {
    _labId = labId;
    _loadingSession = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await _repository.fetchStudentExam(labId);
      _hydrateDrafts();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '笔试内容加载失败，请稍后重试';
    } finally {
      _loadingSession = false;
      notifyListeners();
    }
  }

  Future<void> refreshSession() async {
    final currentLabId = _labId;
    if (currentLabId == null) {
      return;
    }
    await loadSession(currentLabId);
  }

  void updateKeyword(String value) {
    _keyword = value;
  }

  Future<void> searchLabs() async {
    _pageNum = 1;
    await loadHub();
  }

  Future<void> previousPage() async {
    if (_pageNum <= 1) {
      return;
    }
    _pageNum -= 1;
    await loadHub();
  }

  Future<void> nextPage() async {
    if (_labsPage == null || _pageNum >= _labsPage!.pages) {
      return;
    }
    _pageNum += 1;
    await loadHub();
  }

  Future<void> markNotificationRead(int id) async {
    try {
      await _repository.markNotificationRead(id);
      _notifications = _notifications
          .map(
            (item) => item.id == id
                ? WrittenExamNotification(
                    id: item.id,
                    title: item.title,
                    content: item.content,
                    read: true,
                    createTime: item.createTime,
                  )
                : item,
          )
          .toList(growable: false);
      notifyListeners();
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _errorMessage = '通知状态更新失败，请稍后重试';
      notifyListeners();
    }
  }

  void updateObjectiveAnswer(int questionId, String value) {
    final draft = _drafts[questionId];
    if (draft == null) {
      return;
    }
    draft.answer = value;
    notifyListeners();
  }

  void updateTextAnswer(int questionId, String value) {
    final draft = _drafts[questionId];
    if (draft == null) {
      return;
    }
    draft.answer = value;
  }

  void updateLanguage(int questionId, String value) {
    final draft = _drafts[questionId];
    if (draft == null) {
      return;
    }
    draft.language = value;
    if (draft.code.trim().isEmpty) {
      draft.code = WrittenExamAnswerDraft._templateFor(value);
    }
    notifyListeners();
  }

  void resetCodeTemplate(int questionId) {
    final draft = _drafts[questionId];
    if (draft == null) {
      return;
    }
    draft.code = WrittenExamAnswerDraft._templateFor(draft.language);
    notifyListeners();
  }

  void updateCode(int questionId, String value) {
    final draft = _drafts[questionId];
    if (draft == null) {
      return;
    }
    draft.code = value;
  }

  Future<bool> submit() async {
    final session = _session;
    final labId = _labId;
    if (session == null || labId == null) {
      _errorMessage = '当前没有可提交的笔试内容';
      notifyListeners();
      return false;
    }

    for (final question in session.questions) {
      final draft = _drafts[question.id];
      if (draft == null) {
        _errorMessage = '有题目尚未准备完成，请刷新后重试';
        notifyListeners();
        return false;
      }
      if (question.isProgramming) {
        if (draft.code.trim().isEmpty) {
          _errorMessage = '请先完成《${question.title}》的代码作答';
          notifyListeners();
          return false;
        }
      } else if (draft.answer.trim().isEmpty) {
        _errorMessage = '请先完成《${question.title}》的作答';
        notifyListeners();
        return false;
      }
    }

    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final submission = await _repository.submitStudentExam(
        labId: labId,
        answers: session.questions
            .map((question) {
              final draft = _drafts[question.id]!;
              return <String, dynamic>{
                'questionId': question.id,
                'answer': question.isProgramming ? null : draft.answer.trim(),
                'language': question.isProgramming ? draft.language : null,
                'code': question.isProgramming ? draft.code : null,
              };
            })
            .toList(growable: false),
      );

      _session = WrittenExamSessionData(
        labName: session.labName,
        examTitle: session.examTitle,
        examDescription: session.examDescription,
        passScore: session.passScore,
        alreadySubmitted: true,
        questions: session.questions,
        submission: submission,
        environmentStatus: session.environmentStatus,
      );
      _hydrateDrafts();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '笔试提交失败，请稍后重试';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void _hydrateDrafts() {
    final session = _session;
    if (session == null) {
      return;
    }

    final answerSheet = <int, WrittenExamAnswerRecord>{};
    for (final item
        in session.submission?.answerSheet ??
            const <WrittenExamAnswerRecord>[]) {
      if (item.questionId != null) {
        answerSheet[item.questionId!] = item;
      }
    }

    _drafts
      ..clear()
      ..addEntries(
        session.questions.map((question) {
          final record = answerSheet[question.id];
          final draft = record == null
              ? WrittenExamAnswerDraft.fromQuestion(question)
              : WrittenExamAnswerDraft.fromSubmission(
                  question: question,
                  answerRecord: record,
                );
          return MapEntry<int, WrittenExamAnswerDraft>(question.id, draft);
        }),
      );
  }
}
