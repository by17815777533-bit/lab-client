import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../features/gradpath/gradpath_catalog.dart';
import '../../models/practice_question_bank_item.dart';
import '../../repositories/growth_center_repository.dart';
import 'growth_question_bank_controller.dart';

class GrowthQuestionBankPage extends StatefulWidget {
  const GrowthQuestionBankPage({super.key});

  @override
  State<GrowthQuestionBankPage> createState() => _GrowthQuestionBankPageState();
}

class _GrowthQuestionBankPageState extends State<GrowthQuestionBankPage> {
  late final GrowthQuestionBankController _controller;
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = GrowthQuestionBankController(
      context.read<GrowthCenterRepository>(),
    )..load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEditor({PracticeQuestionBankItem? initial}) async {
    final detail = initial == null
        ? null
        : await _controller.fetchDetail(initial.id);
    if (!mounted) {
      return;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _QuestionEditorSheet(
          initial: detail ?? initial,
          onSubmit: _controller.saveQuestion,
        );
      },
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('题目已保存')));
    }
  }

  Future<void> _delete(PracticeQuestionBankItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除题目'),
          content: Text('确认删除“${item.title}”吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _controller.deleteQuestion(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('成长题库'),
            actions: <Widget>[
              IconButton(
                tooltip: '新增题目',
                onPressed: _controller.saving ? null : () => _openEditor(),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          body: ResponsiveListView(
            onRefresh: _controller.refresh,
            children: <Widget>[
              const _GrowthBankHero(),
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
              PanelCard(
                child: Column(
                  children: <Widget>[
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final compact = constraints.maxWidth < 780;
                            final trackField = DropdownButtonFormField<String>(
                              initialValue: _controller.trackCode,
                              decoration: const InputDecoration(
                                labelText: '方向',
                              ),
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
                              onChanged: _controller.updateTrackCode,
                            );
                            final typeField = DropdownButtonFormField<String>(
                              initialValue: _controller.questionType,
                              decoration: const InputDecoration(
                                labelText: '题型',
                              ),
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('全部题型'),
                                ),
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
                              onChanged: _controller.updateQuestionType,
                            );
                            final keywordField = TextField(
                              controller: _keywordController,
                              decoration: const InputDecoration(
                                labelText: '关键词',
                                hintText: '搜索标题或描述',
                              ),
                              onChanged: _controller.updateKeyword,
                              onSubmitted: (_) => _controller.search(),
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
                                      onPressed: _controller.search,
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
                                  onPressed: _controller.search,
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
              if (_controller.loading && _controller.records.isEmpty)
                const PanelCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_controller.records.isEmpty)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: '当前没有题目',
                    message: '可以先新增题目，或更换筛选条件后再试。',
                  ),
                )
              else
                ..._controller.records.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PanelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  item.title,
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
                                  FilledButton.tonal(
                                    onPressed: () => _openEditor(initial: item),
                                    child: const Text('编辑'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _delete(item),
                                    child: const Text('删除'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.content ?? '',
                            style: const TextStyle(
                              height: 1.7,
                              color: Color(0xFF516074),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _MiniTag(text: _typeLabel(item.questionType)),
                              _MiniTag(
                                text: item.trackCode == 'common'
                                    ? '公共题库'
                                    : resolveGradPathTrack(
                                        item.trackCode,
                                      ).shortName,
                              ),
                              if ((item.difficulty ?? '').isNotEmpty)
                                _MiniTag(text: item.difficulty!),
                              ...item.tags
                                  .take(4)
                                  .map((tag) => _MiniTag(text: tag)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_controller.records.isNotEmpty)
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
      },
    );
  }

  static String _typeLabel(String type) {
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
}

class _GrowthBankHero extends StatelessWidget {
  const _GrowthBankHero();

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
            '共享题库维护',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '成长练习和正式笔试都从这里取题，维护时要把题干、答案和判题配置一次写完整。',
            style: TextStyle(color: Colors.white, height: 1.65),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text});

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

class _QuestionEditorSheet extends StatefulWidget {
  const _QuestionEditorSheet({required this.onSubmit, this.initial});

  final PracticeQuestionBankItem? initial;
  final Future<bool> Function(PracticeQuestionBankItem item) onSubmit;

  @override
  State<_QuestionEditorSheet> createState() => _QuestionEditorSheetState();
}

class _QuestionEditorSheetState extends State<_QuestionEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _questionType;
  late String _trackCode;
  late String _difficulty;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late final TextEditingController _analysisController;
  late final TextEditingController _inputController;
  late final TextEditingController _outputController;
  late final TextEditingController _sampleInputController;
  late final TextEditingController _sampleOutputController;
  late List<PracticeQuestionOption> _options;
  late String _correctAnswer;
  late List<String> _acceptableAnswers;
  late Set<String> _allowedLanguages;
  late List<PracticeJudgeCase> _judgeCases;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _questionType = item?.questionType ?? 'programming';
    _trackCode = item?.trackCode ?? 'common';
    _difficulty = item?.difficulty ?? '中等';
    _titleController = TextEditingController(text: item?.title ?? '');
    _contentController = TextEditingController(text: item?.content ?? '');
    _tagsController = TextEditingController(text: item?.tags.join(', ') ?? '');
    _analysisController = TextEditingController(text: item?.analysisHint ?? '');
    _inputController = TextEditingController(text: item?.inputFormat ?? '');
    _outputController = TextEditingController(text: item?.outputFormat ?? '');
    _sampleInputController = TextEditingController(
      text: item?.sampleInput ?? '',
    );
    _sampleOutputController = TextEditingController(
      text: item?.sampleOutput ?? '',
    );
    _options = item?.options.isNotEmpty == true
        ? item!.options
        : <PracticeQuestionOption>[
            PracticeQuestionOption(label: 'A', text: ''),
            PracticeQuestionOption(label: 'B', text: ''),
            PracticeQuestionOption(label: 'C', text: ''),
            PracticeQuestionOption(label: 'D', text: ''),
          ];
    _correctAnswer = item?.correctAnswer ?? 'A';
    _acceptableAnswers = item?.acceptableAnswers.toList() ?? <String>[];
    _allowedLanguages =
        (item?.allowedLanguages.isNotEmpty == true
                ? item!.allowedLanguages
                : <String>['c', 'cpp', 'java', 'python'])
            .toSet();
    _judgeCases = item?.judgeCases.isNotEmpty == true
        ? item!.judgeCases
        : <PracticeJudgeCase>[PracticeJudgeCase(input: '', output: '')];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _analysisController.dispose();
    _inputController.dispose();
    _outputController.dispose();
    _sampleInputController.dispose();
    _sampleOutputController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_questionType == 'single_choice' &&
        _options.any((item) => item.text.trim().isEmpty)) {
      return;
    }
    if (_questionType == 'fill_blank' && _acceptableAnswers.isEmpty) {
      return;
    }
    if (_questionType == 'programming' && _allowedLanguages.isEmpty) {
      return;
    }
    if (_questionType == 'programming' &&
        _judgeCases.where((item) => item.output.trim().isNotEmpty).isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });
    final success = await widget.onSubmit(
      PracticeQuestionBankItem(
        id: widget.initial?.id ?? 0,
        bankQuestionId: widget.initial?.bankQuestionId,
        questionType: _questionType,
        trackCode: _trackCode,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        difficulty: _difficulty,
        inputFormat: _inputController.text.trim(),
        outputFormat: _outputController.text.trim(),
        sampleInput: _sampleInputController.text,
        sampleOutput: _sampleOutputController.text,
        tags: _tagsController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false),
        analysisHint: _analysisController.text.trim(),
        options: _options,
        correctAnswer: _correctAnswer,
        acceptableAnswers: _acceptableAnswers,
        allowedLanguages: _allowedLanguages.toList(growable: false),
        judgeCases: _judgeCases
            .where((item) => item.output.trim().isNotEmpty)
            .toList(growable: false),
        score: widget.initial?.score,
        sortOrder: widget.initial?.sortOrder,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
    });
    if (success) {
      Navigator.of(context).pop(true);
    }
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
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Text(
              widget.initial == null ? '新增题目' : '编辑题目',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12223A),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _questionType,
              decoration: const InputDecoration(labelText: '题型'),
              items: const <DropdownMenuItem<String>>[
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
                _questionType = value ?? 'programming';
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _trackCode,
              decoration: const InputDecoration(labelText: '方向'),
              items: <DropdownMenuItem<String>>[
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
                _trackCode = value ?? 'common';
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _difficulty,
              decoration: const InputDecoration(labelText: '难度'),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: '简单', child: Text('简单')),
                DropdownMenuItem<String>(value: '中等', child: Text('中等')),
                DropdownMenuItem<String>(value: '困难', child: Text('困难')),
              ],
              onChanged: (value) => setState(() {
                _difficulty = value ?? '中等';
              }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '题目标题'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? '请输入题目标题' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '题目描述'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '使用英文逗号分隔',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _analysisController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '解题提示'),
            ),
            if (_questionType == 'single_choice') ..._buildSingleChoiceFields(),
            if (_questionType == 'fill_blank') ..._buildFillBlankFields(),
            if (_questionType == 'programming') ..._buildProgrammingFields(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSingleChoiceFields() {
    return <Widget>[
      const SizedBox(height: 12),
      ..._options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final controller = TextEditingController(text: option.text);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocalState) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: <Widget>[
                  SizedBox(width: 36, child: Text(option.label)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: (value) {
                        _options[index] = PracticeQuestionOption(
                          label: option.label,
                          text: value,
                        );
                      },
                      decoration: InputDecoration(
                        labelText: '选项 ${option.label}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('正确答案'),
                    selected: _correctAnswer == option.label,
                    onSelected: (_) => setState(() {
                      _correctAnswer = option.label;
                    }),
                  ),
                ],
              ),
            );
          },
        );
      }),
    ];
  }

  List<Widget> _buildFillBlankFields() {
    final answersController = TextEditingController(
      text: _acceptableAnswers.join(', '),
    );
    return <Widget>[
      const SizedBox(height: 12),
      TextField(
        controller: answersController,
        onChanged: (value) {
          _acceptableAnswers = value
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
        },
        decoration: const InputDecoration(
          labelText: '可接受答案',
          hintText: '使用英文逗号分隔',
        ),
      ),
    ];
  }

  List<Widget> _buildProgrammingFields() {
    return <Widget>[
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: <Widget>[
          for (final language in <String>['c', 'cpp', 'java', 'python'])
            FilterChip(
              label: Text(language.toUpperCase()),
              selected: _allowedLanguages.contains(language),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _allowedLanguages.add(language);
                  } else {
                    _allowedLanguages.remove(language);
                  }
                });
              },
            ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _inputController,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(labelText: '输入格式'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _outputController,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(labelText: '输出格式'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _sampleInputController,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(labelText: '样例输入'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _sampleOutputController,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(labelText: '样例输出'),
      ),
      const SizedBox(height: 12),
      ..._judgeCases.asMap().entries.map((entry) {
        final index = entry.key;
        final judgeCase = entry.value;
        final inputController = TextEditingController(text: judgeCase.input);
        final outputController = TextEditingController(text: judgeCase.output);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: <Widget>[
              TextField(
                controller: inputController,
                onChanged: (value) {
                  _judgeCases[index] = PracticeJudgeCase(
                    input: value,
                    output: _judgeCases[index].output,
                  );
                },
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: '判题输入 ${index + 1}'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: outputController,
                onChanged: (value) {
                  _judgeCases[index] = PracticeJudgeCase(
                    input: _judgeCases[index].input,
                    output: value,
                  );
                },
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: '期望输出 ${index + 1}'),
              ),
            ],
          ),
        );
      }),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _judgeCases.add(PracticeJudgeCase(input: '', output: ''));
          }),
          icon: const Icon(Icons.add_rounded),
          label: const Text('新增判题用例'),
        ),
      ),
    ];
  }
}
