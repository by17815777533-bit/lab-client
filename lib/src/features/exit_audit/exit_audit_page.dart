import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/user_profile.dart';
import 'exit_audit_controller.dart';
import 'exit_audit_models.dart';

class ExitAuditPage extends ConsumerStatefulWidget {
  const ExitAuditPage({super.key, this.initialLabId});

  final int? initialLabId;

  @override
  ConsumerState<ExitAuditPage> createState() => _ExitAuditPageState();
}

class _ExitAuditPageState extends ConsumerState<ExitAuditPage> {
  late final ExitAuditController _controller;
  late final TextEditingController _labIdController;
  late final TextEditingController _studentNameController;
  bool _labTouched = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).profile;
    final labId = widget.initialLabId ?? profile?.labId;
    _controller = ExitAuditController(
      repository: ref.read(exitAuditRepositoryProvider),
      labId: labId,
    );
    _labIdController = TextEditingController(text: labId?.toString() ?? '');
    _studentNameController = TextEditingController();
    if (labId != null) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _labIdController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  bool _canUseModule(UserProfile? profile) {
    return profile?.schoolDirector == true || profile?.labManager == true;
  }

  Future<void> _loadByLabId() async {
    final value = int.tryParse(_labIdController.text.trim());
    if (value == null || value <= 0) {
      setState(() {
        _labTouched = true;
      });
      return;
    }
    _controller.setLabId(value);
    await _controller.load();
  }

  Future<void> _resetFilters() async {
    _studentNameController.clear();
    _controller.resetFilters();
    if (_controller.labId != null) {
      await _controller.load();
    }
  }

  Future<void> _submitAudit({
    required ExitAuditApplicationRecord record,
    required bool approve,
  }) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _AuditSheet(
          record: record,
          approve: approve,
          onSubmit: (String remark) => _controller.audit(
            id: record.id,
            status: approve ? 1 : 2,
            auditRemark: remark,
          ),
        );
      },
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(approve ? '已通过退出申请' : '已驳回退出申请')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;
    final canUseModule = _canUseModule(profile);
    final isSuperAdmin = profile?.schoolDirector == true;

    if (profile == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final records = _controller.records;
        final pendingCount = records.where((item) => item.isPending).length;
        final approvedCount = records.where((item) => item.isApproved).length;
        final rejectedCount = records.where((item) => item.isRejected).length;
        final currentLabLabel = _controller.labId == null
            ? '未选择实验室'
            : '实验室 #${_controller.labId}';

        return Scaffold(
          appBar: AppBar(
            title: const Text('退出实验室审核'),
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
                currentLabLabel: currentLabLabel,
                canUseModule: canUseModule,
              ),
              const SizedBox(height: 16),
              if (!canUseModule)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: '当前账号无审核权限',
                    message: '只有实验室管理员和学校管理员可以进入退出审核流程。',
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
                      if (isSuperAdmin) ...<Widget>[
                        TextField(
                          controller: _labIdController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '实验室编号',
                            helperText: _labTouched
                                ? '请输入有效的实验室编号'
                                : '学校管理员需要先选择实验室编号',
                            prefixIcon: const Icon(Icons.apartment_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _studentNameController,
                        decoration: const InputDecoration(
                          labelText: '学生姓名',
                          prefixIcon: Icon(Icons.person_search_outlined),
                        ),
                        onChanged: _controller.setStudentName,
                        onSubmitted: (String value) {
                          _controller.setStudentName(value);
                          if (_controller.labId != null) {
                            _controller.load();
                          }
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
                              if (_controller.labId != null) {
                                _controller.load();
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('待审核'),
                            selected: _controller.statusFilter == 0,
                            onSelected: (_) {
                              _controller.setStatusFilter(0);
                              if (_controller.labId != null) {
                                _controller.load();
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('已通过'),
                            selected: _controller.statusFilter == 1,
                            onSelected: (_) {
                              _controller.setStatusFilter(1);
                              if (_controller.labId != null) {
                                _controller.load();
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('已驳回'),
                            selected: _controller.statusFilter == 2,
                            onSelected: (_) {
                              _controller.setStatusFilter(2);
                              if (_controller.labId != null) {
                                _controller.load();
                              }
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
                                : _loadByLabId,
                            child: const Text('查询'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: _controller.loading
                                ? null
                                : _resetFilters,
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
                  pending: pendingCount,
                  approved: approvedCount,
                  rejected: rejectedCount,
                ),
                const SizedBox(height: 16),
                if (_controller.errorMessage != null) ...<Widget>[
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
                          title: '暂无待审核内容',
                          message: '当前筛选条件下没有可处理的退出申请。',
                        )
                      else
                        Column(
                          children: records
                              .map(
                                (record) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _RecordCard(
                                    record: record,
                                    onApprove: record.isPending
                                        ? () => _submitAudit(
                                            record: record,
                                            approve: true,
                                          )
                                        : null,
                                    onReject: record.isPending
                                        ? () => _submitAudit(
                                            record: record,
                                            approve: false,
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
    required this.currentLabLabel,
    required this.canUseModule,
  });

  final UserProfile profile;
  final String currentLabLabel;
  final bool canUseModule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '实验室退出审核',
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
            canUseModule ? '处理学生退出申请，审核结果会同步更新到成员信息。' : '当前账号暂无审核权限。',
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
              _MiniPill(label: currentLabLabel),
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
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  final int total;
  final int pending;
  final int approved;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryCardData>[
      _SummaryCardData(label: '总记录', value: total.toString()),
      _SummaryCardData(label: '当前页待审', value: pending.toString()),
      _SummaryCardData(label: '当前页通过', value: approved.toString()),
      _SummaryCardData(label: '当前页驳回', value: rejected.toString()),
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
    required this.onApprove,
    required this.onReject,
  });

  final ExitAuditApplicationRecord record;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  Color get _statusColor {
    switch (record.status) {
      case 1:
        return const Color(0xFF0F9D58);
      case 2:
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color get _statusBackground {
    switch (record.status) {
      case 1:
        return const Color(0x140F9D58);
      case 2:
        return const Color(0x14E53935);
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
                      record.realName?.isNotEmpty == true
                          ? record.realName!
                          : '学生 #${record.userId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.studentId ?? '-'} · ${record.major ?? '-'}',
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
          _InfoLine(
            label: '实验室',
            value: record.labName ?? '实验室 #${record.labId}',
          ),
          _InfoLine(label: '退出原因', value: record.reason),
          _InfoLine(
            label: '提交时间',
            value: DateTimeFormatter.dateTime(record.createTime),
          ),
          if (record.auditTime != null)
            _InfoLine(
              label: '审核时间',
              value: DateTimeFormatter.dateTime(record.auditTime),
            ),
          if ((record.auditRemark ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                record.auditRemark!,
                style: const TextStyle(color: Color(0xFF516074), height: 1.6),
              ),
            ),
          ],
          if (record.isPending) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('驳回'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onApprove,
                    child: const Text('同意退出'),
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
    required this.record,
    required this.approve,
    required this.onSubmit,
  });

  final ExitAuditApplicationRecord record;
  final bool approve;
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
    final title = widget.approve ? '同意退出' : '驳回申请';

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
                widget.record.realName?.isNotEmpty == true
                    ? '${widget.record.realName} · ${widget.record.studentId ?? '-'}'
                    : '学生 #${widget.record.userId}',
                style: const TextStyle(color: Color(0xFF6D7B92)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarkController,
                maxLines: 4,
                maxLength: 200,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: '审核备注',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                validator: (String? value) {
                  if (!widget.approve && (value ?? '').trim().isEmpty) {
                    return '请填写驳回原因';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                widget.approve ? '同意后，学生将从当前实验室成员中移除。' : '驳回后，申请状态会保留在记录中。',
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
                      : Text(widget.approve ? '确认同意' : '确认驳回'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
