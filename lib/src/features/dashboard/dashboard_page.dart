import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/portal_shortcut_chip.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../features/auth/auth_controller.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/lab_repository.dart';
import '../../repositories/notice_repository.dart';
import '../../repositories/plan_repository.dart';
import 'dashboard_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthController>().profile!;
    _controller = DashboardController(
      profile: profile,
      planRepository: context.read<PlanRepository>(),
      noticeRepository: context.read<NoticeRepository>(),
      applicationRepository: context.read<ApplicationRepository>(),
      labRepository: context.read<LabRepository>(),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile!;
    final studentShortcuts = <PortalShortcutAction>[
      PortalShortcutAction(
        onPressed: () => context.push('/student/labs'),
        icon: Icons.apartment_outlined,
        label: '浏览实验室',
      ),
      PortalShortcutAction(
        onPressed: () => context.push('/student/path-guide'),
        icon: Icons.explore_outlined,
        label: '方向指南',
      ),
      PortalShortcutAction(
        onPressed: () => context.push('/student/growth-center'),
        icon: Icons.hub_outlined,
        label: '成长中心',
      ),
      PortalShortcutAction(
        onPressed: () => context.push('/student/gradpath'),
        icon: Icons.psychology_alt_outlined,
        label: '智能练习',
      ),
      PortalShortcutAction(
        onPressed: () => context.push('/student/written-exams'),
        icon: Icons.fact_check_outlined,
        label: '正式笔试',
      ),
      PortalShortcutAction(
        onPressed: () => context.push('/student/forum'),
        icon: Icons.forum_outlined,
        label: '交流论坛',
      ),
      PortalShortcutAction(
        onPressed: () => context.push('/student/applications'),
        icon: Icons.assignment_outlined,
        label: '我的申请',
      ),
    ];
    final staffShortcuts = <PortalShortcutAction>[
      PortalShortcutAction(
        onPressed: () =>
            context.push(profile.isTeacher ? '/teacher/forum' : '/admin/forum'),
        icon: Icons.forum_outlined,
        label: '交流论坛',
      ),
      PortalShortcutAction(
        onPressed: () => context.push(
          profile.isTeacher ? '/teacher/notices' : '/admin/statistics',
        ),
        icon: Icons.widgets_outlined,
        label: profile.isTeacher ? '公告资讯' : '统计工作台',
      ),
      if (!profile.isTeacher && profile.labManager)
        PortalShortcutAction(
          onPressed: () => context.push('/admin/written-exams'),
          icon: Icons.fact_check_outlined,
          label: '正式笔试',
        ),
      if (!profile.isTeacher)
        PortalShortcutAction(
          onPressed: () => context.push('/admin/growth-question-bank'),
          icon: Icons.inventory_2_outlined,
          label: '共享题库',
        ),
    ];

    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final metrics = profile.isStudent
            ? <_MetricData>[
                _MetricData(
                  label: '开放计划',
                  value: _controller.activePlans.length.toString(),
                  hint: '当前开放招新',
                  accent: const Color(0xFF2F76FF),
                  icon: Icons.campaign_outlined,
                ),
                _MetricData(
                  label: '我的申请',
                  value: _controller.myApplications.length.toString(),
                  hint: '已提交申请',
                  accent: const Color(0xFF0F9D58),
                  icon: Icons.assignment_outlined,
                ),
                _MetricData(
                  label: '待处理',
                  value: _controller.myApplications
                      .where(
                        (item) =>
                            item.status != 'approved' &&
                            item.status != 'rejected',
                      )
                      .length
                      .toString(),
                  hint: '审批中的申请',
                  accent: const Color(0xFFF59E0B),
                  icon: Icons.pending_actions_outlined,
                ),
                _MetricData(
                  label: '最新公告',
                  value: _controller.latestNotices.length.toString(),
                  hint: '当前可见公告',
                  accent: const Color(0xFF7C3AED),
                  icon: Icons.notifications_none_rounded,
                ),
              ]
            : <_MetricData>[
                _MetricData(
                  label: '实验室总数',
                  value: (_controller.labStats?.total ?? 0).toString(),
                  hint: '当前实验室数量',
                  accent: const Color(0xFF2F76FF),
                  icon: Icons.apartment_outlined,
                ),
                _MetricData(
                  label: '开放计划',
                  value: _controller.activePlans.length.toString(),
                  hint: '当前开放计划',
                  accent: const Color(0xFF0F9D58),
                  icon: Icons.campaign_outlined,
                ),
                _MetricData(
                  label: '最新公告',
                  value: _controller.latestNotices.length.toString(),
                  hint: '当前公告数量',
                  accent: const Color(0xFF7C3AED),
                  icon: Icons.notifications_none_rounded,
                ),
                _MetricData(
                  label: '当前身份',
                  value: profile.primaryIdentity ?? profile.roleLabel,
                  hint: '当前门户身份',
                  accent: const Color(0xFF0369A1),
                  icon: Icons.badge_outlined,
                ),
              ];

        return ResponsiveListView(
          onRefresh: _controller.load,
          children: <Widget>[
            _DashboardHero(
              title: profile.isStudent
                  ? '学生工作台'
                  : profile.isTeacher
                  ? '教师工作台'
                  : '管理工作台',
              subtitle: profile.isStudent ? '查看计划和申请' : '处理实验室与审批',
              identity: profile.realName,
              accent: profile.labId == null
                  ? '当前未加入实验室'
                  : '已绑定实验室 #${profile.labId}',
            ),
            const SizedBox(height: 16),
            _MetricGrid(metrics: metrics),
            if (profile.isStudent) ...<Widget>[
              const SizedBox(height: 16),
              PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _SectionTitle(title: '快捷入口', subtitle: '常用功能'),
                    const SizedBox(height: 14),
                    PortalShortcutGrid(actions: studentShortcuts),
                  ],
                ),
              ),
            ],
            if (!profile.isStudent) ...<Widget>[
              const SizedBox(height: 16),
              PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _SectionTitle(title: '常用入口', subtitle: '常用功能'),
                    const SizedBox(height: 14),
                    PortalShortcutGrid(actions: staffShortcuts),
                  ],
                ),
              ),
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
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _SectionTitle(
                    title: '开放招新计划',
                    subtitle: '集中查看当前开放中的招新计划',
                  ),
                  const SizedBox(height: 14),
                  if (_controller.loading && _controller.activePlans.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (_controller.activePlans.isEmpty)
                    const EmptyState(
                      icon: Icons.event_busy_rounded,
                      title: '暂无开放计划',
                      message: '当前没有可申请的招新计划。',
                    )
                  else
                    Column(
                      children: _controller.activePlans
                          .take(4)
                          .map(
                            (plan) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _InfoListTile(
                                title: plan.title,
                                subtitle:
                                    '${plan.labName ?? '未命名实验室'} · ${plan.collegeName ?? '未分配学院'}',
                                trailing: '${plan.quota} 人',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _SectionTitle(
                    title: '最新公告',
                    subtitle: '学校、学院和实验室范围内的最新通知',
                  ),
                  const SizedBox(height: 14),
                  if (_controller.loading && _controller.latestNotices.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (_controller.latestNotices.isEmpty)
                    const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: '暂无公告',
                      message: '当前没有可展示的公告内容。',
                    )
                  else
                    Column(
                      children: _controller.latestNotices
                          .map(
                            (notice) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _NoticePreviewCard(
                                title: notice.title,
                                scope: notice.scopeLabel,
                                content: notice.content,
                                time: DateTimeFormatter.dateTime(
                                  notice.publishTime,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
            if (profile.isStudent) ...<Widget>[
              const SizedBox(height: 16),
              PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _SectionTitle(title: '我的申请记录', subtitle: '最近进度'),
                    const SizedBox(height: 14),
                    if (_controller.loading &&
                        _controller.myApplications.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (_controller.myApplications.isEmpty)
                      const EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: '暂无申请',
                        message: '你还没有提交过实验室申请。',
                      )
                    else
                      Column(
                        children: _controller.myApplications
                            .map(
                              (application) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ApplicationPreviewCard(
                                  application: application,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.title,
    required this.subtitle,
    required this.identity,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String identity;
  final String accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 430;
        final infoCard = Container(
          width: compact ? double.infinity : null,
          constraints: BoxConstraints(
            minWidth: compact ? 0 : 150,
            maxWidth: compact ? constraints.maxWidth : 190,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                identity,
                style: TextStyle(
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                accent,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

        return Container(
          padding: EdgeInsets.all(compact ? 18 : 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF2472FF), Color(0xFF59C8FF)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                right: -18,
                top: -18,
                child: Container(
                  width: compact ? 88 : 110,
                  height: compact ? 88 : 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(34),
                  ),
                ),
              ),
              Positioned(
                right: compact ? 22 : 44,
                bottom: -20,
                child: Container(
                  width: compact ? 56 : 66,
                  height: compact ? 56 : 66,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _HeroBadge(label: '今日工作台'),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: 16),
                        infoCard,
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const _HeroBadge(label: '今日工作台'),
                              const SizedBox(height: 14),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        infoCard,
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final itemWidth = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 12 * 3) / 4
            : (constraints.maxWidth - 12) / 2;
        final compact = constraints.maxWidth < 420;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: SizedBox(
                    height: compact ? 110 : 116,
                    child: PanelCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF6D7B92),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: item.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  item.icon,
                                  size: 18,
                                  color: item.accent,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            item.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 26 : 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF12223A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.hint,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              height: 1.45,
                              color: Color(0xFF9AA7BA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

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
        Text(subtitle, style: const TextStyle(color: Color(0xFF8792A6))),
      ],
    );
  }
}

class _InfoListTile extends StatelessWidget {
  const _InfoListTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 360;
        final trailingBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x142F76FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            trailing,
            style: const TextStyle(
              color: Color(0xFF2F76FF),
              fontWeight: FontWeight.w800,
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5ECF8)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF6D7B92)),
                    ),
                    const SizedBox(height: 12),
                    trailingBadge,
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(
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
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: const TextStyle(color: Color(0xFF6D7B92)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    trailingBadge,
                  ],
                ),
        );
      },
    );
  }
}

class _NoticePreviewCard extends StatelessWidget {
  const _NoticePreviewCard({
    required this.title,
    required this.scope,
    required this.content,
    required this.time,
  });

  final String title;
  final String scope;
  final String content;
  final String time;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 360;
        final scopeBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x142F76FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            scope,
            style: const TextStyle(
              color: Color(0xFF2F76FF),
              fontWeight: FontWeight.w800,
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5ECF8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        scopeBadge,
                        const SizedBox(height: 10),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8792A6),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        scopeBadge,
                        const Spacer(),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8792A6),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(height: 1.65, color: Color(0xFF516074)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ApplicationPreviewCard extends StatelessWidget {
  const _ApplicationPreviewCard({required this.application});

  final dynamic application;

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF0F9D58);
      case 'rejected':
        return const Color(0xFFE53935);
      case 'leader_approved':
        return const Color(0xFF2F76FF);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(application.status as String);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 360;
        final statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            application.statusLabel as String,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5ECF8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          application.labName?.toString() ?? '未命名实验室',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12223A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        statusBadge,
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            application.labName?.toString() ?? '未命名实验室',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12223A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        statusBadge,
                      ],
                    ),
              const SizedBox(height: 8),
              Text(
                application.planTitle?.toString() ?? '未命名计划',
                style: const TextStyle(color: Color(0xFF516074)),
              ),
              const SizedBox(height: 8),
              Text(
                application.applyReason?.toString() ?? '未填写申请理由',
                style: const TextStyle(height: 1.65, color: Color(0xFF6D7B92)),
              ),
              const SizedBox(height: 10),
              Text(
                DateTimeFormatter.dateTime(application.createTime as DateTime?),
                style: const TextStyle(fontSize: 12, color: Color(0xFF8792A6)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.hint,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final String hint;
  final Color accent;
  final IconData icon;
}
