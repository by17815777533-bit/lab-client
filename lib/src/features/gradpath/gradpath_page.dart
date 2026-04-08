import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../repositories/gradpath_repository.dart';
import 'gradpath_catalog.dart';
import 'gradpath_controller.dart';

class GradPathPage extends StatefulWidget {
  const GradPathPage({super.key});

  @override
  State<GradPathPage> createState() => _GradPathPageState();
}

class _GradPathPageState extends State<GradPathPage> {
  late final GradPathController _controller;
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = GradPathController(context.read<GradPathRepository>())
      ..load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openGenerateDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _keywordController.text.trim(),
    );
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '生成定向题目',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '输入一个更具体的关键词，例如“二叉树”、“服务治理”、“自动化测试”。',
                style: TextStyle(height: 1.7, color: Color(0xFF6D7B92)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '关键词',
                  hintText: '例如：动态规划、接口设计、容器调度',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final ok = await _controller.generateQuestion(
                      controller.text,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop(ok);
                  },
                  child: const Text('生成题目'),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (success == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('新题目已生成')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final question = _controller.selectedQuestion;
        final track = _controller.selectedTrackMeta;
        final codeFieldKey = ValueKey<String>(
          '${question?.id ?? 0}-${_controller.selectedLanguage}',
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('智能练习'),
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
              _GradPathHero(currentTrack: track.name, total: _controller.total),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '筛选题目',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final compact = constraints.maxWidth < 760;
                            if (compact) {
                              return Column(children: _buildFilterFields());
                            }
                            return Row(
                              children: _buildFilterFields(inline: true),
                            );
                          },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_controller.loading && _controller.questions.isEmpty)
                const PanelCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_controller.questions.isEmpty)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.psychology_alt_outlined,
                    title: '当前没有可展示的练习题',
                    message: '可以切换方向、搜索关键词，或者直接生成一题新的练习题。',
                  ),
                )
              else
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    if (constraints.maxWidth < 920) {
                      return Column(
                        children: <Widget>[
                          _QuestionListPanel(controller: _controller),
                          const SizedBox(height: 16),
                          _QuestionDetailPanel(
                            controller: _controller,
                            codeFieldKey: codeFieldKey,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 4,
                          child: _QuestionListPanel(controller: _controller),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: _QuestionDetailPanel(
                            controller: _controller,
                            codeFieldKey: codeFieldKey,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFilterFields({bool inline = false}) {
    final children = <Widget>[
      if (inline)
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            initialValue: _controller.selectedTrackCode,
            decoration: const InputDecoration(labelText: '方向'),
            items: gradPathTracks
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.code,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: (value) => _controller.updateTrackCode(value),
          ),
        )
      else
        DropdownButtonFormField<String>(
          initialValue: _controller.selectedTrackCode,
          decoration: const InputDecoration(labelText: '方向'),
          items: gradPathTracks
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.code,
                  child: Text(item.name),
                ),
              )
              .toList(),
          onChanged: (value) => _controller.updateTrackCode(value),
        ),
      if (inline) const SizedBox(width: 12) else const SizedBox(height: 12),
      if (inline)
        Expanded(
          flex: 4,
          child: TextField(
            controller: _keywordController,
            decoration: const InputDecoration(
              labelText: '关键词',
              hintText: '搜索题目标题或内容',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: _controller.setKeyword,
            onSubmitted: (_) => _controller.search(),
          ),
        )
      else
        TextField(
          controller: _keywordController,
          decoration: const InputDecoration(
            labelText: '关键词',
            hintText: '搜索题目标题或内容',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: _controller.setKeyword,
          onSubmitted: (_) => _controller.search(),
        ),
      if (inline) const SizedBox(width: 12) else const SizedBox(height: 12),
      if (inline)
        FilledButton.tonalIcon(
          onPressed: _controller.loading ? null : _controller.search,
          icon: const Icon(Icons.manage_search_rounded),
          label: const Text('搜索'),
        )
      else
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: _controller.loading ? null : _controller.search,
            icon: const Icon(Icons.manage_search_rounded),
            label: const Text('搜索'),
          ),
        ),
      if (inline) const SizedBox(width: 8) else const SizedBox(height: 10),
      if (inline)
        FilledButton.icon(
          onPressed: _controller.generating ? null : _openGenerateDialog,
          icon: _controller.generating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: const Text('生成题目'),
        )
      else
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _controller.generating ? null : _openGenerateDialog,
            icon: _controller.generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: const Text('生成题目'),
          ),
        ),
    ];
    return children;
  }
}

class _GradPathHero extends StatelessWidget {
  const _GradPathHero({required this.currentTrack, required this.total});

  final String currentTrack;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1142C1), Color(0xFF2F76FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '按方向刷题，不再盲目练习',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '围绕岗位方向筛题、生成定向练习，再把运行结果和错误分析收在同一页里。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _HeroChip(label: '当前方向 $currentTrack'),
              _HeroChip(label: '题库 $total'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuestionListPanel extends StatelessWidget {
  const _QuestionListPanel({required this.controller});

  final GradPathController controller;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '题目列表',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          const SizedBox(height: 14),
          ...controller.questions.map((item) {
            final selected = controller.selectedQuestion?.id == item.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => controller.selectQuestion(item.id),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2F76FF)
                          : const Color(0xFFDCE6F5),
                    ),
                    color: selected
                        ? const Color(0xFFEFF5FF)
                        : const Color(0xFFF9FBFF),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF12223A),
                              ),
                            ),
                          ),
                          _TypeTag(label: _typeLabel(item.questionType)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          height: 1.6,
                          color: Color(0xFF6D7B92),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _MiniTag(
                            label: resolveGradPathTrack(
                              item.trackCode,
                            ).shortName,
                          ),
                          if ((item.difficulty ?? '').isNotEmpty)
                            _MiniTag(label: item.difficulty!),
                          ...item.tags
                              .take(3)
                              .map((tag) => _MiniTag(label: tag)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: controller.pageNum <= 1
                    ? null
                    : controller.previousPage,
                child: const Text('上一页'),
              ),
              const SizedBox(width: 12),
              Text(
                '${controller.pageNum} / ${controller.totalPages == 0 ? 1 : controller.totalPages}',
                style: const TextStyle(
                  color: Color(0xFF6D7B92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed:
                    controller.totalPages == 0 ||
                        controller.pageNum >= controller.totalPages
                    ? null
                    : controller.nextPage,
                child: const Text('下一页'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _typeLabel(String value) {
    switch (value) {
      case 'single_choice':
        return '单选题';
      case 'fill_blank':
        return '填空题';
      case 'programming':
        return '编程题';
      default:
        return value;
    }
  }
}

class _QuestionDetailPanel extends StatelessWidget {
  const _QuestionDetailPanel({
    required this.controller,
    required this.codeFieldKey,
  });

  final GradPathController controller;
  final Key codeFieldKey;

  @override
  Widget build(BuildContext context) {
    final question = controller.selectedQuestion;
    if (question == null) {
      return const PanelCard(
        child: EmptyState(
          icon: Icons.code_off_rounded,
          title: '请选择一道题目',
          message: '从左侧选择题目后，这里会展示详细描述、代码区和运行结果。',
        ),
      );
    }

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      question.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _TypeTag(
                          label: _QuestionListPanel._typeLabel(
                            question.questionType,
                          ),
                        ),
                        _MiniTag(
                          label: resolveGradPathTrack(question.trackCode).name,
                        ),
                        ...question.tags
                            .take(4)
                            .map((tag) => _MiniTag(label: tag)),
                      ],
                    ),
                  ],
                ),
              ),
              if (question.isProgramming)
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    initialValue: controller.selectedLanguage,
                    decoration: const InputDecoration(labelText: '语言'),
                    items:
                        (question.allowedLanguages.isEmpty
                                ? <String>[controller.selectedLanguage]
                                : question.allowedLanguages)
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(_languageLabel(item)),
                              ),
                            )
                            .toList(),
                    onChanged: controller.updateLanguage,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionBlock(title: '题目描述', child: Text(question.content)),
          if (question.isProgramming) ...<Widget>[
            const SizedBox(height: 16),
            _SectionBlock(
              title: '输入输出',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('输入格式：${question.inputFormat ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('输出格式：${question.outputFormat ?? '-'}'),
                  const SizedBox(height: 12),
                  Text('样例输入：${question.sampleInput ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('样例输出：${question.sampleOutput ?? '-'}'),
                ],
              ),
            ),
          ],
          if (question.isSingleChoice &&
              question.options.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _SectionBlock(
              title: '选项',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: question.options
                    .map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${option.label}. ${option.text}'),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionBlock(
            title: '代码区',
            child: TextFormField(
              key: codeFieldKey,
              initialValue: controller.code,
              onChanged: controller.updateCode,
              minLines: question.isProgramming ? 14 : 4,
              maxLines: question.isProgramming ? 20 : 6,
              style: const TextStyle(fontFamily: 'monospace', height: 1.5),
              decoration: InputDecoration(
                hintText: question.isProgramming ? '在这里编写代码' : '输入你的答案',
                fillColor: const Color(0xFFF7FAFF),
                filled: true,
              ),
            ),
          ),
          if (question.isProgramming) ...<Widget>[
            const SizedBox(height: 16),
            _SectionBlock(
              title: '自测输入',
              child: TextFormField(
                key: ValueKey<int>(question.id),
                initialValue: controller.customInput,
                onChanged: controller.updateCustomInput,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: '调试运行时可自定义输入',
                  fillColor: Color(0xFFF7FAFF),
                  filled: true,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: controller.running ? null : controller.runDebug,
                icon: controller.running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: const Text('调试运行'),
              ),
              FilledButton.icon(
                onPressed: controller.running ? null : controller.submit,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('提交答案'),
              ),
              OutlinedButton.icon(
                onPressed:
                    controller.analyzing ||
                        (controller.resultText ?? '').isEmpty
                    ? null
                    : controller.analyze,
                icon: controller.analyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.insights_outlined),
                label: const Text('错误分析'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ResultCard(
            title: controller.lastRunPassed ? '运行结果 · 已通过' : '运行结果',
            text: controller.resultText ?? '运行或提交后，这里会显示结果。',
          ),
          if ((controller.analysisText ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _ResultCard(
              title: '分析建议',
              text: controller.analysisText!,
              tone: const Color(0xFFFFF6E5),
            ),
          ],
        ],
      ),
    );
  }

  static String _languageLabel(String value) {
    switch (value) {
      case 'java':
        return 'Java';
      case 'python':
        return 'Python';
      case 'c':
        return 'C';
      case 'cpp':
        return 'C++';
      default:
        return value;
    }
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF12223A),
          ),
        ),
        const SizedBox(height: 10),
        DefaultTextStyle(
          style: const TextStyle(height: 1.7, color: Color(0xFF516074)),
          child: child,
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.text,
    this.tone = const Color(0xFFF4F7FC),
  });

  final String title;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(height: 10),
          SelectableText(
            text,
            style: const TextStyle(
              height: 1.7,
              color: Color(0xFF516074),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6D7B92),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
