import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/practice_question_bank_item.dart';
import '../../models/written_exam_lab.dart';
import '../../models/written_exam_models.dart';
import '../../repositories/written_exam_repository.dart';
import 'written_exam_controller.dart';

class WrittenExamPage extends StatefulWidget {
  const WrittenExamPage({super.key, this.labId});

  final int? labId;

  @override
  State<WrittenExamPage> createState() => _WrittenExamPageState();
}

class _WrittenExamPageState extends State<WrittenExamPage> {
  late final WrittenExamController _controller;
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = WrittenExamController(context.read<WrittenExamRepository>());
    _loadByMode();
  }

  @override
  void didUpdateWidget(covariant WrittenExamPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labId != widget.labId) {
      _loadByMode();
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _loadByMode() {
    if (widget.labId == null) {
      _controller.loadHub();
    } else {
      _controller.loadSession(widget.labId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        if (widget.labId == null) {
          return _buildHub(context);
        }
        return _buildSession(context);
      },
    );
  }

  Widget _buildHub(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('笔试中心')),
      body: ResponsiveListView(
        onRefresh: _controller.refreshHub,
        children: <Widget>[
          const _WrittenExamHero(
            title: '正式笔试工作台',
            subtitle: '统一查看各实验室笔试通知、开放状态和当前作答结果。',
          ),
          const SizedBox(height: 16),
          if ((_controller.errorMessage ?? '').isNotEmpty) ...<Widget>[
            PanelCard(
              child: Text(
                _controller.errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_controller.notifications.isNotEmpty) ...<Widget>[
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '笔试通知',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12223A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._controller.notifications.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.read
                              ? const Color(0xFFF8FBFF)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.read
                                ? const Color(0xFFDCE6F5)
                                : const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF12223A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.content,
                                    style: const TextStyle(
                                      height: 1.65,
                                      color: Color(0xFF516074),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateTimeFormatter.dateTime(item.createTime),
                                    style: const TextStyle(
                                      color: Color(0xFF8792A6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!item.read) ...<Widget>[
                              const SizedBox(width: 12),
                              FilledButton.tonal(
                                onPressed: () =>
                                    _controller.markNotificationRead(item.id),
                                child: const Text('知道了'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  '查找笔试',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '按实验室名称查找当前开放或已参加过的正式笔试。',
                  style: TextStyle(height: 1.65, color: Color(0xFF6D7B92)),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final compact = constraints.maxWidth < 720;
                    final searchField = TextField(
                      controller: _keywordController,
                      decoration: const InputDecoration(
                        labelText: '搜索实验室',
                        hintText: '按实验室名称查找笔试',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: _controller.updateKeyword,
                      onSubmitted: (_) => _controller.searchLabs(),
                    );
                    if (compact) {
                      return Column(
                        children: <Widget>[
                          searchField,
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: _controller.searchLabs,
                              child: const Text('搜索'),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: <Widget>[
                        Expanded(child: searchField),
                        const SizedBox(width: 12),
                        FilledButton.tonal(
                          onPressed: _controller.searchLabs,
                          child: const Text('搜索'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_controller.loadingHub && _controller.labs.isEmpty)
            const PanelCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_controller.labs.isEmpty)
            const PanelCard(
              child: EmptyState(
                icon: Icons.quiz_outlined,
                title: '当前没有可查看的笔试',
                message: '可先浏览实验室招新，已配置笔试的实验室会显示在这里。',
              ),
            )
          else
            ..._controller.labs.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _WrittenExamLabCard(item: item),
              ),
            ),
          if (_controller.labs.isNotEmpty)
            PanelCard(
              child: Row(
                children: <Widget>[
                  OutlinedButton(
                    onPressed: _controller.pageNum > 1
                        ? _controller.previousPage
                        : null,
                    child: const Text('上一页'),
                  ),
                  const Spacer(),
                  Text(
                    '${_controller.pageNum} / ${_controller.totalPages == 0 ? 1 : _controller.totalPages} · 共 ${_controller.total} 条',
                    style: const TextStyle(color: Color(0xFF516074)),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: _controller.pageNum < _controller.totalPages
                        ? _controller.nextPage
                        : null,
                    child: const Text('下一页'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final session = _controller.session;
    final submission = session?.submission;

    return Scaffold(
      appBar: AppBar(title: const Text('正式笔试')),
      body: ResponsiveListView(
        onRefresh: _controller.refreshSession,
        children: <Widget>[
          _WrittenExamHero(
            title: session?.labName ?? '正式笔试',
            subtitle: session?.examTitle ?? '查看题目、完成作答并提交本场笔试。',
          ),
          const SizedBox(height: 16),
          if ((_controller.errorMessage ?? '').isNotEmpty) ...<Widget>[
            PanelCard(
              child: Text(
                _controller.errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_controller.loadingSession && session == null)
            const PanelCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (session == null)
            const PanelCard(
              child: EmptyState(
                icon: Icons.assignment_late_outlined,
                title: '暂时无法打开这场笔试',
                message: '请稍后重试，或返回笔试中心查看其他实验室安排。',
              ),
            )
          else ...<Widget>[
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '考试信息',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12223A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _ExamMetaChip(
                        label: '题目数量',
                        value: '${session.questions.length} 题',
                      ),
                      _ExamMetaChip(
                        label: '通过分数',
                        value: '${session.passScore ?? '-'} 分',
                      ),
                      _ExamMetaChip(
                        label: '当前状态',
                        value: submission == null
                            ? '未提交'
                            : _submissionStatusText(submission.status),
                      ),
                    ],
                  ),
                  if ((session.examDescription ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(
                      session.examDescription!,
                      style: const TextStyle(
                        height: 1.7,
                        color: Color(0xFF516074),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (session.environmentStatus.isNotEmpty)
              PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '判题环境',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: session.environmentStatus.entries
                          .map(
                            (entry) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: entry.value
                                    ? const Color(0xFFE8FFF2)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_languageLabel(entry.key)} ${entry.value ? '可用' : '未就绪'}',
                                style: TextStyle(
                                  color: entry.value
                                      ? const Color(0xFF0F9D58)
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
            if (session.environmentStatus.isNotEmpty)
              const SizedBox(height: 16),
            if (submission != null)
              _SubmittedSummaryCard(
                submission: submission,
                passScore: session.passScore,
              ),
            if (submission != null) const SizedBox(height: 16),
            ...session.questions.map(
              (question) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _QuestionCard(
                  question: question,
                  draft: _controller.drafts[question.id],
                  readonly: session.alreadySubmitted,
                  answerRecord: _findAnswerRecord(submission, question.id),
                  onChoiceSelected: (value) =>
                      _controller.updateObjectiveAnswer(question.id, value),
                  onTextChanged: (value) =>
                      _controller.updateTextAnswer(question.id, value),
                  onLanguageChanged: (value) =>
                      _controller.updateLanguage(question.id, value),
                  onResetTemplate: () =>
                      _controller.resetCodeTemplate(question.id),
                  onCodeChanged: (value) =>
                      _controller.updateCode(question.id, value),
                ),
              ),
            ),
            if (!session.alreadySubmitted)
              PanelCard(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _controller.submitting
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = await _controller.submit();
                            if (!mounted || !ok) {
                              return;
                            }
                            messenger.showSnackBar(
                              const SnackBar(content: Text('笔试已提交')),
                            );
                          },
                    child: _controller.submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('提交本场笔试'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  WrittenExamAnswerRecord? _findAnswerRecord(
    WrittenExamSubmissionRecord? submission,
    int questionId,
  ) {
    if (submission == null) {
      return null;
    }
    for (final item in submission.answerSheet) {
      if (item.questionId == questionId) {
        return item;
      }
    }
    return null;
  }
}

class _WrittenExamHero extends StatelessWidget {
  const _WrittenExamHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0B4560), Color(0xFF2F76FF)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 106,
              height: 106,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(34),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '正式笔试',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.65,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WrittenExamLabCard extends StatelessWidget {
  const _WrittenExamLabCard({required this.item});

  final WrittenExamLab item;

  @override
  Widget build(BuildContext context) {
    final chipColor = switch (item.myExamStatus) {
      2 => const Color(0xFF0F9D58),
      3 => const Color(0xFFE53935),
      1 => const Color(0xFF2F76FF),
      _ => const Color(0xFFF59E0B),
    };

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 58,
            height: 4,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.labName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.writtenExamTitle ?? '当前实验室未设置独立笔试标题',
                      style: const TextStyle(
                        color: Color(0xFF516074),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(
                    color: chipColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if ((item.labDesc ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              item.labDesc!,
              style: const TextStyle(height: 1.65, color: Color(0xFF6D7B92)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _ExamMetaTag(
                label: '窗口',
                value:
                    '${DateTimeFormatter.dateTime(item.writtenExamStartTime)} - ${DateTimeFormatter.dateTime(item.writtenExamEndTime)}',
              ),
              _ExamMetaTag(
                label: '通过线',
                value: item.writtenExamPassScore == null
                    ? '-'
                    : '${item.writtenExamPassScore} 分',
              ),
              _ExamMetaTag(
                label: '当前得分',
                value: item.myExamScore == null ? '-' : '${item.myExamScore} 分',
              ),
            ],
          ),
          if ((item.interviewLockedReason ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                item.interviewLockedReason!,
                style: const TextStyle(height: 1.6, color: Color(0xFF516074)),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonal(
                onPressed: item.hasWrittenExam
                    ? () => context.push('/student/written-exams/${item.id}')
                    : null,
                child: Text(item.canTakeWrittenExam ? '进入笔试' : '查看笔试'),
              ),
              if (item.canDeliver)
                const _StatusPill(
                  text: '已满足投递条件',
                  color: Color(0xFF0F9D58),
                  background: Color(0xFFE8FFF2),
                ),
              if (item.hasWrittenExam && item.writtenExamOpen)
                _StatusPill(
                  text: item.writtenExamWithinWindow ? '当前开放中' : '不在考试时段',
                  color: item.writtenExamWithinWindow
                      ? const Color(0xFF2F76FF)
                      : const Color(0xFFB45309),
                  background: item.writtenExamWithinWindow
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFFEF3C7),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmittedSummaryCard extends StatelessWidget {
  const _SubmittedSummaryCard({
    required this.submission,
    required this.passScore,
  });

  final WrittenExamSubmissionRecord submission;
  final int? passScore;

  @override
  Widget build(BuildContext context) {
    final passed = submission.status == 2;
    final failed = submission.status == 3;

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  passed
                      ? '笔试已通过'
                      : failed
                      ? '笔试未通过'
                      : '笔试已提交',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
                ),
              ),
              _StatusPill(
                text: _submissionStatusText(submission.status),
                color: passed
                    ? const Color(0xFF0F9D58)
                    : failed
                    ? const Color(0xFFE53935)
                    : const Color(0xFF2F76FF),
                background: passed
                    ? const Color(0xFFE8FFF2)
                    : failed
                    ? const Color(0xFFFEEAEA)
                    : const Color(0xFFEFF6FF),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              Text(
                '总分 ${submission.totalScore ?? '-'}',
                style: const TextStyle(
                  color: Color(0xFF2F76FF),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '通过线 ${passScore ?? '-'}',
                style: const TextStyle(color: Color(0xFF516074)),
              ),
              Text(
                '提交时间 ${DateTimeFormatter.dateTime(submission.submitTime)}',
                style: const TextStyle(color: Color(0xFF8792A6)),
              ),
            ],
          ),
          if ((submission.aiRemark ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              submission.aiRemark!,
              style: const TextStyle(height: 1.65, color: Color(0xFF516074)),
            ),
          ],
          if ((submission.adminRemark ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '审核说明：${submission.adminRemark}',
                style: const TextStyle(height: 1.6, color: Color(0xFF516074)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.draft,
    required this.readonly,
    required this.onChoiceSelected,
    required this.onTextChanged,
    required this.onLanguageChanged,
    required this.onResetTemplate,
    required this.onCodeChanged,
    this.answerRecord,
  });

  final PracticeQuestionBankItem question;
  final WrittenExamAnswerDraft? draft;
  final bool readonly;
  final WrittenExamAnswerRecord? answerRecord;
  final ValueChanged<String> onChoiceSelected;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onResetTemplate;
  final ValueChanged<String> onCodeChanged;

  @override
  Widget build(BuildContext context) {
    final currentDraft = draft ?? WrittenExamAnswerDraft.fromQuestion(question);
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  question.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  _ExamMetaTag(
                    label: '题型',
                    value: _questionTypeText(question.questionType),
                  ),
                  if ((question.difficulty ?? '').isNotEmpty)
                    _ExamMetaTag(label: '难度', value: question.difficulty!),
                  if (question.score != null)
                    _ExamMetaTag(label: '分值', value: '${question.score} 分'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.content ?? '暂无题目描述',
            style: const TextStyle(height: 1.7, color: Color(0xFF516074)),
          ),
          if (question.isProgramming) ...<Widget>[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final compact = constraints.maxWidth < 720;
                final inputCard = _QuestionInfoCard(
                  title: '输入格式',
                  content: question.inputFormat ?? '-',
                );
                final outputCard = _QuestionInfoCard(
                  title: '输出格式',
                  content: question.outputFormat ?? '-',
                );
                if (compact) {
                  return Column(
                    children: <Widget>[
                      inputCard,
                      const SizedBox(height: 10),
                      outputCard,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: inputCard),
                    const SizedBox(width: 10),
                    Expanded(child: outputCard),
                  ],
                );
              },
            ),
            if ((question.sampleInput ?? '').isNotEmpty ||
                (question.sampleOutput ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final compact = constraints.maxWidth < 720;
                  final sampleIn = _QuestionInfoCard(
                    title: '样例输入',
                    content: question.sampleInput ?? '-',
                  );
                  final sampleOut = _QuestionInfoCard(
                    title: '样例输出',
                    content: question.sampleOutput ?? '-',
                  );
                  if (compact) {
                    return Column(
                      children: <Widget>[
                        sampleIn,
                        const SizedBox(height: 10),
                        sampleOut,
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      Expanded(child: sampleIn),
                      const SizedBox(width: 10),
                      Expanded(child: sampleOut),
                    ],
                  );
                },
              ),
            ],
          ],
          if ((question.analysisHint ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                question.analysisHint!,
                style: const TextStyle(height: 1.6, color: Color(0xFF516074)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            readonly ? '你的答案' : '作答区',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          const SizedBox(height: 12),
          if (question.isSingleChoice)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: question.options
                  .map(
                    (option) => ChoiceChip(
                      label: Text('${option.label}. ${option.text}'),
                      selected: currentDraft.answer == option.label,
                      onSelected: readonly
                          ? null
                          : (_) => onChoiceSelected(option.label),
                    ),
                  )
                  .toList(growable: false),
            ),
          if (question.isFillBlank)
            TextFormField(
              key: ValueKey<String>(
                'fill-${question.id}-${readonly ? currentDraft.answer : question.title}',
              ),
              initialValue: currentDraft.answer,
              enabled: !readonly,
              decoration: const InputDecoration(
                labelText: '答案',
                hintText: '请输入你的答案',
              ),
              onChanged: onTextChanged,
            ),
          if (question.isProgramming) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: currentDraft.language,
                    decoration: const InputDecoration(labelText: '语言'),
                    items: question.allowedLanguages
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(_languageLabel(item)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: readonly
                        ? null
                        : (value) {
                            if (value != null) {
                              onLanguageChanged(value);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: readonly ? null : onResetTemplate,
                  child: const Text('重置模板'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey<String>(
                'code-${question.id}-${currentDraft.language}-${readonly ? 'readonly' : 'editing'}',
              ),
              initialValue: currentDraft.code,
              enabled: !readonly,
              minLines: 10,
              maxLines: 16,
              decoration: const InputDecoration(
                labelText: '代码',
                alignLabelWithHint: true,
              ),
              onChanged: onCodeChanged,
            ),
          ],
          if (answerRecord != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: <Widget>[
                      Text(
                        '得分 ${answerRecord!.score ?? '-'} / ${answerRecord!.fullScore ?? '-'}',
                        style: const TextStyle(
                          color: Color(0xFF2F76FF),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((answerRecord!.language ?? '').isNotEmpty)
                        Text(
                          '语言 ${_languageLabel(answerRecord!.language!)}',
                          style: const TextStyle(color: Color(0xFF516074)),
                        ),
                    ],
                  ),
                  if ((answerRecord!.resultMessage ?? '')
                      .isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      answerRecord!.resultMessage!,
                      style: const TextStyle(
                        height: 1.6,
                        color: Color(0xFF516074),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionInfoCard extends StatelessWidget {
  const _QuestionInfoCard({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            content,
            style: const TextStyle(height: 1.6, color: Color(0xFF516074)),
          ),
        ],
      ),
    );
  }
}

class _ExamMetaChip extends StatelessWidget {
  const _ExamMetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label ',
          style: const TextStyle(color: Color(0xFF8792A6), fontSize: 13),
          children: <InlineSpan>[
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF12223A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamMetaTag extends StatelessWidget {
  const _ExamMetaTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label · $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6D7B92),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _submissionStatusText(int status) {
  switch (status) {
    case 2:
      return '已通过';
    case 3:
      return '未通过';
    default:
      return '待审核';
  }
}

String _questionTypeText(String type) {
  switch (type) {
    case 'single_choice':
      return '单选题';
    case 'fill_blank':
      return '填空题';
    case 'programming':
      return '编程题';
    default:
      return type;
  }
}

String _languageLabel(String language) {
  switch (language) {
    case 'cpp':
      return 'C++';
    case 'c':
      return 'C';
    case 'python':
      return 'Python';
    case 'java':
      return 'Java';
    default:
      return language;
  }
}
