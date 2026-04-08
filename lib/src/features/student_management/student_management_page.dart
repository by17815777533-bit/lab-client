import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/utils/file_url_resolver.dart';
import '../../core/utils/url_launcher_helper.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/admin_student_record.dart';
import '../../models/user_profile.dart';
import 'student_management_controller.dart';

class StudentManagementPage extends ConsumerStatefulWidget {
  const StudentManagementPage({super.key});

  @override
  ConsumerState<StudentManagementPage> createState() =>
      _StudentManagementPageState();
}

class _StudentManagementPageState extends ConsumerState<StudentManagementPage> {
  late final StudentManagementController _controller;
  late final UserProfile _profile;
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _realNameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = ref.read(authControllerProvider).profile!;
    _controller = StudentManagementController(
      repository: ref.read(studentManagementRepositoryProvider),
      profile: _profile,
    )..load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _realNameController.dispose();
    _studentIdController.dispose();
    _majorController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    _controller.updateFilters(
      keyword: _keywordController.text,
      realName: _realNameController.text,
      studentId: _studentIdController.text,
      major: _majorController.text,
    );
    await _controller.search();
  }

  Future<void> _resetSearch() async {
    _keywordController.clear();
    _realNameController.clear();
    _studentIdController.clear();
    _majorController.clear();
    _controller.resetFilters();
    await _controller.load();
  }

  void _openDeliveries(AdminStudentRecord student) {
    context.push(
      '/admin/deliveries?studentId=${Uri.encodeComponent(student.displayStudentId)}'
      '&realName=${Uri.encodeComponent(student.realName)}',
    );
  }

  Future<void> _openStudentDetail(
    AdminStudentRecord student,
    String baseUrl,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _StudentDetailSheet(
          student: student,
          baseUrl: baseUrl,
          onViewDeliveries: () {
            Navigator.of(context).pop();
            _openDeliveries(student);
          },
        );
      },
    );
  }

  Future<void> _deleteStudent(AdminStudentRecord student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除学生账号'),
          content: Text('确认删除 ${student.realName} 的账号吗？删除后无法恢复。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D),
              ),
              child: const Text('确认删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await _controller.deleteStudent(student.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '学生账号已删除' : _controller.errorMessage ?? '删除失败'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.watch(appSettingsControllerProvider).baseUrl;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final students = _controller.students;
        final totalDeliveries = students.fold<int>(
          0,
          (int sum, AdminStudentRecord item) => sum + item.totalDeliveries,
        );
        final pendingTotal = students.fold<int>(
          0,
          (int sum, AdminStudentRecord item) => sum + item.pendingCount,
        );
        final resumeCount = students.where((item) => item.hasResume).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(_profile.schoolDirector ? '学生管理' : '投递学生'),
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
              _StudentHeroBanner(
                profile: _profile,
                total: _controller.total,
                pendingTotal: pendingTotal,
                totalDeliveries: totalDeliveries,
                scopedToLab: _controller.scopedToLab,
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
              PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '筛选条件',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _FilterField(
                          controller: _keywordController,
                          label: '关键词',
                          hint: '姓名或学号',
                          icon: Icons.search_rounded,
                          onSubmitted: (_) => _runSearch(),
                        ),
                        _FilterField(
                          controller: _realNameController,
                          label: '学生姓名',
                          hint: '请输入学生姓名',
                          icon: Icons.badge_outlined,
                          onSubmitted: (_) => _runSearch(),
                        ),
                        _FilterField(
                          controller: _studentIdController,
                          label: '学号',
                          hint: '请输入学号',
                          icon: Icons.perm_identity_outlined,
                          onSubmitted: (_) => _runSearch(),
                        ),
                        _FilterField(
                          controller: _majorController,
                          label: '专业',
                          hint: '请输入专业',
                          icon: Icons.school_outlined,
                          onSubmitted: (_) => _runSearch(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: _controller.loading ? null : _runSearch,
                          icon: const Icon(Icons.travel_explore_rounded),
                          label: const Text('查询'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _controller.loading ? null : _resetSearch,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('重置'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _SummaryTile(
                    title: '当前学生',
                    value: '${_controller.total}',
                    subtitle: _controller.scopedToLab ? '当前实验室范围' : '当前可见范围',
                    accent: const Color(0xFF1D4ED8),
                    icon: Icons.groups_2_outlined,
                  ),
                  _SummaryTile(
                    title: '待处理投递',
                    value: '$pendingTotal',
                    subtitle: '当前页待审核记录',
                    accent: const Color(0xFFF59E0B),
                    icon: Icons.pending_actions_outlined,
                  ),
                  _SummaryTile(
                    title: '投递总量',
                    value: '$totalDeliveries',
                    subtitle: '当前页累计投递',
                    accent: const Color(0xFF0F766E),
                    icon: Icons.assessment_outlined,
                  ),
                  _SummaryTile(
                    title: '资料齐全',
                    value: '$resumeCount',
                    subtitle: '已上传简历人数',
                    accent: const Color(0xFF7C3AED),
                    icon: Icons.description_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            '学生列表',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12223A),
                            ),
                          ),
                        ),
                        Text(
                          '${_controller.total} 人',
                          style: const TextStyle(
                            color: Color(0xFF6D7B92),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_controller.loading && students.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (students.isEmpty)
                      EmptyState(
                        icon: Icons.group_outlined,
                        title: _controller.scopedToLab ? '当前还没有投递学生' : '暂无学生记录',
                        message: _controller.scopedToLab
                            ? '当前实验室下还没有可展示的投递学生。'
                            : '当前条件下没有匹配到学生记录。',
                      )
                    else
                      Column(
                        children: students
                            .map(
                              (AdminStudentRecord student) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _StudentCard(
                                  student: student,
                                  canDelete: _controller.canDeleteStudents,
                                  deleting: _controller.deleting,
                                  onViewDetail: () =>
                                      _openStudentDetail(student, baseUrl),
                                  onViewDeliveries: () =>
                                      _openDeliveries(student),
                                  onDelete: () => _deleteStudent(student),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    if (_controller.totalPages > 1) ...<Widget>[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          OutlinedButton(
                            onPressed: _controller.pageNum > 1
                                ? _controller.previousPage
                                : null,
                            child: const Text('上一页'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${_controller.pageNum} / ${_controller.totalPages}',
                              style: const TextStyle(
                                color: Color(0xFF475467),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed:
                                _controller.pageNum < _controller.totalPages
                                ? _controller.nextPage
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
          ),
        );
      },
    );
  }
}

class _StudentHeroBanner extends StatelessWidget {
  const _StudentHeroBanner({
    required this.profile,
    required this.total,
    required this.pendingTotal,
    required this.totalDeliveries,
    required this.scopedToLab,
  });

  final UserProfile profile;
  final int total;
  final int pendingTotal;
  final int totalDeliveries;
  final bool scopedToLab;

  @override
  Widget build(BuildContext context) {
    final title = profile.schoolDirector ? '学生管理总览' : '实验室投递学生';
    final subtitle = profile.schoolDirector
        ? '支持查看学生资料、投递进展与账号治理'
        : '当前仅展示与本实验室相关的投递学生记录';

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1D4ED8), Color(0xFF4F8CFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _HeroPill(icon: Icons.groups_rounded, label: '学生 $total'),
              _HeroPill(
                icon: Icons.pending_actions_rounded,
                label: '待处理 $pendingTotal',
              ),
              _HeroPill(
                icon: Icons.assignment_outlined,
                label: '投递 $totalDeliveries',
              ),
              _HeroPill(
                icon: Icons.verified_user_outlined,
                label: scopedToLab ? '实验室范围' : profile.roleLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 230),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: accent.withValues(alpha: 0.08),
          border: Border.all(color: accent.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: accent),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF475467),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF12223A),
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.canDelete,
    required this.deleting,
    required this.onViewDetail,
    required this.onViewDeliveries,
    required this.onDelete,
  });

  final AdminStudentRecord student;
  final bool canDelete;
  final bool deleting;
  final VoidCallback onViewDetail;
  final VoidCallback onViewDeliveries;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF7F9FD),
        border: Border.all(color: const Color(0xFFE3EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDCEBFF),
                child: Text(
                  student.initials,
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      student.realName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student.displayStudentId} · ${student.major ?? '未填写专业'}',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.college ?? '未填写学院',
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _CountBadge(
                label: '简历',
                value: student.hasResume ? '已上传' : '未上传',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _StatusChip(
                label: '待审核 ${student.pendingCount}',
                background: const Color(0xFFFFF4D6),
                foreground: const Color(0xFFB54708),
              ),
              _StatusChip(
                label: '已通过 ${student.approvedCount}',
                background: const Color(0xFFDFF7EA),
                foreground: const Color(0xFF067647),
              ),
              _StatusChip(
                label: '已拒绝 ${student.rejectedCount}',
                background: const Color(0xFFFDE7EA),
                foreground: const Color(0xFFB42318),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: <Widget>[
              _InfoText(
                icon: Icons.mail_outline_rounded,
                text: student.email ?? '未填写邮箱',
              ),
              _InfoText(
                icon: Icons.phone_outlined,
                text: student.phone ?? '未填写电话',
              ),
              _InfoText(
                icon: Icons.schedule_outlined,
                text: '注册于 ${DateTimeFormatter.dateTime(student.createTime)}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: onViewDetail,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('查看资料'),
              ),
              FilledButton.tonalIcon(
                onPressed: onViewDeliveries,
                icon: const Icon(Icons.work_history_outlined),
                label: const Text('投递记录'),
              ),
              if (canDelete)
                TextButton.icon(
                  onPressed: deleting ? null : onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB42318),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('删除账号'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentDetailSheet extends StatelessWidget {
  const _StudentDetailSheet({
    required this.student,
    required this.baseUrl,
    required this.onViewDeliveries,
  });

  final AdminStudentRecord student;
  final String baseUrl;
  final VoidCallback onViewDeliveries;

  @override
  Widget build(BuildContext context) {
    final resumeUrl = student.canPreviewResume
        ? FileUrlResolver.resolve(baseUrl: baseUrl, rawUrl: student.resume)
        : '';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFDCEBFF),
                  child: Text(
                    student.initials,
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        student.realName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12223A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.displayStudentId,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _DetailLine(label: '学院', value: student.college ?? '未填写'),
            _DetailLine(label: '专业', value: student.major ?? '未填写'),
            _DetailLine(label: '年级', value: student.grade ?? '未填写'),
            _DetailLine(label: '邮箱', value: student.email ?? '未填写'),
            _DetailLine(label: '电话', value: student.phone ?? '未填写'),
            _DetailLine(
              label: '注册时间',
              value: DateTimeFormatter.dateTime(student.createTime),
            ),
            _DetailLine(
              label: '更新时间',
              value: DateTimeFormatter.dateTime(student.updateTime),
            ),
            _DetailLine(
              label: '投递统计',
              value:
                  '待审核 ${student.pendingCount} / 已通过 ${student.approvedCount} / 已拒绝 ${student.rejectedCount}',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: onViewDeliveries,
                  icon: const Icon(Icons.work_history_outlined),
                  label: const Text('查看投递'),
                ),
                if (resumeUrl.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: () => openExternalLink(context, resumeUrl),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('查看简历'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: null,
                    icon: const Icon(Icons.description_outlined),
                    label: Text(student.hasResume ? '简历暂不可预览' : '未上传简历'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF98A2B3),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF12223A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFF98A2B3)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF12223A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
