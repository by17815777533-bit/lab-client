import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/utils/file_url_resolver.dart';
import '../../core/utils/url_launcher_helper.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/delivery_record.dart';
import '../../models/user_profile.dart';
import 'delivery_management_controller.dart';

class DeliveryManagementPage extends ConsumerStatefulWidget {
  const DeliveryManagementPage({
    super.key,
    this.initialRealName,
    this.initialStudentId,
    this.initialAuditStatus,
  });

  final String? initialRealName;
  final String? initialStudentId;
  final int? initialAuditStatus;

  @override
  ConsumerState<DeliveryManagementPage> createState() =>
      _DeliveryManagementPageState();
}

class _DeliveryManagementPageState
    extends ConsumerState<DeliveryManagementPage> {
  late final DeliveryManagementController _controller;
  late final UserProfile _profile;
  late final TextEditingController _realNameController;
  late final TextEditingController _studentIdController;

  @override
  void initState() {
    super.initState();
    _profile = ref.read(authControllerProvider).profile!;
    _controller = DeliveryManagementController(
      repository: ref.read(deliveryRepositoryProvider),
      profile: _profile,
      initialRealName: widget.initialRealName,
      initialStudentId: widget.initialStudentId,
      initialAuditStatus: widget.initialAuditStatus,
    )..load();
    _realNameController = TextEditingController(
      text: widget.initialRealName ?? '',
    );
    _studentIdController = TextEditingController(
      text: widget.initialStudentId ?? '',
    );
  }

  @override
  void dispose() {
    _realNameController.dispose();
    _studentIdController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    _controller.updateFilters(
      realName: _realNameController.text,
      studentId: _studentIdController.text,
      auditStatus: _controller.auditStatus,
    );
    await _controller.search();
  }

  Future<void> _resetSearch() async {
    _realNameController.clear();
    _studentIdController.clear();
    _controller.clearFilters();
    await _controller.load();
  }

  Future<void> _showDeliveryDetail(
    DeliveryRecord record,
    String baseUrl,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _DeliveryDetailSheet(
          record: record,
          baseUrl: baseUrl,
          canAudit: _controller.canAudit,
          onApprove: record.canAudit
              ? () {
                  Navigator.of(context).pop();
                  _openReviewSheet(record, approve: true);
                }
              : null,
          onReject: record.canAudit
              ? () {
                  Navigator.of(context).pop();
                  _openReviewSheet(record, approve: false);
                }
              : null,
        );
      },
    );
  }

  Future<void> _openReviewSheet(
    DeliveryRecord record, {
    required bool approve,
  }) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _ReviewSheet(
          title: approve ? '通过并发放 offer' : '拒绝投递',
          placeholder: approve ? '请输入通过说明' : '请输入拒绝原因',
          loading: _controller.submitting,
          onSubmit: (String remark) => _controller.reviewDelivery(
            record: record,
            approve: approve,
            remark: remark,
          ),
        );
      },
    );

    if (!mounted || success == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '投递处理完成' : _controller.errorMessage ?? '处理失败'),
      ),
    );
  }

  Future<void> _applyStatus(int? value) async {
    _controller.updateFilters(
      realName: _realNameController.text,
      studentId: _studentIdController.text,
      auditStatus: value,
    );
    await _controller.search();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.watch(appSettingsControllerProvider).baseUrl;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final deliveries = _controller.deliveries;
        final pendingCount = deliveries
            .where((item) => item.displayStatus == 0)
            .length;
        final offerPendingCount = deliveries
            .where((item) => item.displayStatus == 3)
            .length;
        final joinedCount = deliveries
            .where((item) => item.displayStatus == 1)
            .length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('投递管理'),
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
              _DeliveryHeroBanner(
                profile: _profile,
                total: _controller.total,
                pendingCount: pendingCount,
                offerPendingCount: offerPendingCount,
                joinedCount: joinedCount,
                canAudit: _controller.canAudit,
              ),
              const SizedBox(height: 16),
              if (!_controller.canAudit)
                const PanelCard(
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.visibility_outlined, color: Color(0xFF1D4ED8)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '当前页面可查看投递进展，审核与发放由对应实验室负责人处理。',
                          style: TextStyle(
                            color: Color(0xFF36537A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_controller.canAudit) const SizedBox(height: 16),
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
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          label: const Text('全部'),
                          selected: _controller.auditStatus == null,
                          onSelected: (_) => _applyStatus(null),
                        ),
                        ChoiceChip(
                          label: const Text('待审核'),
                          selected: _controller.auditStatus == 0,
                          onSelected: (_) => _applyStatus(0),
                        ),
                        ChoiceChip(
                          label: const Text('审核通过'),
                          selected: _controller.auditStatus == 1,
                          onSelected: (_) => _applyStatus(1),
                        ),
                        ChoiceChip(
                          label: const Text('已拒绝'),
                          selected: _controller.auditStatus == 2,
                          onSelected: (_) => _applyStatus(2),
                        ),
                        ChoiceChip(
                          label: const Text('已撤销'),
                          selected: _controller.auditStatus == 3,
                          onSelected: (_) => _applyStatus(3),
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
                    title: '投递总量',
                    value: '${_controller.total}',
                    subtitle: '当前筛选结果',
                    accent: const Color(0xFF1D4ED8),
                    icon: Icons.assignment_turned_in_outlined,
                  ),
                  _SummaryTile(
                    title: '待审核',
                    value: '$pendingCount',
                    subtitle: '当前页待处理',
                    accent: const Color(0xFFF59E0B),
                    icon: Icons.pending_actions_outlined,
                  ),
                  _SummaryTile(
                    title: '待确认 offer',
                    value: '$offerPendingCount',
                    subtitle: '等待学生选择',
                    accent: const Color(0xFF7C3AED),
                    icon: Icons.mark_email_unread_outlined,
                  ),
                  _SummaryTile(
                    title: '已加入',
                    value: '$joinedCount',
                    subtitle: '当前页已完成',
                    accent: const Color(0xFF0F766E),
                    icon: Icons.verified_user_outlined,
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
                            '投递列表',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12223A),
                            ),
                          ),
                        ),
                        Text(
                          '${_controller.total} 条记录',
                          style: const TextStyle(
                            color: Color(0xFF6D7B92),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_controller.loading && deliveries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (deliveries.isEmpty)
                      const EmptyState(
                        icon: Icons.assignment_late_outlined,
                        title: '暂无投递记录',
                        message: '当前筛选条件下没有匹配到投递记录。',
                      )
                    else
                      Column(
                        children: deliveries
                            .map(
                              (DeliveryRecord record) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _DeliveryCard(
                                  record: record,
                                  canAudit: _controller.canAudit,
                                  submitting: _controller.submitting,
                                  onViewDetail: () =>
                                      _showDeliveryDetail(record, baseUrl),
                                  onApprove: record.canAudit
                                      ? () => _openReviewSheet(
                                          record,
                                          approve: true,
                                        )
                                      : null,
                                  onReject: record.canAudit
                                      ? () => _openReviewSheet(
                                          record,
                                          approve: false,
                                        )
                                      : null,
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

class _DeliveryHeroBanner extends StatelessWidget {
  const _DeliveryHeroBanner({
    required this.profile,
    required this.total,
    required this.pendingCount,
    required this.offerPendingCount,
    required this.joinedCount,
    required this.canAudit,
  });

  final UserProfile profile;
  final int total;
  final int pendingCount;
  final int offerPendingCount;
  final int joinedCount;
  final bool canAudit;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            '投递进展总览',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canAudit ? '当前账号可直接处理本实验室投递。' : '当前账号可查看投递进展与结果流转。',
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
              _HeroPill(icon: Icons.assignment_rounded, label: '总量 $total'),
              _HeroPill(
                icon: Icons.pending_actions_rounded,
                label: '待审核 $pendingCount',
              ),
              _HeroPill(
                icon: Icons.mark_email_unread_outlined,
                label: '待确认 $offerPendingCount',
              ),
              _HeroPill(
                icon: Icons.verified_user_outlined,
                label: '已加入 $joinedCount',
              ),
              _HeroPill(
                icon: Icons.admin_panel_settings_outlined,
                label: profile.roleLabel,
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

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.record,
    required this.canAudit,
    required this.submitting,
    required this.onViewDetail,
    this.onApprove,
    this.onReject,
  });

  final DeliveryRecord record;
  final bool canAudit;
  final bool submitting;
  final VoidCallback onViewDetail;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      record.displayLabName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.displayStudentName} · ${record.displayStudentId}',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _DeliveryStatusChip(status: record.displayStatus),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            record.displayReason,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF344054), height: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: <Widget>[
              _InfoText(
                icon: Icons.schedule_outlined,
                text: DateTimeFormatter.dateTime(record.createTime),
              ),
              _InfoText(
                icon: Icons.repeat_rounded,
                text: '投递 ${record.deliveryAttemptCount}/2',
              ),
              _InfoText(
                icon: Icons.undo_rounded,
                text: '撤销 ${record.withdrawCount}/1',
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
                label: const Text('查看详情'),
              ),
              if (canAudit)
                FilledButton.tonalIcon(
                  onPressed: submitting ? null : onApprove,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('通过并发放'),
                ),
              if (canAudit)
                TextButton.icon(
                  onPressed: submitting ? null : onReject,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB42318),
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('拒绝'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetailSheet extends StatelessWidget {
  const _DeliveryDetailSheet({
    required this.record,
    required this.baseUrl,
    required this.canAudit,
    this.onApprove,
    this.onReject,
  });

  final DeliveryRecord record;
  final String baseUrl;
  final bool canAudit;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final attachments = _buildAttachmentItems(record, baseUrl);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    record.displayLabName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12223A),
                    ),
                  ),
                ),
                _DeliveryStatusChip(status: record.displayStatus),
              ],
            ),
            const SizedBox(height: 18),
            _DetailLine(label: '学生', value: record.displayStudentName),
            _DetailLine(label: '学号', value: record.displayStudentId),
            _DetailLine(label: '学院', value: record.college ?? '未填写'),
            _DetailLine(label: '专业', value: record.major ?? '未填写'),
            _DetailLine(label: '邮箱', value: record.email ?? '未填写'),
            _DetailLine(label: '电话', value: record.phone ?? '未填写'),
            _DetailLine(
              label: '投递时间',
              value: DateTimeFormatter.dateTime(record.createTime),
            ),
            _DetailLine(
              label: '状态时间',
              value: DateTimeFormatter.dateTime(
                record.updateTime ?? record.admitTime,
              ),
            ),
            _DetailLine(
              label: '投递次数',
              value: '${record.deliveryAttemptCount} / 2',
            ),
            _DetailLine(label: '撤销次数', value: '${record.withdrawCount} / 1'),
            _DetailLine(label: '投递说明', value: record.displayReason),
            if ((record.skillTags ?? '').trim().isNotEmpty)
              _DetailLine(label: '技能标签', value: record.skillTags!.trim()),
            if ((record.comment ?? '').trim().isNotEmpty)
              _DetailLine(label: '处理备注', value: record.comment!.trim()),
            if (attachments.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              const Text(
                '材料附件',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: attachments
                    .map(
                      (_AttachmentItem item) => FilledButton.tonalIcon(
                        onPressed: item.url.isEmpty
                            ? null
                            : () => openExternalLink(context, item.url),
                        icon: Icon(
                          item.url.isEmpty
                              ? Icons.lock_outline_rounded
                              : Icons.attach_file_rounded,
                        ),
                        label: Text(item.label),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (canAudit && record.canAudit)
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('通过并发放'),
                  ),
                if (canAudit && record.canAudit)
                  TextButton.icon(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB42318),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('拒绝'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_AttachmentItem> _buildAttachmentItems(
    DeliveryRecord record,
    String baseUrl,
  ) {
    final items = <_AttachmentItem>[];
    for (final String rawUrl in record.attachmentPaths) {
      items.add(
        _AttachmentItem(
          label: _displayName(rawUrl),
          url: _resolveUrl(baseUrl, rawUrl),
        ),
      );
    }
    if (record.showsProfileResume) {
      items.add(
        _AttachmentItem(
          label: '个人简历',
          url: record.canPreviewResume
              ? _resolveUrl(baseUrl, record.resumeUrl!)
              : '',
        ),
      );
    }
    return items;
  }

  String _resolveUrl(String baseUrl, String rawUrl) {
    if (rawUrl.trim().isEmpty || rawUrl.trim().startsWith('protected:')) {
      return '';
    }
    return FileUrlResolver.resolve(baseUrl: baseUrl, rawUrl: rawUrl);
  }

  String _displayName(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return '附件';
    }
    final normalized = trimmed.startsWith('protected:')
        ? trimmed.substring('protected:'.length)
        : trimmed;
    final segment = normalized.split('/').last;
    if (segment.isEmpty) {
      return '附件';
    }
    return Uri.decodeComponent(segment);
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({
    required this.title,
    required this.placeholder,
    required this.loading,
    required this.onSubmit,
  });

  final String title;
  final String placeholder;
  final bool loading;
  final Future<bool> Function(String remark) onSubmit;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final TextEditingController _remarkController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final remark = _remarkController.text.trim();
    if (remark.length < 2) {
      setState(() {
        _errorText = '请至少填写 2 个字';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    final success = await widget.onSubmit(remark);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
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
            const SizedBox(height: 14),
            TextField(
              controller: _remarkController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: '处理说明',
                hintText: widget.placeholder,
                errorText: _errorText,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.loading ? null : _submit,
                child: Text(widget.loading ? '提交中...' : '确认提交'),
              ),
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

class _DeliveryStatusChip extends StatelessWidget {
  const _DeliveryStatusChip({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    late final String label;

    switch (status) {
      case 1:
        background = const Color(0xFFDFF7EA);
        foreground = const Color(0xFF067647);
        label = '已加入';
        break;
      case 2:
        background = const Color(0xFFFDE7EA);
        foreground = const Color(0xFFB42318);
        label = '已拒绝';
        break;
      case 3:
        background = const Color(0xFFF2E8FF);
        foreground = const Color(0xFF6F2DBD);
        label = '待确认';
        break;
      case 4:
        background = const Color(0xFFE8F1FF);
        foreground = const Color(0xFF1D4ED8);
        label = '审核通过';
        break;
      case 5:
        background = const Color(0xFFF4F4F5);
        foreground = const Color(0xFF667085);
        label = 'offer 关闭';
        break;
      case 6:
        background = const Color(0xFFFFF1D6);
        foreground = const Color(0xFFB54708);
        label = '已撤销';
        break;
      default:
        background = const Color(0xFFFFF4D6);
        foreground = const Color(0xFFB54708);
        label = '待审核';
        break;
    }

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
          fontSize: 12,
          fontWeight: FontWeight.w800,
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

class _AttachmentItem {
  const _AttachmentItem({required this.label, required this.url});

  final String label;
  final String url;
}
