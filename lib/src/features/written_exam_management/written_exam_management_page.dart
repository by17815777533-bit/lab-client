import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../features/gradpath/gradpath_catalog.dart';
import '../../models/paged_result.dart';
import '../../models/practice_question_bank_item.dart';
import '../../models/written_exam_models.dart';
import '../../repositories/growth_center_repository.dart';
import '../../repositories/written_exam_repository.dart';
import 'written_exam_management_controller.dart';

class WrittenExamManagementPage extends StatefulWidget {
  const WrittenExamManagementPage({super.key});

  @override
  State<WrittenExamManagementPage> createState() =>
      _WrittenExamManagementPageState();
}

class _WrittenExamManagementPageState extends State<WrittenExamManagementPage> {
  late final WrittenExamManagementController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _passScoreController = TextEditingController();
  final TextEditingController _submissionKeywordController =
      TextEditingController();
  bool _recruitmentOpen = false;
  String? _hydratedRevision;

  @override
  void initState() {
    super.initState();
    _controller = WrittenExamManagementController(
      context.read<WrittenExamRepository>(),
    )..load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _passScoreController.dispose();
    _submissionKeywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({
    required TextEditingController controller,
    required DateTime? initialValue,
  }) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialValue ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue ?? now),
    );
    if (time == null) {
      return;
    }
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    controller.text = _formatServerDateTime(value);
    setState(() {});
  }

  Future<void> _openQuestionSelector() async {
    final selected = await showModalBottomSheet<List<PracticeQuestionBankItem>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _QuestionSelectorSheet(
          repository: context.read<GrowthCenterRepository>(),
          initialSelectedKeys: _controller.questions
              .map((item) => item.bankQuestionId ?? item.id)
              .toSet(),
        );
      },
    );
    if (selected == null || selected.isEmpty) {
      return;
    }
    _controller.addQuestions(selected);
  }

  Future<void> _reviewSubmission(
    WrittenExamSubmissionRecord record,
    int status,
  ) async {
    final remarkController = TextEditingController(
      text: record.adminRemark ?? '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(status == 2 ? '通过答卷' : '标记未通过'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${record.realName ?? '该学生'} 的答卷将被${status == 2 ? '标记为通过' : '标记为未通过'}。',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '审核说明',
                  hintText: '可选填写，学生会在结果页看到这段说明',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      remarkController.dispose();
      return;
    }
    final ok = await _controller.reviewSubmission(
      submissionId: record.id,
      status: status,
      adminRemark: remarkController.text.trim(),
    );
    remarkController.dispose();
    if (!mounted || !ok) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('审核结果已更新')));
  }

  void _showSubmissionDetail(WrittenExamSubmissionRecord record) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    record.realName ?? '笔试答卷',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12223A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '总分 ${record.totalScore ?? '-'} · ${_submissionStatusText(record.status)} · ${DateTimeFormatter.dateTime(record.submitTime)}',
                    style: const TextStyle(color: Color(0xFF516074)),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: record.answerSheet
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FBFF),
                                  borderRadius: BorderRadius.circular(18),
                                ),
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
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        _TinyTag(
                                          text:
                                              '得分 ${item.score ?? '-'} / ${item.fullScore ?? '-'}',
                                        ),
                                        if ((item.questionType ?? '')
                                            .isNotEmpty)
                                          _TinyTag(
                                            text: _questionTypeText(
                                              item.questionType!,
                                            ),
                                          ),
                                        if ((item.language ?? '').isNotEmpty)
                                          _TinyTag(
                                            text: _languageLabel(
                                              item.language!,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if ((item.answer ?? '')
                                        .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 10),
                                      SelectableText(
                                        '答案：${item.answer}',
                                        style: const TextStyle(
                                          height: 1.6,
                                          color: Color(0xFF516074),
                                        ),
                                      ),
                                    ],
                                    if ((item.code ?? '')
                                        .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: SelectableText(
                                          item.code!,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            height: 1.55,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if ((item.resultMessage ?? '')
                                        .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 10),
                                      Text(
                                        item.resultMessage!,
                                        style: const TextStyle(
                                          height: 1.6,
                                          color: Color(0xFF516074),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('关闭'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveConfig() async {
    final title = _titleController.text.trim();
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();
    final passScore = int.tryParse(_passScoreController.text.trim()) ?? 60;

    if (title.isEmpty || startTime.isEmpty || endTime.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先补全标题和考试时间')));
      return;
    }
    if (_controller.questions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先从共享题库中选择至少一道题目')));
      return;
    }

    final ok = await _controller.saveConfig(
      recruitmentOpen: _recruitmentOpen,
      title: title,
      description: _descriptionController.text.trim(),
      startTime: startTime,
      endTime: endTime,
      passScore: passScore,
    );
    if (!mounted || !ok) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('正式笔试配置已保存')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        _syncFormIfNeeded();

        return Scaffold(
          appBar: AppBar(
            title: const Text('正式笔试管理'),
            actions: <Widget>[
              IconButton(
                tooltip: '刷新',
                onPressed: _controller.loading ? null : _controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: ResponsiveListView(
            onRefresh: _controller.refresh,
            children: <Widget>[
              const _HeroBanner(),
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
              if (_controller.loading && _controller.config == null)
                const PanelCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else ...<Widget>[
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '基础配置',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF12223A),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '维护考试时间、开放状态和共享题目快照。',
                                  style: TextStyle(color: Color(0xFF6D7B92)),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                context.push('/admin/growth-question-bank'),
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('共享题库'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('开放招新'),
                        subtitle: const Text('关闭后，学生不能进入这场正式笔试'),
                        value: _recruitmentOpen,
                        onChanged: (value) =>
                            setState(() => _recruitmentOpen = value),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '笔试标题',
                          hintText: '例如：2026 春季实验室正式笔试',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: '笔试说明',
                          hintText: '说明作答规则、注意事项和考试要求',
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                              final compact = constraints.maxWidth < 720;
                              final startField = TextField(
                                controller: _startTimeController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: '开始时间',
                                  suffixIcon: Icon(Icons.schedule_rounded),
                                ),
                                onTap: () => _pickDateTime(
                                  controller: _startTimeController,
                                  initialValue: DateTimeFormatter.tryParse(
                                    _startTimeController.text,
                                  ),
                                ),
                              );
                              final endField = TextField(
                                controller: _endTimeController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: '结束时间',
                                  suffixIcon: Icon(Icons.schedule_rounded),
                                ),
                                onTap: () => _pickDateTime(
                                  controller: _endTimeController,
                                  initialValue: DateTimeFormatter.tryParse(
                                    _endTimeController.text,
                                  ),
                                ),
                              );
                              final passScoreField = TextField(
                                controller: _passScoreController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '通过分数',
                                ),
                              );
                              if (compact) {
                                return Column(
                                  children: <Widget>[
                                    startField,
                                    const SizedBox(height: 12),
                                    endField,
                                    const SizedBox(height: 12),
                                    passScoreField,
                                  ],
                                );
                              }
                              return Row(
                                children: <Widget>[
                                  Expanded(child: startField),
                                  const SizedBox(width: 12),
                                  Expanded(child: endField),
                                  const SizedBox(width: 12),
                                  SizedBox(width: 160, child: passScoreField),
                                ],
                              );
                            },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _controller.saving ? null : _saveConfig,
                          child: _controller.saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('保存笔试配置'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_controller.config?.environmentDetails.isNotEmpty == true)
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
                          spacing: 12,
                          runSpacing: 12,
                          children: _controller.config!.environmentDetails
                              .map(
                                (item) => SizedBox(
                                  width: 280,
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: item.available
                                          ? const Color(0xFFEFF8FF)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: item.available
                                            ? const Color(0xFFBFDBFE)
                                            : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                item.label ?? item.key,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF12223A),
                                                ),
                                              ),
                                            ),
                                            _TinyTag(
                                              text: item.available
                                                  ? '已就绪'
                                                  : '未就绪',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '配置命令：${item.configuredCommand ?? '-'}',
                                          style: const TextStyle(
                                            color: Color(0xFF516074),
                                            height: 1.55,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '解析命令：${item.resolvedCommand ?? '-'}',
                                          style: const TextStyle(
                                            color: Color(0xFF516074),
                                            height: 1.55,
                                          ),
                                        ),
                                        if ((item.message ?? '')
                                            .isNotEmpty) ...<Widget>[
                                          const SizedBox(height: 8),
                                          Text(
                                            item.message!,
                                            style: const TextStyle(
                                              color: Color(0xFF6D7B92),
                                              height: 1.55,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                if (_controller.config?.environmentDetails.isNotEmpty == true)
                  const SizedBox(height: 16),
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '正式笔试题目',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF12223A),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '学生进入正式笔试时只会看到这里选中的题目。',
                                  style: TextStyle(color: Color(0xFF6D7B92)),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _openQuestionSelector,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('从题库选题'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_controller.questions.isEmpty)
                        const EmptyState(
                          icon: Icons.quiz_outlined,
                          title: '当前还没有配置正式笔试题目',
                          message: '可以先从共享题库中选择题目，再保存本场笔试配置。',
                        )
                      else
                        ..._controller.questions.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _QuestionSortCard(
                              index: entry.key,
                              item: entry.value,
                              onScoreChanged: (value) => _controller
                                  .updateQuestionScore(entry.key, value),
                              onMoveUp: () =>
                                  _controller.moveQuestion(entry.key, -1),
                              onMoveDown: () =>
                                  _controller.moveQuestion(entry.key, 1),
                              onRemove: () =>
                                  _controller.removeQuestionAt(entry.key),
                              canMoveUp: entry.key > 0,
                              canMoveDown:
                                  entry.key < _controller.questions.length - 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '提交记录',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12223A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                              final compact = constraints.maxWidth < 760;
                              final searchField = TextField(
                                controller: _submissionKeywordController,
                                decoration: const InputDecoration(
                                  labelText: '搜索学生姓名',
                                  prefixIcon: Icon(Icons.search_rounded),
                                ),
                                onChanged: _controller.updateSubmissionKeyword,
                                onSubmitted: (_) =>
                                    _controller.searchSubmissions(),
                              );
                              final statusField = DropdownButtonFormField<int?>(
                                initialValue: _controller.submissionStatus,
                                decoration: const InputDecoration(
                                  labelText: '审核状态',
                                ),
                                items: const <DropdownMenuItem<int?>>[
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('全部状态'),
                                  ),
                                  DropdownMenuItem<int?>(
                                    value: 1,
                                    child: Text('待审核'),
                                  ),
                                  DropdownMenuItem<int?>(
                                    value: 2,
                                    child: Text('已通过'),
                                  ),
                                  DropdownMenuItem<int?>(
                                    value: 3,
                                    child: Text('未通过'),
                                  ),
                                ],
                                onChanged: _controller.updateSubmissionStatus,
                              );
                              if (compact) {
                                return Column(
                                  children: <Widget>[
                                    searchField,
                                    const SizedBox(height: 12),
                                    statusField,
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.tonal(
                                        onPressed:
                                            _controller.searchSubmissions,
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
                                  SizedBox(width: 180, child: statusField),
                                  const SizedBox(width: 12),
                                  FilledButton.tonal(
                                    onPressed: _controller.searchSubmissions,
                                    child: const Text('搜索'),
                                  ),
                                ],
                              );
                            },
                      ),
                      const SizedBox(height: 16),
                      if (_controller.submissions.isEmpty)
                        const EmptyState(
                          icon: Icons.assignment_turned_in_outlined,
                          title: '当前没有笔试提交记录',
                          message: '学生提交后，这里会集中展示答卷与审核状态。',
                        )
                      else
                        ..._controller.submissions.map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FBFF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFDCE6F5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          record.realName ?? '未命名学生',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF12223A),
                                          ),
                                        ),
                                      ),
                                      _SubmissionStatusPill(
                                        status: record.status,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      Text(
                                        record.studentId ?? '-',
                                        style: const TextStyle(
                                          color: Color(0xFF516074),
                                        ),
                                      ),
                                      Text(
                                        record.major ?? '-',
                                        style: const TextStyle(
                                          color: Color(0xFF516074),
                                        ),
                                      ),
                                      Text(
                                        '总分 ${record.totalScore ?? '-'}',
                                        style: const TextStyle(
                                          color: Color(0xFF2F76FF),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        DateTimeFormatter.dateTime(
                                          record.submitTime,
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xFF8792A6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((record.aiRemark ?? '')
                                      .isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 10),
                                    Text(
                                      record.aiRemark!,
                                      style: const TextStyle(
                                        height: 1.6,
                                        color: Color(0xFF516074),
                                      ),
                                    ),
                                  ],
                                  if ((record.adminRemark ?? '')
                                      .isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Text(
                                      '审核说明：${record.adminRemark}',
                                      style: const TextStyle(
                                        height: 1.6,
                                        color: Color(0xFF6D7B92),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      FilledButton.tonal(
                                        onPressed: () =>
                                            _showSubmissionDetail(record),
                                        child: const Text('查看答卷'),
                                      ),
                                      if (record.status == 1) ...<Widget>[
                                        FilledButton.tonal(
                                          onPressed: _controller.reviewing
                                              ? null
                                              : () => _reviewSubmission(
                                                  record,
                                                  2,
                                                ),
                                          child: const Text('通过'),
                                        ),
                                        OutlinedButton(
                                          onPressed: _controller.reviewing
                                              ? null
                                              : () => _reviewSubmission(
                                                  record,
                                                  3,
                                                ),
                                          child: const Text('不通过'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_controller.submissions.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: _controller.submissionPageNum > 1
                                  ? _controller.previousSubmissionPage
                                  : null,
                              child: const Text('上一页'),
                            ),
                            const Spacer(),
                            Text(
                              '${_controller.submissionPageNum} / ${_controller.submissionTotalPages == 0 ? 1 : _controller.submissionTotalPages} · 共 ${_controller.submissionTotal} 条',
                              style: const TextStyle(color: Color(0xFF516074)),
                            ),
                            const Spacer(),
                            FilledButton.tonal(
                              onPressed:
                                  _controller.submissionPageNum <
                                      _controller.submissionTotalPages
                                  ? _controller.nextSubmissionPage
                                  : null,
                              child: const Text('下一页'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _syncFormIfNeeded() {
    final config = _controller.config;
    if (config == null) {
      return;
    }
    final revision =
        '${config.recruitmentOpen}|${config.examTitle}|${config.startTime}|${config.endTime}|${config.passScore}|${config.questions.length}';
    if (_hydratedRevision == revision) {
      return;
    }
    _hydratedRevision = revision;
    _recruitmentOpen = config.recruitmentOpen;
    _titleController.text = config.examTitle ?? '';
    _descriptionController.text = config.examDescription ?? '';
    _startTimeController.text = _formatServerDateTime(config.startTime);
    _endTimeController.text = _formatServerDateTime(config.endTime);
    _passScoreController.text = '${config.passScore}';
    _submissionKeywordController.text = _controller.submissionKeyword;
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '正式笔试管理',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '统一管理考试时间、共享题目快照和学生答卷审核，让笔试流程在一个入口里完成。',
            style: TextStyle(color: Colors.white, height: 1.65),
          ),
        ],
      ),
    );
  }
}

class _QuestionSortCard extends StatelessWidget {
  const _QuestionSortCard({
    required this.index,
    required this.item,
    required this.onScoreChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.canMoveUp,
    required this.canMoveDown,
  });

  final int index;
  final PracticeQuestionBankItem item;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final bool canMoveUp;
  final bool canMoveDown;

  @override
  Widget build(BuildContext context) {
    final scoreController = TextEditingController(text: '${item.score ?? 10}');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '第 ${index + 1} 题 · ${item.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _TinyTag(text: _questionTypeText(item.questionType)),
                        _TinyTag(
                          text: item.trackCode == 'common'
                              ? '公共题库'
                              : resolveGradPathTrack(item.trackCode).shortName,
                        ),
                        if ((item.difficulty ?? '').isNotEmpty)
                          _TinyTag(text: item.difficulty!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: TextField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '分值'),
                  onChanged: (value) {
                    final score = int.tryParse(value);
                    if (score != null && score > 0) {
                      onScoreChanged(score);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.content ?? '暂无题目描述',
            style: const TextStyle(height: 1.65, color: Color(0xFF516074)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(
                onPressed: canMoveUp ? onMoveUp : null,
                child: const Text('上移'),
              ),
              OutlinedButton(
                onPressed: canMoveDown ? onMoveDown : null,
                child: const Text('下移'),
              ),
              OutlinedButton(onPressed: onRemove, child: const Text('移除')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmissionStatusPill extends StatelessWidget {
  const _SubmissionStatusPill({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      2 => const Color(0xFF0F9D58),
      3 => const Color(0xFFE53935),
      _ => const Color(0xFF2F76FF),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _submissionStatusText(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6D7B92),
        ),
      ),
    );
  }
}

class _QuestionSelectorSheet extends StatefulWidget {
  const _QuestionSelectorSheet({
    required this.repository,
    required this.initialSelectedKeys,
  });

  final GrowthCenterRepository repository;
  final Set<int> initialSelectedKeys;

  @override
  State<_QuestionSelectorSheet> createState() => _QuestionSelectorSheetState();
}

class _QuestionSelectorSheetState extends State<_QuestionSelectorSheet> {
  final TextEditingController _keywordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  PagedResult<PracticeQuestionBankItem>? _page;
  int _pageNum = 1;
  final int _pageSize = 8;
  String _trackCode = '';
  String _questionType = '';
  late final Set<int> _selectedKeys;
  final Map<int, PracticeQuestionBankItem> _selectedMap =
      <int, PracticeQuestionBankItem>{};

  @override
  void initState() {
    super.initState();
    _selectedKeys = widget.initialSelectedKeys.toSet();
    _load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final page = await widget.repository.fetchAdminQuestionBank(
        pageNum: _pageNum,
        pageSize: _pageSize,
        trackCode: _trackCode.isEmpty ? null : _trackCode,
        questionType: _questionType.isEmpty ? null : _questionType,
        keyword: _keywordController.text.trim().isEmpty
            ? null
            : _keywordController.text.trim(),
      );
      for (final item in page.records) {
        final key = item.bankQuestionId ?? item.id;
        if (_selectedKeys.contains(key)) {
          _selectedMap[key] = item;
        }
      }
      setState(() {
        _page = page;
      });
    } catch (_) {
      setState(() {
        _errorMessage = '共享题库读取失败，请稍后重试';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _toggleSelection(PracticeQuestionBankItem item, bool selected) {
    final key = item.bankQuestionId ?? item.id;
    setState(() {
      if (selected) {
        _selectedKeys.add(key);
        _selectedMap[key] = item;
      } else {
        _selectedKeys.remove(key);
        _selectedMap.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '从共享题库选题',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12223A),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final compact = constraints.maxWidth < 760;
                final trackField = DropdownButtonFormField<String>(
                  initialValue: _trackCode,
                  decoration: const InputDecoration(labelText: '方向'),
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('全部方向'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'common',
                      child: Text('公共题库'),
                    ),
                    ...gradPathTracks.map(
                      (item) => DropdownMenuItem<String>(
                        value: item.code,
                        child: Text(item.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _trackCode = value ?? '';
                  }),
                );
                final typeField = DropdownButtonFormField<String>(
                  initialValue: _questionType,
                  decoration: const InputDecoration(labelText: '题型'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: '', child: Text('全部题型')),
                    DropdownMenuItem<String>(
                      value: 'single_choice',
                      child: Text('单选题'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'fill_blank',
                      child: Text('填空题'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'programming',
                      child: Text('编程题'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _questionType = value ?? '';
                  }),
                );
                final keywordField = TextField(
                  controller: _keywordController,
                  decoration: const InputDecoration(
                    labelText: '关键词',
                    hintText: '搜索标题或描述',
                  ),
                  onSubmitted: (_) {
                    _pageNum = 1;
                    _load();
                  },
                );
                if (compact) {
                  return Column(
                    children: <Widget>[
                      trackField,
                      const SizedBox(height: 12),
                      typeField,
                      const SizedBox(height: 12),
                      keywordField,
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: () {
                            _pageNum = 1;
                            _load();
                          },
                          child: const Text('搜索'),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: trackField),
                    const SizedBox(width: 12),
                    Expanded(child: typeField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: keywordField),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: () {
                        _pageNum = 1;
                        _load();
                      },
                      child: const Text('搜索'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if ((_errorMessage ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Expanded(
              child: _loading && (_page?.records.isEmpty ?? true)
                  ? const Center(child: CircularProgressIndicator())
                  : (_page?.records.isEmpty ?? true)
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: '当前没有可选题目',
                      message: '可以切换方向或关键词后再试。',
                    )
                  : ListView(
                      children: _page!.records
                          .map(
                            (item) => CheckboxListTile(
                              value: _selectedKeys.contains(
                                item.bankQuestionId ?? item.id,
                              ),
                              onChanged: (value) =>
                                  _toggleSelection(item, value == true),
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.title),
                              subtitle: Text(
                                [
                                  _questionTypeText(item.questionType),
                                  item.trackCode == 'common'
                                      ? '公共题库'
                                      : resolveGradPathTrack(
                                          item.trackCode,
                                        ).shortName,
                                  if ((item.difficulty ?? '').isNotEmpty)
                                    item.difficulty!,
                                ].join(' · '),
                              ),
                              secondary: Text('${item.score ?? 10} 分'),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: _pageNum > 1
                      ? () {
                          setState(() => _pageNum -= 1);
                          _load();
                        }
                      : null,
                  child: const Text('上一页'),
                ),
                const Spacer(),
                Text(
                  '$_pageNum / ${_page?.pages == 0 || _page == null ? 1 : _page!.pages}',
                  style: const TextStyle(color: Color(0xFF516074)),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: _page != null && _pageNum < _page!.pages
                      ? () {
                          setState(() => _pageNum += 1);
                          _load();
                        }
                      : null,
                  child: const Text('下一页'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  '已选 ${_selectedMap.length} 题',
                  style: const TextStyle(
                    color: Color(0xFF12223A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_selectedMap.values.toList(growable: false)),
                  child: const Text('加入正式笔试'),
                ),
              ],
            ),
          ],
        ),
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

String _languageLabel(String value) {
  switch (value) {
    case 'cpp':
      return 'C++';
    case 'c':
      return 'C';
    case 'python':
      return 'Python';
    case 'java':
      return 'Java';
    default:
      return value;
  }
}

String _formatServerDateTime(DateTime? value) {
  if (value == null) {
    return '';
  }
  final local = value.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:$minute:$second';
}
