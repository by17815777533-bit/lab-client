import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/portal_shortcut_chip.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../auth/auth_controller.dart';
import '../../repositories/application_repository.dart';
import 'applications_controller.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  late final ApplicationsController _controller;

  static const List<_StatusFilter> _filters = <_StatusFilter>[
    _StatusFilter(label: '全部', value: null),
    _StatusFilter(label: '待审核', value: 'submitted'),
    _StatusFilter(label: '初审通过', value: 'leader_approved'),
    _StatusFilter(label: '已通过', value: 'approved'),
    _StatusFilter(label: '已驳回', value: 'rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = ApplicationsController(context.read<ApplicationRepository>());
    if (context.read<AuthController>().profile!.isStudent) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final profile = context.watch<AuthController>().profile!;
    if (!profile.isStudent) {
      return ResponsiveListView(
        children: <Widget>[
          PanelCard(
            child: Column(
              children: const <Widget>[
                EmptyState(
                  icon: Icons.workspace_premium_outlined,
                  title: '当前账号暂无申请流程',
                  message: '仅学生使用',
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final serviceShortcuts = profile.labId != null
            ? <PortalShortcutAction>[
                PortalShortcutAction(
                  onPressed: () => context.push('/student/equipment'),
                  icon: Icons.inventory_2_outlined,
                  label: '设备借用',
                ),
                PortalShortcutAction(
                  onPressed: () => context.push('/student/exit-application'),
                  icon: Icons.logout_rounded,
                  label: '退出申请',
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
              ]
            : <PortalShortcutAction>[
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
              ];

        return ResponsiveListView(
          onRefresh: _controller.load,
          children: <Widget>[
            _ApplicationsHero(
              profile: profile,
              serviceCount: serviceShortcuts.length,
              recordCount: _controller.total,
            ),
            const SizedBox(height: 16),
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '服务入口',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12223A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '常用服务',
                    style: TextStyle(color: Color(0xFF6D7B92)),
                  ),
                  const SizedBox(height: 12),
                  PortalShortcutGrid(actions: serviceShortcuts),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '申请记录',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12223A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '查看进度',
                    style: TextStyle(color: Color(0xFF6D7B92)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filters
                        .map(
                          (filter) => ChoiceChip(
                            label: Text(filter.label),
                            showCheckmark: false,
                            selected: _controller.statusFilter == filter.value,
                            onSelected: (_) =>
                                _controller.updateStatus(filter.value),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_controller.loading && _controller.items.isEmpty)
              const PanelCard(child: Center(child: CircularProgressIndicator()))
            else if (_controller.items.isEmpty)
              const PanelCard(
                child: EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: '暂无申请记录',
                  message: '当前筛选条件下没有查询到申请记录。',
                ),
              )
            else
              ..._controller.items.map((item) {
                final color = _statusColor(item.status);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 56,
                          height: 4,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                final compact = constraints.maxWidth < 360;
                                final statusBadge = Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.statusLabel,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );

                                return compact
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            item.labName ?? '未命名实验室',
                                            style: const TextStyle(
                                              fontSize: 18,
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
                                              item.labName ?? '未命名实验室',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF12223A),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          statusBadge,
                                        ],
                                      );
                              },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.planTitle ?? '未命名计划',
                          style: const TextStyle(
                            color: Color(0xFF516074),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.applyReason ?? '未填写申请理由',
                          style: const TextStyle(
                            height: 1.7,
                            color: Color(0xFF6D7B92),
                          ),
                        ),
                        if ((item.auditComment ?? '').isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '审核意见：${item.auditComment}',
                              style: const TextStyle(
                                color: Color(0xFF516074),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          '提交时间：${DateTimeFormatter.dateTime(item.createTime)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8792A6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 6),
            PanelCard(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final compact = constraints.maxWidth < 380;
                  final pageText = Text(
                    '${_controller.pageNum} / ${_controller.totalPages} · 共 ${_controller.total} 条',
                    style: const TextStyle(
                      color: Color(0xFF6D7B92),
                      fontWeight: FontWeight.w700,
                    ),
                  );

                  return compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Center(child: pageText),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _controller.pageNum > 1
                                        ? _controller.previousPage
                                        : null,
                                    child: const Text('上一页'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.tonal(
                                    onPressed:
                                        _controller.pageNum <
                                            _controller.totalPages
                                        ? _controller.nextPage
                                        : null,
                                    child: const Text('下一页'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: _controller.pageNum > 1
                                  ? _controller.previousPage
                                  : null,
                              child: const Text('上一页'),
                            ),
                            const Spacer(),
                            pageText,
                            const Spacer(),
                            FilledButton.tonal(
                              onPressed:
                                  _controller.pageNum < _controller.totalPages
                                  ? _controller.nextPage
                                  : null,
                              child: const Text('下一页'),
                            ),
                          ],
                        );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusFilter {
  const _StatusFilter({required this.label, required this.value});

  final String label;
  final String? value;
}

class _ApplicationsHero extends StatelessWidget {
  const _ApplicationsHero({
    required this.profile,
    required this.serviceCount,
    required this.recordCount,
  });

  final dynamic profile;
  final int serviceCount;
  final int recordCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 420;

        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 22,
            compact ? 18 : 22,
            compact ? 18 : 22,
            compact ? 20 : 24,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
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
                  width: compact ? 84 : 100,
                  height: compact ? 84 : 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
              Positioned(
                right: compact ? 18 : 28,
                bottom: -12,
                child: Container(
                  width: compact ? 48 : 60,
                  height: compact ? 48 : 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
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
                      '申请中心',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '我的申请',
                    style: TextStyle(
                      fontSize: compact ? 26 : 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profile.labId == null ? '先看方向，再申请' : '申请、退组和练习入口',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _HeroInfoTile(label: '服务入口', value: '$serviceCount'),
                      _HeroInfoTile(label: '申请记录', value: '$recordCount'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroInfoTile extends StatelessWidget {
  const _HeroInfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
