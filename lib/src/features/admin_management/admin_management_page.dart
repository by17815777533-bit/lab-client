import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/user_profile.dart';
import 'admin_management_controller.dart';
import 'admin_management_models.dart';

class AdminManagementPage extends ConsumerStatefulWidget {
  const AdminManagementPage({super.key});

  @override
  ConsumerState<AdminManagementPage> createState() =>
      _AdminManagementPageState();
}

class _AdminManagementPageState extends ConsumerState<AdminManagementPage> {
  late final AdminManagementController _controller;
  late final UserProfile _profile;
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = ref.read(authControllerProvider).profile!;
    _controller = AdminManagementController(
      repository: ref.read(adminManagementRepositoryProvider),
    )..load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    _controller.setKeyword(_keywordController.text);
  }

  Future<void> _openAssignSheet(LabAdminAssignment item) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _AssignAdminSheet(
          assignment: item,
          students: _controller.students,
          onSubmit: (AdminManagerUser user) async {
            final assigned = await _controller.assignAdmin(
              labId: item.lab.id,
              userId: user.id,
            );
            if (assigned) {
              return null;
            }
            return _controller.errorMessage ?? '指定失败，请稍后重试';
          },
        );
      },
    );

    if (!mounted || success != true) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('管理员已更新')));
  }

  Future<void> _removeAdmin(LabAdminAssignment item) async {
    final currentAdminName = item.admin?.realName ?? '当前管理员';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('移除管理员'),
          content: Text(
            '确认移除 ${item.lab.labName} 的管理员 $currentAdminName 吗？移除后该账号会恢复学生身份。',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child: const Text('确认移除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await _controller.removeAdmin(item.lab.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '管理员已移除' : _controller.errorMessage ?? '移除失败'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPermission = _profile.schoolDirector;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final assignments = _controller.assignments;
        final assignedCount = assignments
            .where((item) => item.admin != null)
            .length;
        final pendingCount = assignments.length - assignedCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text('管理员分配'),
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
              _HeroCard(
                profile: _profile,
                total: assignments.length,
                assignedCount: assignedCount,
                pendingCount: pendingCount,
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
              if (!hasPermission)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: '当前账号暂不可使用',
                    message: '只有学校管理员可以管理实验室管理员分配。',
                  ),
                )
              else ...<Widget>[
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '实验室筛选',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12223A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _keywordController,
                        decoration: const InputDecoration(
                          labelText: '关键词',
                          hintText: '实验室名称 / 描述 / 管理员',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: _controller.setKeyword,
                        onSubmitted: (_) => _search(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  total: assignments.length,
                  assigned: assignedCount,
                  pending: pendingCount,
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
                              '实验室列表',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF12223A),
                              ),
                            ),
                          ),
                          Text(
                            '${assignments.length} 个实验室',
                            style: const TextStyle(
                              color: Color(0xFF6D7B92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_controller.loading && assignments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (assignments.isEmpty)
                        const EmptyState(
                          icon: Icons.apartment_outlined,
                          title: '暂无实验室数据',
                          message: '当前没有可分配管理员的实验室记录。',
                        )
                      else
                        Column(
                          children: assignments
                              .map(
                                (LabAdminAssignment item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _AssignmentCard(
                                    item: item,
                                    assigning: _controller.assigning,
                                    removing: _controller.removing,
                                    onAssign: () => _openAssignSheet(item),
                                    onRemove: item.admin == null
                                        ? null
                                        : () => _removeAdmin(item),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
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
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.total,
    required this.assignedCount,
    required this.pendingCount,
  });

  final UserProfile profile;
  final int total;
  final int assignedCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF2D78FF), Color(0xFF5CCBFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '实验室管理员安排',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.realName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '为实验室指定学生管理员，并及时处理管理员变更。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _HeroPill(label: profile.roleLabel),
              _HeroPill(label: '实验室 $total 个'),
              _HeroPill(label: '已配置 $assignedCount 个'),
              _HeroPill(label: '待分配 $pendingCount 个'),
            ],
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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.total,
    required this.assigned,
    required this.pending,
  });

  final int total;
  final int assigned;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryCardData>[
      _SummaryCardData(label: '实验室总数', value: '$total'),
      _SummaryCardData(label: '已配置管理员', value: '$assigned'),
      _SummaryCardData(label: '待分配', value: '$pending'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map(
            (item) => SizedBox(
              width: 160,
              child: PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFF6D7B92),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: Color(0xFF12223A),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({required this.label, required this.value});

  final String label;
  final String value;
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.item,
    required this.assigning,
    required this.removing,
    this.onAssign,
    this.onRemove,
  });

  final LabAdminAssignment item;
  final bool assigning;
  final bool removing;
  final VoidCallback? onAssign;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasAdmin = item.admin != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
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
                      item.lab.labName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.lab.labDesc ?? '暂无实验室简介',
                      style: const TextStyle(
                        color: Color(0xFF6D7B92),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: hasAdmin ? '已配置' : '待分配',
                color: hasAdmin
                    ? const Color(0xFF059669)
                    : const Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: <Widget>[
              if ((item.lab.location ?? '').isNotEmpty)
                _InfoPill(
                  icon: Icons.place_outlined,
                  label: item.lab.location!,
                ),
              if ((item.lab.currentAdmins ?? '').isNotEmpty)
                _InfoPill(
                  icon: Icons.badge_outlined,
                  label: item.lab.currentAdmins!,
                ),
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: DateTimeFormatter.date(item.lab.updateTime),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (item.admin == null)
            const Text(
              '当前还没有绑定实验室管理员。',
              style: TextStyle(
                color: Color(0xFF4A5567),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.admin!.realName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.admin!.username} · ${item.admin!.email ?? '未填写邮箱'}',
                  style: const TextStyle(color: Color(0xFF6D7B92)),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: assigning ? null : onAssign,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(hasAdmin ? '重新指定' : '指定管理员'),
              ),
              if (hasAdmin)
                OutlinedButton.icon(
                  onPressed: removing ? null : onRemove,
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('移除'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF2F76FF)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4A5567),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignAdminSheet extends StatefulWidget {
  const _AssignAdminSheet({
    required this.assignment,
    required this.students,
    required this.onSubmit,
  });

  final LabAdminAssignment assignment;
  final List<AdminManagerUser> students;
  final Future<String?> Function(AdminManagerUser user) onSubmit;

  @override
  State<_AssignAdminSheet> createState() => _AssignAdminSheetState();
}

class _AssignAdminSheetState extends State<_AssignAdminSheet> {
  final TextEditingController _keywordController = TextEditingController();
  AdminManagerUser? _selectedUser;
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  List<AdminManagerUser> get _candidates {
    final normalized = _keywordController.text.trim().toLowerCase();
    if (normalized.isEmpty) {
      return widget.students;
    }
    return widget.students
        .where((AdminManagerUser item) {
          return item.realName.toLowerCase().contains(normalized) ||
              item.username.toLowerCase().contains(normalized) ||
              (item.studentId ?? '').toLowerCase().contains(normalized) ||
              (item.college ?? '').toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  Future<void> _submit() async {
    final selectedUser = _selectedUser;
    if (selectedUser == null) {
      setState(() {
        _errorText = '请选择要指定的学生';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final error = await widget.onSubmit(selectedUser);
    if (!mounted) {
      return;
    }

    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _errorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final candidates = _candidates;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              widget.assignment.lab.labName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12223A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.assignment.admin == null
                  ? '请选择一位学生作为实验室管理员。'
                  : '当前管理员：${widget.assignment.admin!.realName}，重新指定后原管理员会恢复学生身份。',
              style: const TextStyle(color: Color(0xFF6D7B92), height: 1.5),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _keywordController,
              decoration: const InputDecoration(
                labelText: '搜索学生',
                hintText: '姓名 / 学号 / 账号 / 学院',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Container(
              constraints: const BoxConstraints(maxHeight: 360),
              child: candidates.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search_outlined,
                      title: '暂无可选学生',
                      message: '当前条件下没有可指定为管理员的学生。',
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: candidates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final item = candidates[index];
                        final selected = _selectedUser?.id == item.id;
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => setState(() => _selectedUser = item),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0x142F76FF)
                                  : const Color(0xFFF9FBFF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF2F76FF)
                                    : const Color(0xFFE6ECF5),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        item.realName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF12223A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.studentId ?? item.username} · ${item.college ?? '-'}',
                                        style: const TextStyle(
                                          color: Color(0xFF6D7B92),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _selectedUser?.id == item.id
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: _selectedUser?.id == item.id
                                      ? const Color(0xFF2F76FF)
                                      : const Color(0xFFA7B2C4),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if ((_errorText ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                _errorText!,
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('确认指定'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
