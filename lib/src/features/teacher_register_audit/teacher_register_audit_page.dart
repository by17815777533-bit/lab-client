import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/user_profile.dart';
import 'teacher_register_audit_controller.dart';
import 'teacher_register_audit_models.dart';

class TeacherRegisterAuditPage extends ConsumerStatefulWidget {
  const TeacherRegisterAuditPage({super.key});

  @override
  ConsumerState<TeacherRegisterAuditPage> createState() =>
      _TeacherRegisterAuditPageState();
}

class _TeacherRegisterAuditPageState
    extends ConsumerState<TeacherRegisterAuditPage> {
  late final TeacherRegisterAuditController _controller;
  late final TextEditingController _keywordController;

  @override
  void initState() {
    super.initState();
    _controller = TeacherRegisterAuditController(
      ref.read(teacherRegisterAuditRepositoryProvider),
    )..load();
    _keywordController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  bool _canUseModule(UserProfile? profile) {
    return profile?.schoolDirector == true || profile?.collegeManager == true;
  }

  Future<void> _submitAudit({
    required TeacherRegisterAuditRecord record,
    required String action,
    required String title,
  }) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _AuditSheet(
          title: title,
          record: record,
          action: action,
          onSubmit: (String remark) => _controller.audit(
            id: record.id,
            action: action,
            auditComment: remark,
          ),
        );
      },
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${record.realName} 的申请已处理')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).profile;
    final canUseModule = _canUseModule(profile);
    final isSuperAdmin = profile?.schoolDirector == true;

    if (profile == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final records = _controller.records;
        final submittedCount = records.where((item) => item.isSubmitted).length;
        final collegeApprovedCount = records
            .where((item) => item.isCollegeApproved)
            .length;
        final approvedCount = records.where((item) => item.isApproved).length;
        final rejectedCount = records.where((item) => item.isRejected).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('教师注册审核'),
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
                profile: profile,
                canUseModule: canUseModule,
                scopeLabel: isSuperAdmin ? '学校级审核' : '学院级审核',
              ),
              const SizedBox(height: 16),
              if (!canUseModule)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: '当前账号无审核权限',
                    message: '只有学院管理员和学校管理员可以进入教师注册审核流程。',
                  ),
                )
              else ...<Widget>[
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
                      TextField(
                        controller: _keywordController,
                        decoration: const InputDecoration(
                          labelText: '关键词',
                          hintText: '工号 / 姓名 / 邮箱 / 学院',
                          prefixIcon: Icon(Icons.manage_search_rounded),
                        ),
                        onChanged: _controller.setKeyword,
                        onSubmitted: (String value) {
                          _controller.setKeyword(value);
                          _controller.load();
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          ChoiceChip(
                            label: const Text('全部'),
                            selected: _controller.statusFilter == null,
                            onSelected: (_) {
                              _controller.setStatusFilter(null);
                              _controller.load();
                            },
                          ),
                          ChoiceChip(
                            label: const Text('待学院审核'),
                            selected: _controller.statusFilter == 'submitted',
                            onSelected: (_) {
                              _controller.setStatusFilter('submitted');
                              _controller.load();
                            },
                          ),
                          ChoiceChip(
                            label: const Text('待学校审核'),
                            selected:
                                _controller.statusFilter == 'college_approved',
                            onSelected: (_) {
                              _controller.setStatusFilter('college_approved');
                              _controller.load();
                            },
                          ),
                          ChoiceChip(
                            label: const Text('已通过'),
                            selected: _controller.statusFilter == 'approved',
                            onSelected: (_) {
                              _controller.setStatusFilter('approved');
                              _controller.load();
                            },
                          ),
                          ChoiceChip(
                            label: const Text('已驳回'),
                            selected: _controller.statusFilter == 'rejected',
                            onSelected: (_) {
                              _controller.setStatusFilter('rejected');
                              _controller.load();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          FilledButton(
                            onPressed: _controller.loading
                                ? null
                                : _controller.load,
                            child: const Text('查询'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: _controller.loading
                                ? null
                                : () {
                                    _keywordController.clear();
                                    _controller.resetFilters();
                                    _controller.load();
                                  },
                            child: const Text('重置'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  total: _controller.total,
                  submitted: submittedCount,
                  collegeApproved: collegeApprovedCount,
                  approved: approvedCount,
                  rejected: rejectedCount,
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
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              '审核列表',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF12223A),
                              ),
                            ),
                          ),
                          Text(
                            '共 ${_controller.total} 条',
                            style: const TextStyle(
                              color: Color(0xFF6D7B92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_controller.loading && records.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (records.isEmpty)
                        const EmptyState(
                          icon: Icons.inbox_outlined,
                          title: '暂无待处理内容',
                          message: '当前筛选条件下没有可处理的教师注册申请。',
                        )
                      else
                        Column(
                          children: records
                              .map(
                                (record) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _RecordCard(
                                    record: record,
                                    canCollegeApprove:
                                        record.canCollegeApprove &&
                                        !isSuperAdmin,
                                    canSchoolApprove:
                                        record.canSchoolApprove && isSuperAdmin,
                                    canReject: isSuperAdmin
                                        ? record.isSubmitted ||
                                              record.isCollegeApproved
                                        : record.isSubmitted,
                                    onCollegeApprove:
                                        record.canCollegeApprove &&
                                            !isSuperAdmin
                                        ? () => _submitAudit(
                                            record: record,
                                            action: 'collegeApprove',
                                            title: '学院审核通过',
                                          )
                                        : null,
                                    onSchoolApprove:
                                        record.canSchoolApprove && isSuperAdmin
                                        ? () => _submitAudit(
                                            record: record,
                                            action: 'schoolApprove',
                                            title: '学校审核通过',
                                          )
                                        : null,
                                    onReject:
                                        (isSuperAdmin
                                            ? record.isSubmitted ||
                                                  record.isCollegeApproved
                                            : record.isSubmitted)
                                        ? () => _submitAudit(
                                            record: record,
                                            action: 'reject',
                                            title: '驳回申请',
                                          )
                                        : null,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      if (_controller.totalPages > 1) ...<Widget>[
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: _controller.pageNum > 1
                                  ? _controller.previousPage
                                  : null,
                              child: const Text('上一页'),
                            ),
                            const Spacer(),
                            Text(
                              '${_controller.pageNum} / ${_controller.totalPages}',
                              style: const TextStyle(
                                color: Color(0xFF6D7B92),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
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
    required this.canUseModule,
    required this.scopeLabel,
  });

  final UserProfile profile;
  final bool canUseModule;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF312E81), Color(0xFF4F46E5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '教师注册审核',
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
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canUseModule ? '按学院和学校两级流程处理教师注册申请，处理结果会同步到申请记录。' : '当前账号暂无审核权限。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _MiniPill(label: profile.roleLabel),
              _MiniPill(label: scopeLabel),
              _MiniPill(label: canUseModule ? '可审核' : '无权限'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

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
    required this.submitted,
    required this.collegeApproved,
    required this.approved,
    required this.rejected,
  });

  final int total;
  final int submitted;
  final int collegeApproved;
  final int approved;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryCardData>[
      _SummaryCardData(label: '总记录', value: total.toString()),
      _SummaryCardData(label: '待学院审核', value: submitted.toString()),
      _SummaryCardData(label: '待学校审核', value: collegeApproved.toString()),
      _SummaryCardData(label: '已通过', value: approved.toString()),
      _SummaryCardData(label: '已驳回', value: rejected.toString()),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map(
            (card) => SizedBox(
              width: 160,
              child: PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      card.label,
                      style: const TextStyle(
                        color: Color(0xFF6D7B92),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.value,
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.canCollegeApprove,
    required this.canSchoolApprove,
    required this.canReject,
    required this.onCollegeApprove,
    required this.onSchoolApprove,
    required this.onReject,
  });

  final TeacherRegisterAuditRecord record;
  final bool canCollegeApprove;
  final bool canSchoolApprove;
  final bool canReject;
  final VoidCallback? onCollegeApprove;
  final VoidCallback? onSchoolApprove;
  final VoidCallback? onReject;

  Color get _statusColor {
    switch (record.status) {
      case 'approved':
        return const Color(0xFF0F9D58);
      case 'rejected':
        return const Color(0xFFE53935);
      case 'college_approved':
        return const Color(0xFF2F76FF);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color get _statusBackground {
    switch (record.status) {
      case 'approved':
        return const Color(0x140F9D58);
      case 'rejected':
        return const Color(0x14E53935);
      case 'college_approved':
        return const Color(0x142F76FF);
      default:
        return const Color(0x14F59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                      record.realName.isNotEmpty
                          ? record.realName
                          : record.teacherNo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.teacherNo} · ${record.collegeName ?? '未分配学院'}',
                      style: const TextStyle(color: Color(0xFF6D7B92)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoLine(label: '邮箱', value: record.email),
          _InfoLine(label: '手机号', value: record.phone ?? '-'),
          _InfoLine(label: '职称', value: record.title ?? '-'),
          _InfoLine(label: '申请说明', value: record.applyReason ?? '-'),
          _InfoLine(
            label: '提交时间',
            value: DateTimeFormatter.dateTime(record.createTime),
          ),
          if ((record.collegeAuditComment ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            _CommentBox(
              title: '学院审核意见',
              content: record.collegeAuditComment!,
              time: record.collegeAuditTime,
            ),
          ],
          if ((record.schoolAuditComment ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _CommentBox(
              title: '学校审核意见',
              content: record.schoolAuditComment!,
              time: record.schoolAuditTime,
            ),
          ],
          if (record.generatedUserName != null) ...<Widget>[
            const SizedBox(height: 4),
            _InfoLine(label: '生成账号', value: record.generatedUserName!),
          ],
          if (record.isSubmitted || record.isCollegeApproved) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                if (canReject)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('驳回'),
                    ),
                  ),
                if (canReject && (canCollegeApprove || canSchoolApprove))
                  const SizedBox(width: 10),
                if (canCollegeApprove)
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: onCollegeApprove,
                      child: const Text('学院通过'),
                    ),
                  ),
                if (canSchoolApprove)
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: onSchoolApprove,
                      child: const Text('学校通过'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentBox extends StatelessWidget {
  const _CommentBox({
    required this.title,
    required this.content,
    required this.time,
  });

  final String title;
  final String content;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF516074),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(color: Color(0xFF516074), height: 1.6),
          ),
          if (time != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              DateTimeFormatter.dateTime(time),
              style: const TextStyle(color: Color(0xFF9AA4B2), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF8792A6)),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                color: Color(0xFF12223A),
                fontWeight: FontWeight.w600,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditSheet extends StatefulWidget {
  const _AuditSheet({
    required this.title,
    required this.record,
    required this.action,
    required this.onSubmit,
  });

  final String title;
  final TeacherRegisterAuditRecord record;
  final String action;
  final Future<bool> Function(String remark) onSubmit;

  @override
  State<_AuditSheet> createState() => _AuditSheetState();
}

class _AuditSheetState extends State<_AuditSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _remarkController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final success = await widget.onSubmit(_remarkController.text.trim());
      if (!mounted) {
        return;
      }
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('审核提交失败')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final title = widget.title;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.record.realName} · ${widget.record.teacherNo}',
                style: const TextStyle(color: Color(0xFF6D7B92)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarkController,
                maxLines: 4,
                maxLength: 255,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: '审核备注',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.action == 'reject'
                    ? '驳回后，申请会保留在记录中。'
                    : '处理完成后，申请状态会同步更新。',
                style: const TextStyle(color: Color(0xFF6D7B92), height: 1.6),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.title),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
