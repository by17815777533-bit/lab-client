import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/user_profile.dart';
import 'exit_application_controller.dart';
import 'exit_application_models.dart';

class ExitApplicationPage extends ConsumerStatefulWidget {
  const ExitApplicationPage({super.key});

  @override
  ConsumerState<ExitApplicationPage> createState() =>
      _ExitApplicationPageState();
}

class _ExitApplicationPageState extends ConsumerState<ExitApplicationPage> {
  late final ExitApplicationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExitApplicationController(
      ref.read(labExitApplicationRepositoryProvider),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openSubmitSheet(UserProfile profile) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _SubmitSheet(
          labLabel: profile.labId == null
              ? '当前未加入实验室'
              : '实验室 #${profile.labId}',
          onSubmit: (String reason) => _controller.submit(reason: reason),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('退出申请已提交')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;

    if (profile == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final hasLab = profile.labId != null;
        final pendingCount = _controller.records
            .where((item) => item.isPending)
            .length;
        final approvedCount = _controller.records
            .where((item) => item.isApproved)
            .length;
        final rejectedCount = _controller.records
            .where((item) => item.isRejected)
            .length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('退出实验室申请'),
            actions: <Widget>[
              if (hasLab)
                TextButton.icon(
                  onPressed: _controller.submitting
                      ? null
                      : () => _openSubmitSheet(profile),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('发起申请'),
                ),
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
                hasLab: hasLab,
                onSubmit: hasLab && !_controller.submitting
                    ? () => _openSubmitSheet(profile)
                    : null,
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
              _SummaryRow(
                total: _controller.total,
                pending: pendingCount,
                approved: approvedCount,
                rejected: rejectedCount,
              ),
              const SizedBox(height: 16),
              if (!hasLab)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.apartment_outlined,
                    title: '当前未加入实验室',
                    message: '加入实验室后，可以在这里提交退出申请并查看处理结果。',
                  ),
                )
              else
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              '申请记录',
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
                      if (_controller.loading && _controller.records.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_controller.records.isEmpty)
                        const EmptyState(
                          icon: Icons.inbox_outlined,
                          title: '暂无申请记录',
                          message: '提交第一条退出申请后，这里会自动展示处理进度。',
                        )
                      else
                        Column(
                          children: _controller.records
                              .map(
                                (record) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ApplicationRecordCard(record: record),
                                ),
                              )
                              .toList(),
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
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.hasLab,
    required this.onSubmit,
  });

  final UserProfile profile;
  final bool hasLab;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF2D78FF), Color(0xFF69C6FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '退出实验室申请',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasLab ? '当前实验室 #${profile.labId}' : '当前未加入实验室',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasLab
                ? '提交后将进入实验室管理员审核流程，审核结果会同步到你的申请记录。'
                : '加入实验室后即可提交退出申请并跟踪处理进度。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _MiniPill(label: profile.realName),
              _MiniPill(label: profile.roleLabel),
              _MiniPill(label: hasLab ? '可提交申请' : '无法提交'),
            ],
          ),
          if (onSubmit != null) ...<Widget>[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2F76FF),
              ),
              icon: const Icon(Icons.send_outlined),
              label: const Text('发起申请'),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
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
          .toList(),
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({required this.label, required this.value});

  final String label;
  final String value;
}

class _ApplicationRecordCard extends StatelessWidget {
  const _ApplicationRecordCard({required this.record});

  final LabExitApplicationRecord record;

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
                      record.labName?.isNotEmpty == true
                          ? record.labName!
                          : '实验室 #${record.labId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.realName ?? '-'} · ${record.studentId ?? '-'}',
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
          _InfoLine(label: '申请原因', value: record.reason),
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

class _SubmitSheet extends StatefulWidget {
  const _SubmitSheet({required this.labLabel, required this.onSubmit});

  final String labLabel;
  final Future<bool> Function(String reason) onSubmit;

  @override
  State<_SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends State<_SubmitSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
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
      final success = await widget.onSubmit(_reasonController.text);
      if (!mounted) {
        return;
      }
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('提交失败，请稍后重试')));
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
              const Text(
                '提交退出申请',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.labLabel,
                style: const TextStyle(color: Color(0xFF6D7B92)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: '退出原因',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入退出原因';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const Text(
                '提交后将进入实验室管理员审核流程，审核结果会同步到记录列表。',
                style: TextStyle(color: Color(0xFF6D7B92), height: 1.6),
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
                      : const Text('提交申请'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
