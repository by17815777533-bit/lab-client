import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/growth_center_models.dart';
import '../../repositories/growth_center_repository.dart';
import 'growth_center_controller.dart';

class GrowthCenterPage extends StatefulWidget {
  const GrowthCenterPage({super.key});

  @override
  State<GrowthCenterPage> createState() => _GrowthCenterPageState();
}

class _GrowthCenterPageState extends State<GrowthCenterPage> {
  late final GrowthCenterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GrowthCenterController(context.read<GrowthCenterRepository>())
      ..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final dashboard = _controller.dashboard;
        final result = _controller.latestResult;
        final detail = _controller.selectedTrackDetail;

        return Scaffold(
          appBar: AppBar(
            title: const Text('成长中心'),
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
              _GrowthHero(
                hasResult: _controller.hasResult,
                trackCount: dashboard?.tracks.length ?? 0,
                questionCount: _controller.questionSet?.questions.length ?? 0,
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
              if (_controller.loading && dashboard == null)
                const PanelCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (dashboard == null)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.hub_outlined,
                    title: '暂时无法获取成长中心内容',
                    message: '请稍后再试，或联系管理员确认当前服务状态。',
                  ),
                )
              else if (!_controller.hasResult)
                _AssessmentSection(controller: _controller)
              else ...<Widget>[
                if (result != null)
                  _ResultOverviewCard(
                    result: result,
                    onPractice: () => context.push('/student/growth-practice'),
                    onGradPath: () => context.push('/student/gradpath'),
                    onRestart: _controller.restartAssessment,
                  ),
                const SizedBox(height: 16),
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '推荐路径',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12223A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...dashboard.tracks.map(
                        (track) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TrackTile(
                            track: track,
                            selected:
                                _controller.selectedTrackCode == track.code,
                            onTap: () => _controller.selectTrack(track.code),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (detail != null)
                  _TrackDetailSection(
                    detail: detail,
                    onPractice: () => context.push(
                      '/student/growth-practice?track=${detail.track.code}',
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GrowthHero extends StatelessWidget {
  const _GrowthHero({
    required this.hasResult,
    required this.trackCount,
    required this.questionCount,
  });

  final bool hasResult;
  final int trackCount;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0B4560), Color(0xFF0F766E)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -14,
            top: -12,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(34),
              ),
            ),
          ),
          Positioned(
            right: 52,
            bottom: -18,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final compact = constraints.maxWidth < 760;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      hasResult ? '路径已生成' : '成长测评',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (compact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          hasResult ? '成长路径已经生成' : '先完成成长测评',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasResult
                              ? '根据你的测评结果查看路径推荐、学习阶段和练习入口。'
                              : '完成 20 道测评题后，系统会给出更贴合你的成长路径推荐。',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.65,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                hasResult ? '成长路径已经生成' : '先完成成长测评',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasResult
                                    ? '根据你的测评结果查看路径推荐、学习阶段和练习入口。'
                                    : '完成 20 道测评题后，系统会给出更贴合你的成长路径推荐。',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.65,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                hasResult ? '推荐方向 $trackCount 个' : '待完成测评',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasResult
                                    ? '继续查看阶段路线和练习入口'
                                    : '当前题量 $questionCount 题',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _HeroPill(label: hasResult ? '已生成路径' : '待完成测评'),
                      _HeroPill(label: '方向 $trackCount'),
                      _HeroPill(
                        label:
                            '题量 ${questionCount == 0 ? '--' : questionCount}',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
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

class _AssessmentSection extends StatelessWidget {
  const _AssessmentSection({required this.controller});

  final GrowthCenterController controller;

  @override
  Widget build(BuildContext context) {
    final questionSet = controller.questionSet;
    if (questionSet == null) {
      return const PanelCard(
        child: EmptyState(
          icon: Icons.fact_check_outlined,
          title: '当前没有可用测评题目',
          message: '请稍后再试。',
        ),
      );
    }

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(
            title: '成长测评',
            subtitle: '逐题完成后会自动生成更贴合你的成长方向推荐。',
          ),
          const SizedBox(height: 10),
          Text(
            '共 ${questionSet.questions.length} 道题，完成后会生成你的路径推荐。',
            style: const TextStyle(height: 1.65, color: Color(0xFF6D7B92)),
          ),
          const SizedBox(height: 16),
          ...questionSet.questions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDCE6F5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Q${question.questionNo ?? '-'} · ${question.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    if ((question.description ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        question.description!,
                        style: const TextStyle(
                          height: 1.7,
                          color: Color(0xFF6D7B92),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...question.options.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => controller.selectAnswer(
                            question.id,
                            option.optionKey,
                          ),
                          child: Ink(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  controller.answers[question.id] ==
                                      option.optionKey
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    controller.answers[question.id] ==
                                        option.optionKey
                                    ? const Color(0xFF2F76FF)
                                    : const Color(0xFFDCE6F5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${option.optionKey}. ${option.optionTitle}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF12223A),
                                  ),
                                ),
                                if ((option.optionDesc).isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 6),
                                  Text(
                                    option.optionDesc,
                                    style: const TextStyle(
                                      height: 1.6,
                                      color: Color(0xFF6D7B92),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.submitting
                  ? null
                  : controller.submitAssessment,
              child: controller.submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('提交测评'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultOverviewCard extends StatelessWidget {
  const _ResultOverviewCard({
    required this.result,
    required this.onPractice,
    required this.onGradPath,
    required this.onRestart,
  });

  final GrowthResultView result;
  final VoidCallback onPractice;
  final VoidCallback onGradPath;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final top = result.topTracks.isNotEmpty ? result.topTracks.first : null;
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(
            title: '结果总览',
            subtitle: '根据最近一次测评结果，为你推荐更匹配的成长方向。',
          ),
          const SizedBox(height: 14),
          Text(
            top?.name ?? '成长结果',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.summary ?? '成长结果已更新。',
            style: const TextStyle(height: 1.7, color: Color(0xFF516074)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: <Widget>[
              Text(
                '答题数 ${result.answerCount}',
                style: const TextStyle(
                  color: Color(0xFF2F76FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '更新时间 ${DateTimeFormatter.dateTime(result.createTime)}',
                style: const TextStyle(color: Color(0xFF8792A6)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: onPractice,
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('成长练习'),
              ),
              FilledButton.tonalIcon(
                onPressed: onGradPath,
                icon: const Icon(Icons.psychology_alt_outlined),
                label: const Text('智能练习'),
              ),
              OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('重新测评'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.selected,
    required this.onTap,
  });

  final GrowthTrackSummary track;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? const Color(0xFFEFF8FF) : const Color(0xFFF8FBFF),
          border: Border.all(
            color: selected ? const Color(0xFF2F76FF) : const Color(0xFFDCE6F5),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    track.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12223A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    track.subtitle ?? track.description ?? '',
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
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                '${track.matchScore ?? 0}',
                style: const TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF12223A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF8792A6), height: 1.55),
        ),
      ],
    );
  }
}

class _TrackDetailSection extends StatelessWidget {
  const _TrackDetailSection({required this.detail, required this.onPractice});

  final GrowthTrackDetail detail;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
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
                      detail.track.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail.track.fitScene ?? detail.track.description ?? '',
                      style: const TextStyle(
                        height: 1.7,
                        color: Color(0xFF516074),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: onPractice,
                child: const Text('去练习'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              ...detail.track.courses.take(4).map((item) => _Tag(text: item)),
              ...detail.track.books.take(2).map((item) => _Tag(text: item)),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '阶段路线',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          const SizedBox(height: 12),
          ...detail.stages.map(
            (stage) => Padding(
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
                      'Stage ${stage.stageNo ?? '-'} · ${stage.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stage.goal ?? '',
                      style: const TextStyle(
                        height: 1.65,
                        color: Color(0xFF516074),
                      ),
                    ),
                    if ((stage.practiceKeyword ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        '推荐练习：${stage.practiceKeyword}',
                        style: const TextStyle(
                          color: Color(0xFF2F76FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6D7B92),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
