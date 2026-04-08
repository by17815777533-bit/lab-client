import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/portal_shortcut_chip.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/statistics_overview.dart';
import '../../models/user_profile.dart';
import '../lab_apply_audit/latest_lab_apply_widgets.dart';
import 'statistics_controller.dart';

class StatisticsWorkbenchPage extends ConsumerStatefulWidget {
  const StatisticsWorkbenchPage({super.key, this.labId});

  final int? labId;

  @override
  ConsumerState<StatisticsWorkbenchPage> createState() =>
      _StatisticsWorkbenchPageState();
}

class _StatisticsWorkbenchPageState
    extends ConsumerState<StatisticsWorkbenchPage> {
  late final StatisticsController _controller;
  int _sectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = StatisticsController(
      repository: ref.read(statisticsRepositoryProvider),
      labApplyAuditRepository: ref.read(labApplyAuditRepositoryProvider),
      labId: widget.labId,
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).profile;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final overview = _controller.overview;
        final canUseExitAudit =
            profile?.schoolDirector == true || profile?.labManager == true;
        final canUseLabApplications =
            profile?.schoolDirector == true ||
            profile?.collegeManager == true ||
            profile?.labManager == true;
        final canUseTeacherRegister =
            profile?.schoolDirector == true || profile?.collegeManager == true;
        final canUseEquipment = profile?.labManager == true;
        final canUseWorkspace = profile?.labManager == true;
        final canUseAttendanceWorkbench = profile?.isAdmin == true;
        final canUseRecruitPlans = profile?.isAdmin == true;
        final canUseAdminManagement = profile?.schoolDirector == true;
        final canUseAdminAccounts = profile?.schoolDirector == true;
        final canUseStudentManagement = profile?.isAdmin == true;
        final canUseDeliveryManagement = profile?.isAdmin == true;
        final canUseGraduateManagement = profile?.labManager == true;
        final canUseLabInfoManagement = profile?.labManager == true;
        final canUseGrowthQuestionBank = profile?.isAdmin == true;
        final canUseWrittenExams = profile?.labManager == true;

        return Scaffold(
          appBar: AppBar(
            title: const Text('统计工作台'),
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
              _HeroBanner(
                profile: profile,
                overview: overview,
                loading: _controller.loading,
              ),
              if (canUseExitAudit ||
                  canUseAttendanceWorkbench ||
                  canUseRecruitPlans ||
                  canUseAdminManagement ||
                  canUseAdminAccounts ||
                  canUseStudentManagement ||
                  canUseDeliveryManagement ||
                  canUseGraduateManagement ||
                  canUseLabInfoManagement ||
                  canUseGrowthQuestionBank ||
                  canUseWrittenExams ||
                  canUseEquipment ||
                  canUseWorkspace ||
                  canUseLabApplications ||
                  canUseTeacherRegister) ...<Widget>[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      if (canUseLabApplications)
                        PortalShortcutChip(
                          onPressed: () => context.push('/admin/applications'),
                          icon: Icons.fact_check_outlined,
                          label: '成员申请',
                        ),
                      if (canUseTeacherRegister)
                        PortalShortcutChip(
                          onPressed: () =>
                              context.push('/admin/teacher-register-applies'),
                          icon: Icons.badge_outlined,
                          label: '教师注册',
                        ),
                      if (canUseAttendanceWorkbench)
                        PortalShortcutChip(
                          onPressed: () =>
                              context.push('/admin/attendance-workbench'),
                          icon: Icons.how_to_reg_rounded,
                          label: '考勤工作台',
                        ),
                      if (canUseRecruitPlans)
                        PortalShortcutChip(
                          onPressed: () => context.push('/admin/recruit-plans'),
                          icon: Icons.campaign_outlined,
                          label: '招新计划',
                        ),
                      if (canUseAdminManagement)
                        PortalShortcutChip(
                          onPressed: () =>
                              context.push('/admin/admin-management'),
                          icon: Icons.manage_accounts_outlined,
                          label: '管理员分配',
                        ),
                      if (canUseAdminAccounts)
                        PortalShortcutChip(
                          onPressed: () =>
                              context.push('/admin/admin-accounts'),
                          icon: Icons.admin_panel_settings_outlined,
                          label: '管理员账号',
                        ),
                      if (canUseStudentManagement)
                        PortalShortcutChip(
                          onPressed: () => context.push('/admin/students'),
                          icon: Icons.groups_2_outlined,
                          label: '学生管理',
                        ),
                      if (canUseDeliveryManagement)
                        PortalShortcutChip(
                          onPressed: () => context.push('/admin/deliveries'),
                          icon: Icons.assignment_turned_in_outlined,
                          label: '投递管理',
                        ),
                      if (canUseGraduateManagement)
                        PortalShortcutChip(
                          onPressed: () => context.push('/admin/graduates'),
                          icon: Icons.workspace_premium_outlined,
                          label: '优秀毕业生',
                        ),
                      if (canUseGrowthQuestionBank)
                        PortalShortcutChip(
                          onPressed: () =>
                              context.push('/admin/growth-question-bank'),
                          icon: Icons.inventory_2_outlined,
                          label: '共享题库',
                        ),
                      if (canUseWrittenExams)
                        PortalShortcutChip(
                          onPressed: () => context.push('/admin/written-exams'),
                          icon: Icons.fact_check_outlined,
                          label: '正式笔试',
                        ),
                      if (canUseLabInfoManagement)
                        PortalShortcutChip(
                          onPressed: () => context.push('/admin/lab-info'),
                          icon: Icons.apartment_outlined,
                          label: '实验室信息',
                        ),
                      if (canUseEquipment)
                        PortalShortcutChip(
                          onPressed: () => context.push('/admin/equipment'),
                          icon: Icons.inventory_2_outlined,
                          label: '设备管理',
                        ),
                      if (canUseWorkspace)
                        PortalShortcutChip(
                          onPressed: () => context.push('/admin/workspace'),
                          icon: Icons.folder_open_outlined,
                          label: '空间工作台',
                        ),
                      if (canUseExitAudit)
                        PortalShortcutChip(
                          onPressed: () => context.push('/admin/exit-audits'),
                          icon: Icons.rule_folder_outlined,
                          label: '退出审核',
                        ),
                    ],
                  ),
                ),
              ],
              if (_controller.latestApplications.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                LatestLabApplyPanel(items: _controller.latestApplications),
              ],
              if ((_controller.errorMessage ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                PanelCard(
                  child: Text(
                    _controller.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (overview != null) ...<Widget>[
                _MetricGrid(metrics: overview.heroMetrics),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _SectionChip(
                      label: '概览',
                      selected: _sectionIndex == 0,
                      onSelected: () => setState(() => _sectionIndex = 0),
                    ),
                    _SectionChip(
                      label: '趋势',
                      selected: _sectionIndex == 1,
                      onSelected: () => setState(() => _sectionIndex = 1),
                    ),
                    _SectionChip(
                      label: '动态',
                      selected: _sectionIndex == 2,
                      onSelected: () => setState(() => _sectionIndex = 2),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_sectionIndex),
                    child: switch (_sectionIndex) {
                      0 => _OverviewSection(overview: overview),
                      1 => _TrendSection(overview: overview),
                      _ => _ActivitySection(overview: overview),
                    },
                  ),
                ),
              ] else if (!_controller.loading) ...<Widget>[
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.query_stats_rounded,
                    title: '暂无统计内容',
                    message: '当前账号没有可展示的统计数据。',
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

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.profile,
    required this.overview,
    required this.loading,
  });

  final UserProfile? profile;
  final StatisticsOverview? overview;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final currentProfile = profile;
    final scopeName =
        overview?.scopeName ??
        (currentProfile?.schoolDirector == true
            ? '全校运营概览'
            : currentProfile?.collegeManager == true
            ? '学院运营概览'
            : currentProfile?.labManager == true
            ? '实验室运营概览'
            : '当前概览');
    final roleText = currentProfile?.schoolDirector == true
        ? '学校管理员'
        : currentProfile?.collegeManager == true
        ? '学院管理员'
        : currentProfile?.labManager == true
        ? '实验室管理员'
        : currentProfile?.roleLabel ?? '统计工作台';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF2472FF), Color(0xFF58C8FF)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
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
                  '运营总览',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                scopeName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${currentProfile?.realName ?? '当前账号'} · $roleText',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HeroChip(
                    icon: Icons.insights_rounded,
                    label: loading ? '加载中' : '实时汇总',
                  ),
                  if (overview != null)
                    _HeroChip(
                      icon: Icons.apartment_rounded,
                      label: overview!.scopeType == 'school'
                          ? '全校层级'
                          : overview!.scopeType == 'college'
                          ? '学院层级'
                          : '实验室层级',
                    ),
                  _HeroChip(
                    icon: Icons.schedule_rounded,
                    label: DateTimeFormatter.date(DateTime.now()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<StatisticsMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.sizeOf(context).width >= 760 ? 3 : 2;
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: metrics
          .map(
            (metric) => PanelCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0x142F76FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Color(0xFF2F76FF),
                    ),
                  ),
                  Text(
                    metric.label,
                    style: const TextStyle(
                      color: Color(0xFF6D7B92),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metric.value,
                    style: const TextStyle(
                      color: Color(0xFF12223A),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    metric.hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9AA4B2),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SectionChip extends StatefulWidget {
  const _SectionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  State<_SectionChip> createState() => _SectionChipState();
}

class _SectionChipState extends State<_SectionChip> {
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(widget.label),
      selected: widget.selected,
      onSelected: (_) => widget.onSelected(),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.overview});

  final StatisticsOverview overview;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];

    if (overview.isSchool) {
      cards.addAll(<Widget>[
        _SeriesPanel(
          title: '学院实验室分布',
          series: overview.collegeDistribution,
          accent: const Color(0xFF0EA5E9),
        ),
        _SeriesPanel(
          title: '实验室活跃度排行',
          series: overview.activityRanking,
          accent: const Color(0xFF8B5CF6),
        ),
        _SeriesPanel(
          title: '招新转化率排行',
          series: overview.recruitConversionRanking,
          accent: const Color(0xFF10B981),
          suffix: '%',
        ),
        _SeriesPanel(
          title: '学院综合对比',
          series: overview.collegeComparison,
          accent: const Color(0xFFF59E0B),
        ),
      ]);
    } else if (overview.isCollege) {
      cards.addAll(<Widget>[
        _SeriesPanel(
          title: '实验室活跃度排行',
          series: overview.activityRanking,
          accent: const Color(0xFF0EA5E9),
        ),
        _SeriesPanel(
          title: '申请状态分布',
          series: overview.applyStatus,
          accent: const Color(0xFFF59E0B),
        ),
        _SeriesPanel(
          title: '招新转化率排行',
          series: overview.recruitConversionRanking,
          accent: const Color(0xFF10B981),
          suffix: '%',
        ),
        _SeriesPanel(
          title: '指导老师覆盖',
          series: overview.teacherGuidanceRanking,
          accent: const Color(0xFF8B5CF6),
        ),
      ]);
    } else {
      cards.addAll(<Widget>[
        _SeriesPanel(
          title: '成员角色结构',
          series: overview.memberTypeDistribution,
          accent: const Color(0xFF0EA5E9),
        ),
        _SeriesPanel(
          title: '申请状态分布',
          series: overview.applyStatus,
          accent: const Color(0xFFF59E0B),
        ),
        _SeriesPanel(
          title: '实验室活跃构成',
          series: overview.activityRanking,
          accent: const Color(0xFF8B5CF6),
        ),
      ]);
    }

    return Column(
      children: cards
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: card,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.overview});

  final StatisticsOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _TrendCard(
          title: '申请趋势',
          series: overview.monthlyApplyTrend,
          accent: const Color(0xFF0EA5E9),
          suffix: '',
        ),
        const SizedBox(height: 16),
        _TrendCard(
          title: '出勤趋势',
          series: overview.monthlyAttendanceTrend,
          accent: const Color(0xFF10B981),
          suffix: '%',
        ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.overview});

  final StatisticsOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '待办事项',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 14),
              if (overview.pendingApprovals.isEmpty)
                const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: '暂无待办',
                  message: '当前没有需要处理的事项。',
                )
              else
                Column(
                  children: overview.pendingApprovals
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PendingRow(
                            item: item,
                            destination: _resolvePendingRoute(item),
                          ),
                        ),
                      )
                      .toList(growable: false),
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
                '最新动态',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 14),
              if (overview.recentApplies.isEmpty)
                const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: '暂无动态',
                  message: '当前没有可展示的最新申请记录。',
                )
              else
                Column(
                  children: overview.recentApplies
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ApplyRow(item: item),
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.item, this.destination});

  final StatisticsPendingItem item;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x142F76FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: Color(0xFF2F76FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF12223A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(color: Color(0xFF6D7B92), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.value.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          if (destination != null) ...<Widget>[
            const SizedBox(width: 10),
            FilledButton.tonal(
              onPressed: () => context.push(destination!),
              child: const Text('查看'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApplyRow extends StatelessWidget {
  const _ApplyRow({required this.item});

  final StatisticsRecentApply item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.how_to_reg_rounded,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.studentName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF12223A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.studentId}${item.labName == null ? '' : ' · ${item.labName}'}',
                  style: const TextStyle(color: Color(0xFF6D7B92), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusTag(status: item.status),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'submitted' => '待审核',
      'leader_approved' => '已初审',
      'college_approved' => '待终审',
      'approved' => '已通过',
      'rejected' => '已驳回',
      _ when status.isEmpty => '-',
      _ => status,
    };

    final color = switch (status) {
      'submitted' => const Color(0xFFB45309),
      'leader_approved' => const Color(0xFF2563EB),
      'college_approved' => const Color(0xFF7C3AED),
      'approved' => const Color(0xFF15803D),
      'rejected' => const Color(0xFFB42318),
      _ => const Color(0xFF475569),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SeriesPanel extends StatelessWidget {
  const _SeriesPanel({
    required this.title,
    required this.series,
    required this.accent,
    this.suffix = '',
  });

  final String title;
  final List<StatisticsSeriesItem> series;
  final Color accent;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionHeader(title: title),
          const SizedBox(height: 14),
          if (series.isEmpty)
            const EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: '暂无数据',
              message: '当前分组没有可展示的数据。',
            )
          else
            Column(
              children: series
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SeriesBar(
                        item: item,
                        accent: accent,
                        suffix: suffix,
                        maxValue: _maxValue(series),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.series,
    required this.accent,
    required this.suffix,
  });

  final String title;
  final List<StatisticsSeriesItem> series;
  final Color accent;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionHeader(title: title),
          const SizedBox(height: 14),
          if (series.isEmpty)
            const EmptyState(
              icon: Icons.show_chart_rounded,
              title: '暂无趋势',
              message: '当前没有可展示的时间趋势。',
            )
          else
            SizedBox(
              height: 220,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: series
                          .map(
                            (item) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      '${item.value.toStringAsFixed(item.value.truncateToDouble() == item.value ? 0 : 1)}$suffix',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF12223A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      height: math.max(
                                        12,
                                        120 * _ratio(item.value, series),
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: <Color>[
                                            accent.withValues(alpha: 0.92),
                                            accent.withValues(alpha: 0.68),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6D7B92),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SeriesBar extends StatelessWidget {
  const _SeriesBar({
    required this.item,
    required this.accent,
    required this.maxValue,
    required this.suffix,
  });

  final StatisticsSeriesItem item;
  final Color accent;
  final double maxValue;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final percent = maxValue <= 0 ? 0 : (item.value / maxValue * 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                item.name.isEmpty ? '-' : item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF12223A),
                ),
              ),
            ),
            Text(
              '${item.value.toStringAsFixed(item.value.truncateToDouble() == item.value ? 0 : 1)}$suffix',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF12223A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: maxValue <= 0 ? 0 : item.value / maxValue,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '相对强度 ${percent.toStringAsFixed(0)}%',
          style: const TextStyle(color: Color(0xFF9AA4B2), fontSize: 12),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
        ),
      ],
    );
  }
}

double _maxValue(List<StatisticsSeriesItem> items) {
  return items.fold<double>(0, (sum, item) => math.max(sum, item.value));
}

double _ratio(double value, List<StatisticsSeriesItem> series) {
  if (series.isEmpty) {
    return 0;
  }
  final maxValue = series.map((item) => item.value).fold<double>(0, math.max);
  if (maxValue <= 0) {
    return 0;
  }
  return value / maxValue;
}

String? _resolvePendingRoute(StatisticsPendingItem item) {
  switch (item.route) {
    case '/admin/applications':
      return '/admin/applications';
    case '/admin/teacher-register-applies':
      return '/admin/teacher-register-applies';
    case '/admin/workspace':
      return item.label.contains('退出') ? '/admin/exit-audits' : null;
    default:
      return null;
  }
}
