import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/user_profile.dart';
import 'lab_apply_audit_controller.dart';
import 'lab_apply_audit_models.dart';

class LabApplyAuditPage extends ConsumerStatefulWidget {
  const LabApplyAuditPage({super.key});

  @override
  ConsumerState<LabApplyAuditPage> createState() => _LabApplyAuditPageState();
}

class _LabApplyAuditPageState extends ConsumerState<LabApplyAuditPage> {
  late final LabApplyAuditController _controller;
  late final TextEditingController _keywordController;
  late final TextEditingController _labIdController;
  late final int? _initialLabId;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).profile;
    _initialLabId = profile?.labId;
    final requireLabSelection =
        profile?.schoolDirector == true || profile?.collegeManager == true;
    _controller = LabApplyAuditController(
      repository: ref.read(labApplyAuditRepositoryProvider),
      requireLabSelection: requireLabSelection,
      initialLabId: _initialLabId,
    );
    _keywordController = TextEditingController();
    _labIdController = TextEditingController(
      text: _initialLabId?.toString() ?? '',
    );

    if (!requireLabSelection || _initialLabId != null) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _keywordController.dispose();
    _labIdController.dispose();
    super.dispose();
  }

  bool _canUseModule(UserProfile? profile) {
    return profile?.schoolDirector == true ||
        profile?.collegeManager == true ||
        profile?.labManager == true;
  }

  Future<void> _runSearch(UserProfile profile) async {
    if (_controller.requireLabSelection) {
      final labId = int.tryParse(_labIdController.text.trim());
      _controller.setLabId(labId);
    }
    _controller.setKeyword(_keywordController.text);
    await _controller.load();
  }

  Future<void> _resetFilters() async {
    _keywordController.clear();
    _labIdController.text = _initialLabId?.toString() ?? '';
    _controller.resetFilters(initialLabId: _initialLabId);
    if (!_controller.requireLabSelection || _initialLabId != null) {
      await _controller.load();
    }
  }

  Future<void> _submitAudit({
    required LabApplyAuditRecord record,
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
      ).showSnackBar(const SnackBar(content: Text('申请处理完成')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).profile;
    final canUseModule = _canUseModule(profile);
    final needsLabSelection = _controller.requireLabSelection;

    if (profile == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final records = _controller.records;
        final submittedCount = records.where((item) => item.isSubmitted).length;
        final leaderApprovedCount = records
            .where((item) => item.isLeaderApproved)
            .length;
        final approvedCount = records.where((item) => item.isApproved).length;
        final rejectedCount = records.where((item) => item.isRejected).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('实验室申请审核'),
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
                scopeLabel: needsLabSelection
                    ? (_controller.labId == null
                          ? '待选择实验室'
                          : '实验室 #${_controller.labId}')
                    : '当前实验室',
              ),
              const SizedBox(height: 16),
              if (!canUseModule)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: '当前账号无审核权限',
                    message: '只有实验室管理员、学院管理员和学校管理员可以进入申请审核流程。',
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
                      if (needsLabSelection) ...<Widget>[
                        TextField(
                          controller: _labIdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '实验室编号',
                            hintText: '请输入需要查看的实验室编号',
                            prefixIcon: Icon(Icons.apartment_outlined),
                          ),
                          onSubmitted: (_) => _runSearch(profile),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _keywordController,
                        decoration: const InputDecoration(
                          labelText: '关键词',
                          hintText: '学生姓名 / 学号 / 实验室',
                          prefixIcon: Icon(Icons.manage_search_rounded),
                        ),
                        onChanged: _controller.setKeyword,
                        onSubmitted: (_) => _runSearch(profile),
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
                              _runSearch(profile);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('待审核'),
                            selected: _controller.statusFilter == 'submitted',
                            onSelected: (_) {
                              _controller.setStatusFilter('submitted');
                              _runSearch(profile);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('初审通过'),
                            selected:
                                _controller.statusFilter == 'leader_approved',
                            onSelected: (_) {
                              _controller.setStatusFilter('leader_approved');
                              _runSearch(profile);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('已通过'),
                            selected: _controller.statusFilter == 'approved',
                            onSelected: (_) {
                              _controller.setStatusFilter('approved');
                              _runSearch(profile);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('已驳回'),
                            selected: _controller.statusFilter == 'rejected',
                            onSelected: (_) {
                              _controller.setStatusFilter('rejected');
                              _runSearch(profile);
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
                                : () => _runSearch(profile),
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
                  submitted: submittedCount,
                  leaderApproved: leaderApprovedCount,
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
                              '申请列表',
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
                          message: '当前筛选条件下没有可处理的实验室申请。',
                        )
                      else
                        Column(
                          children: records
                              .map(
                                (record) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _RecordCard(
                                    record: record,
                                    onLeaderApprove: record.canLeaderApprove
                                        ? () => _submitAudit(
                                            record: record,
                                            action: 'leaderApprove',
                                            title: '初审通过',
                                          )
                                        : null,
                                    onApprove: record.canApprove
                                        ? () => _submitAudit(
                                            record: record,
                                            action: 'approve',
                                            title: '终审通过',
                                          )
                                        : null,
                                    onReject: record.canReject
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
          colors: <Color>[Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '实验室申请审核',
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
            canUseModule ? '处理学生入组申请，并同步更新审核进度。' : '当前账号暂无审核权限。',
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
    required this.leaderApproved,
    required this.approved,
    required this.rejected,
  });

  final int total;
  final int submitted;
  final int leaderApproved;
  final int approved;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryCardData>[
      _SummaryCardData(label: '总记录', value: total.toString()),
      _SummaryCardData(label: '待审核', value: submitted.toString()),
      _SummaryCardData(label: '初审通过', value: leaderApproved.toString()),
      _SummaryCardData(label: '已通过', value: approved.toString()),
      _SummaryCardData(label: '已驳回', value: rejected.toString()),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map(
            (card) => SizedBox(
              width: 150,
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
    this.onLeaderApprove,
    this.onApprove,
    this.onReject,
  });

  final LabApplyAuditRecord record;
  final VoidCallback? onLeaderApprove;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  Color get _statusColor {
    switch (record.status) {
      case 'leader_approved':
        return const Color(0xFF2563EB);
      case 'approved':
        return const Color(0xFF0F9D58);
      case 'rejected':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFF59E0B);
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
                      record.studentName?.isNotEmpty == true
                          ? record.studentName!
                          : '学生申请',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.studentId ?? '-'} · ${record.major ?? '-'} · ${record.grade ?? '-'}',
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
                  color: _statusColor.withValues(alpha: 0.12),
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
          _InfoLine(label: '实验室', value: record.labName ?? '-'),
          _InfoLine(label: '招新计划', value: record.planTitle ?? '-'),
          _InfoLine(label: '申请理由', value: record.applyReason ?? '-'),
          if ((record.researchInterest ?? '').trim().isNotEmpty)
            _InfoLine(label: '研究兴趣', value: record.researchInterest!),
          if ((record.skillSummary ?? '').trim().isNotEmpty)
            _InfoLine(label: '能力说明', value: record.skillSummary!),
          _InfoLine(
            label: '联系方式',
            value: '${record.phone ?? '-'} / ${record.email ?? '-'}',
          ),
          _InfoLine(
            label: '提交时间',
            value: DateTimeFormatter.dateTime(record.createTime),
          ),
          if (record.auditTime != null)
            _InfoLine(
              label: '审核时间',
              value: DateTimeFormatter.dateTime(record.auditTime),
            ),
          if ((record.auditComment ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                record.auditComment!,
                style: const TextStyle(color: Color(0xFF516074), height: 1.6),
              ),
            ),
          ],
          if (record.canApprove || record.canReject) ...<Widget>[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (onLeaderApprove != null)
                  OutlinedButton(
                    onPressed: onLeaderApprove,
                    child: const Text('初审通过'),
                  ),
                if (onApprove != null)
                  FilledButton.tonal(
                    onPressed: onApprove,
                    child: const Text('终审通过'),
                  ),
                if (onReject != null)
                  OutlinedButton(onPressed: onReject, child: const Text('驳回')),
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
    required this.title,
    required this.record,
    required this.action,
    required this.onSubmit,
  });

  final String title;
  final LabApplyAuditRecord record;
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
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.record.studentName ?? '-'} · ${widget.record.studentId ?? '-'}',
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
                  if (widget.action == 'reject' &&
                      (value ?? '').trim().isEmpty) {
                    return '请填写驳回原因';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                widget.action == 'approve'
                    ? '通过后，学生会加入当前实验室，并自动关闭其余待处理申请。'
                    : widget.action == 'leaderApprove'
                    ? '初审通过后，申请会进入下一阶段审核。'
                    : '驳回后，申请会保留在记录中，学生可查看处理结果。',
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
                      : const Text('确认提交'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
