import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../features/gradpath/gradpath_catalog.dart';
import '../../repositories/growth_center_repository.dart';
import 'growth_practice_controller.dart';

class GrowthPracticePage extends StatefulWidget {
  const GrowthPracticePage({super.key, this.initialTrackCode});

  final String? initialTrackCode;

  @override
  State<GrowthPracticePage> createState() => _GrowthPracticePageState();
}

class _GrowthPracticePageState extends State<GrowthPracticePage> {
  late final GrowthPracticeController _controller;
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = GrowthPracticeController(
      context.read<GrowthCenterRepository>(),
      initialTrackCode: widget.initialTrackCode,
    )..load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('成长练习')),
          body: ResponsiveListView(
            onRefresh: _controller.refresh,
            children: <Widget>[
              _PracticeHero(trackCode: _controller.trackCode),
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
                            final compact = constraints.maxWidth < 760;
                            final trackField = DropdownButtonFormField<String>(
                              initialValue: _controller.trackCode,
                              decoration: const InputDecoration(
                                labelText: '方向',
                              ),
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem<String>(
                                  value: 'all',
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
                              initialValue: _controller.questionType.isEmpty
                                  ? ''
                                  : _controller.questionType,
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
                            final searchField = TextField(
                              controller: _keywordController,
                              decoration: const InputDecoration(
                                labelText: '关键词',
                                hintText: '搜索题目标题或内容',
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
                                  searchField,
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
                                Expanded(flex: 2, child: searchField),
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
                    icon: Icons.quiz_outlined,
                    title: '当前没有可用题目',
                    message: '可以切换方向或题型后再试。',
                  ),
                )
              else
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    if (constraints.maxWidth < 920) {
                      return Column(
                        children: <Widget>[
                          _PracticeQuestionList(controller: _controller),
                          const SizedBox(height: 16),
                          _PracticeDetailPanel(controller: _controller),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 4,
                          child: _PracticeQuestionList(controller: _controller),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: _PracticeDetailPanel(controller: _controller),
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
}

class _PracticeHero extends StatelessWidget {
  const _PracticeHero({required this.trackCode});

  final String trackCode;

  @override
  Widget build(BuildContext context) {
    final label = trackCode == 'all'
        ? '全部方向'
        : trackCode == 'common'
        ? '公共题库'
        : resolveGradPathTrack(trackCode).name;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$label 练习区',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在成长中心里按方向刷题，把基础题、编程题和短答训练收进同一个工作台。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeQuestionList extends StatelessWidget {
  const _PracticeQuestionList({required this.controller});

  final GrowthPracticeController controller;

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
          const SizedBox(height: 12),
          ...controller.questions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => controller.selectQuestion(item.id),
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: controller.selectedQuestion?.id == item.id
                        ? const Color(0xFFEFF8FF)
                        : const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: controller.selectedQuestion?.id == item.id
                          ? const Color(0xFF2F76FF)
                          : const Color(0xFFDCE6F5),
                    ),
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
                      Text(
                        item.content ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          height: 1.6,
                          color: Color(0xFF6D7B92),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: controller.pageNum > 1
                    ? controller.previousPage
                    : null,
                child: const Text('上一页'),
              ),
              const SizedBox(width: 12),
              Text(
                '${controller.pageNum} / ${controller.totalPages == 0 ? 1 : controller.totalPages}',
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: controller.pageNum < controller.totalPages
                    ? controller.nextPage
                    : null,
                child: const Text('下一页'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PracticeDetailPanel extends StatelessWidget {
  const _PracticeDetailPanel({required this.controller});

  final GrowthPracticeController controller;

  @override
  Widget build(BuildContext context) {
    final question = controller.selectedQuestion;
    if (question == null) {
      return const PanelCard(
        child: EmptyState(
          icon: Icons.extension_outlined,
          title: '请选择一道题目',
          message: '选择后可以查看题干并直接作答。',
        ),
      );
    }

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            question.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question.content ?? '',
            style: const TextStyle(height: 1.7, color: Color(0xFF516074)),
          ),
          const SizedBox(height: 14),
          if (question.isSingleChoice)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: question.options
                  .map(
                    (option) => ChoiceChip(
                      label: Text('${option.label}. ${option.text}'),
                      selected: controller.answer == option.label,
                      onSelected: (_) => controller.updateAnswer(option.label),
                    ),
                  )
                  .toList(growable: false),
            )
          else if (question.isFillBlank)
            TextField(
              onChanged: controller.updateAnswer,
              decoration: const InputDecoration(
                labelText: '填写答案',
                hintText: '输入你的答案',
              ),
            )
          else ...<Widget>[
            DropdownButtonFormField<String>(
              initialValue: controller.language,
              decoration: const InputDecoration(labelText: '语言'),
              items: question.allowedLanguages
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: controller.updateLanguage,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey<String>('${question.id}-${controller.language}'),
              initialValue: controller.code,
              onChanged: controller.updateCode,
              minLines: 12,
              maxLines: 18,
              style: const TextStyle(fontFamily: 'monospace', height: 1.5),
              decoration: const InputDecoration(
                labelText: '代码',
                fillColor: Color(0xFFF7FAFF),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey<int>(question.id),
              initialValue: controller.input,
              onChanged: controller.updateInput,
              minLines: 3,
              maxLines: 5,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(
                labelText: '自测输入',
                fillColor: Color(0xFFF7FAFF),
                filled: true,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              if (!question.isProgramming)
                FilledButton(
                  onPressed: controller.submitting
                      ? null
                      : controller.submitObjective,
                  child: const Text('提交答案'),
                ),
              if (question.isProgramming)
                FilledButton.tonal(
                  onPressed: controller.running
                      ? null
                      : () => controller.runCode(debug: true),
                  child: const Text('调试运行'),
                ),
              if (question.isProgramming)
                FilledButton(
                  onPressed: controller.running
                      ? null
                      : () => controller.runCode(debug: false),
                  child: const Text('提交判题'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: SelectableText(
              controller.resultMessage ?? '作答后，这里会显示结果。',
              style: const TextStyle(
                height: 1.7,
                color: Color(0xFF516074),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
