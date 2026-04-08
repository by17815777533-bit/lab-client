import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/lab_summary.dart';
import '../../models/recruit_plan.dart';
import '../../models/user_profile.dart';
import 'recruit_plan_management_controller.dart';

class RecruitPlanManagementPage extends ConsumerStatefulWidget {
  const RecruitPlanManagementPage({super.key});

  @override
  ConsumerState<RecruitPlanManagementPage> createState() =>
      _RecruitPlanManagementPageState();
}

class _RecruitPlanManagementPageState
    extends ConsumerState<RecruitPlanManagementPage> {
  late final RecruitPlanManagementController _controller;
  late final TextEditingController _keywordController;
  late final UserProfile _profile;

  static const List<_PlanStatusFilter> _filters = <_PlanStatusFilter>[
    _PlanStatusFilter(label: '全部', value: null),
    _PlanStatusFilter(label: '草稿', value: 'draft'),
    _PlanStatusFilter(label: '开放中', value: 'open'),
    _PlanStatusFilter(label: '已关闭', value: 'closed'),
  ];

  @override
  void initState() {
    super.initState();
    _profile = ref.read(authControllerProvider).profile!;
    _controller = RecruitPlanManagementController(
      repository: ref.read(planRepositoryProvider),
      labRepository: ref.read(labRepositoryProvider),
      profile: _profile,
    )..load();
    _keywordController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    _controller.setKeyword(_keywordController.text);
    await _controller.search();
  }

  Future<void> _resetFilters() async {
    _keywordController.clear();
    _controller
      ..setKeyword('')
      ..setStatus(null)
      ..setSelectedLabId(_profile.labId);
    await _controller.search();
  }

  Future<void> _openPlanSheet({RecruitPlan? plan}) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _PlanEditorSheet(
          profile: _profile,
          labs: _controller.labOptions,
          fixedLabId: _profile.labId,
          initialPlan: plan,
          onSubmit:
              ({
                required int labId,
                required String title,
                required String startTime,
                required String endTime,
                required int quota,
                required String status,
                String? requirement,
              }) async {
                final saved = await _controller.savePlan(
                  id: plan?.id,
                  labId: labId,
                  title: title,
                  startTime: startTime,
                  endTime: endTime,
                  quota: quota,
                  requirement: requirement,
                  status: status,
                );
                if (saved) {
                  return null;
                }
                return _controller.errorMessage ?? '保存失败，请稍后重试';
              },
        );
      },
    );

    if (!mounted || success != true) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('招新计划已保存')));
  }

  Future<void> _deletePlan(RecruitPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除招新计划'),
          content: Text('确认删除“${plan.title}”吗？删除后不可恢复。'),
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
              child: const Text('确认删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await _controller.deletePlan(plan.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '招新计划已删除' : _controller.errorMessage ?? '删除失败'),
      ),
    );
  }

  String _scopeLabel() {
    if (_profile.schoolDirector) {
      return '全校招新安排';
    }
    if (_profile.collegeManager) {
      return _profile.college ?? '当前学院';
    }
    if (_profile.labId != null) {
      return '实验室 #${_profile.labId}';
    }
    return '当前范围';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final records = _controller.records;
        final openCount = records.where((item) => item.isOpen).length;
        final draftCount = records.where((item) => item.isDraft).length;
        final closedCount = records.where((item) => item.isClosed).length;
        final needsLabSelection =
            _controller.requireLabSelection &&
            _controller.selectedLabId == null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('招新计划'),
            actions: <Widget>[
              IconButton(
                tooltip: '刷新',
                onPressed: _controller.loading ? null : _controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: '新建计划',
                onPressed: _controller.saving ? null : _openPlanSheet,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          body: ResponsiveListView(
            onRefresh: _controller.refresh,
            children: <Widget>[
              _HeroCard(
                profile: _profile,
                scopeLabel: _scopeLabel(),
                total: _controller.total,
                openCount: openCount,
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
                    if (_controller.canSelectLab) ...<Widget>[
                      DropdownButtonFormField<int?>(
                        key: ValueKey<int?>(_controller.selectedLabId),
                        initialValue: _controller.selectedLabId,
                        decoration: const InputDecoration(
                          labelText: '实验室范围',
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                        items: <DropdownMenuItem<int?>>[
                          if (_profile.schoolDirector)
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('全部实验室'),
                            ),
                          ..._controller.labOptions.map(
                            (LabSummary lab) => DropdownMenuItem<int?>(
                              value: lab.id,
                              child: Text(lab.labName),
                            ),
                          ),
                        ],
                        onChanged: _controller.setSelectedLabId,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _keywordController,
                      decoration: const InputDecoration(
                        labelText: '关键词',
                        hintText: '标题 / 实验室名称 / 学院名称',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filters
                          .map(
                            (item) => ChoiceChip(
                              label: Text(item.label),
                              selected: _controller.status == item.value,
                              onSelected: (_) {
                                _controller.setStatus(item.value);
                                _search();
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: _controller.loading ? null : _search,
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('查询'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _controller.loading ? null : _resetFilters,
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('重置'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _controller.saving ? null : _openPlanSheet,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('新建计划'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (needsLabSelection) ...<Widget>[
                const SizedBox(height: 16),
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.apartment_outlined,
                    title: '请先选择实验室',
                    message: '选定实验室后，这里会展示对应的招新计划。',
                  ),
                ),
              ] else ...<Widget>[
                const SizedBox(height: 16),
                _SummaryRow(
                  total: _controller.total,
                  openCount: openCount,
                  draftCount: draftCount,
                  closedCount: closedCount,
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
                              '计划列表',
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
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (records.isEmpty)
                        const EmptyState(
                          icon: Icons.event_note_outlined,
                          title: '暂无招新计划',
                          message: '当前筛选条件下没有可展示的招新计划。',
                        )
                      else
                        Column(
                          children: records
                              .map(
                                (RecruitPlan plan) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _PlanCard(
                                    plan: plan,
                                    deleting: _controller.deleting,
                                    onEdit: () => _openPlanSheet(plan: plan),
                                    onDelete: () => _deletePlan(plan),
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
    required this.scopeLabel,
    required this.total,
    required this.openCount,
  });

  final UserProfile profile;
  final String scopeLabel;
  final int total;
  final int openCount;

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
            '招新安排',
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
            '统一维护计划标题、开放周期和名额，保证学生端看到的是最新安排。',
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
              _HeroPill(label: scopeLabel),
              _HeroPill(label: '共 $total 条'),
              _HeroPill(label: '开放中 $openCount 条'),
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
    required this.openCount,
    required this.draftCount,
    required this.closedCount,
  });

  final int total;
  final int openCount;
  final int draftCount;
  final int closedCount;

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryData>[
      _SummaryData(label: '总计划', value: '$total'),
      _SummaryData(label: '开放中', value: '$openCount'),
      _SummaryData(label: '草稿', value: '$draftCount'),
      _SummaryData(label: '已关闭', value: '$closedCount'),
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

class _SummaryData {
  const _SummaryData({required this.label, required this.value});

  final String label;
  final String value;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.deleting,
    this.onEdit,
    this.onDelete,
  });

  final RecruitPlan plan;
  final bool deleting;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final badgeColor = switch (plan.status) {
      'open' => const Color(0xFF059669),
      'closed' => const Color(0xFF6B7280),
      _ => const Color(0xFF2563EB),
    };

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
                      plan.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${plan.labName ?? '未命名实验室'} · ${plan.collegeName ?? '未分配学院'}',
                      style: const TextStyle(
                        color: Color(0xFF6D7B92),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.statusLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: <Widget>[
              _InfoPill(
                icon: Icons.people_outline_rounded,
                label: '名额 ${plan.quota}',
              ),
              _InfoPill(
                icon: Icons.schedule_rounded,
                label:
                    '${DateTimeFormatter.dateTime(plan.startTime)} - ${DateTimeFormatter.dateTime(plan.endTime)}',
              ),
              if ((plan.location ?? '').isNotEmpty)
                _InfoPill(icon: Icons.place_outlined, label: plan.location!),
            ],
          ),
          if ((plan.requirement ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              plan.requirement!,
              style: const TextStyle(color: Color(0xFF4A5567), height: 1.6),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑'),
              ),
              FilledButton.tonalIcon(
                onPressed: deleting ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除'),
              ),
            ],
          ),
        ],
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

class _PlanEditorSheet extends StatefulWidget {
  const _PlanEditorSheet({
    required this.profile,
    required this.labs,
    required this.fixedLabId,
    required this.initialPlan,
    required this.onSubmit,
  });

  final UserProfile profile;
  final List<LabSummary> labs;
  final int? fixedLabId;
  final RecruitPlan? initialPlan;
  final Future<String?> Function({
    required int labId,
    required String title,
    required String startTime,
    required String endTime,
    required int quota,
    required String status,
    String? requirement,
  })
  onSubmit;

  @override
  State<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends State<_PlanEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _quotaController;
  late final TextEditingController _requirementController;
  late DateTime _startTime;
  late DateTime _endTime;
  late String _status;
  late int? _labId;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialPlan?.title ?? '',
    );
    _quotaController = TextEditingController(
      text: '${widget.initialPlan?.quota ?? 10}',
    );
    _requirementController = TextEditingController(
      text: widget.initialPlan?.requirement ?? '',
    );
    _startTime = widget.initialPlan?.startTime ?? DateTime.now();
    _endTime =
        widget.initialPlan?.endTime ??
        DateTime.now().add(const Duration(days: 30));
    _status = widget.initialPlan?.status ?? 'draft';
    _labId = widget.initialPlan?.labId ?? widget.fixedLabId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quotaController.dispose();
    _requirementController.dispose();
    super.dispose();
  }

  bool get _canSelectLab =>
      widget.profile.schoolDirector || widget.fixedLabId == null;

  Future<void> _pickDateTime({required bool start}) async {
    final current = start ? _startTime : _endTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null) {
      return;
    }
    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      if (start) {
        _startTime = result;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(days: 7));
        }
      } else {
        _endTime = result;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_labId == null) {
      setState(() {
        _errorText = '请选择实验室';
      });
      return;
    }
    if (_endTime.isBefore(_startTime)) {
      setState(() {
        _errorText = '结束时间不能早于开始时间';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final error = await widget.onSubmit(
      labId: _labId!,
      title: _titleController.text.trim(),
      startTime: _apiDateTime(_startTime),
      endTime: _apiDateTime(_endTime),
      quota: int.tryParse(_quotaController.text.trim()) ?? 0,
      status: _status,
      requirement: _requirementController.text.trim().isEmpty
          ? null
          : _requirementController.text.trim(),
    );

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
    final fixedLab = widget.labs.cast<LabSummary?>().firstWhere(
      (LabSummary? item) => item?.id == widget.fixedLabId,
      orElse: () => null,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.initialPlan == null ? '新建招新计划' : '编辑招新计划',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '维护计划标题、开放周期与申请要求，学生端会自动读取最新开放计划。',
                style: TextStyle(color: Color(0xFF6D7B92), height: 1.5),
              ),
              const SizedBox(height: 18),
              if (_canSelectLab) ...<Widget>[
                DropdownButtonFormField<int>(
                  key: ValueKey<int?>(_labId),
                  initialValue: _labId,
                  decoration: const InputDecoration(labelText: '所属实验室'),
                  items: widget.labs
                      .map(
                        (LabSummary lab) => DropdownMenuItem<int>(
                          value: lab.id,
                          child: Text(lab.labName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (int? value) => setState(() => _labId = value),
                  validator: (int? value) {
                    if (value == null) {
                      return '请选择实验室';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ] else ...<Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE5F3)),
                  ),
                  child: Text(
                    fixedLab?.labName ?? '当前实验室',
                    style: const TextStyle(
                      color: Color(0xFF12223A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '计划标题'),
                validator: (String? value) {
                  if ((value ?? '').trim().isEmpty) {
                    return '请输入计划标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quotaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '招募名额'),
                validator: (String? value) {
                  final count = int.tryParse((value ?? '').trim());
                  if (count == null || count <= 0) {
                    return '请输入大于 0 的名额';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey<String>(_status),
                initialValue: _status,
                decoration: const InputDecoration(labelText: '计划状态'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'draft', child: Text('草稿')),
                  DropdownMenuItem<String>(value: 'open', child: Text('开放中')),
                  DropdownMenuItem<String>(value: 'closed', child: Text('已关闭')),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(start: true),
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: Text(_displayDateTime(_startTime)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(start: false),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(_displayDateTime(_endTime)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _requirementController,
                minLines: 4,
                maxLines: 5,
                maxLength: 220,
                decoration: const InputDecoration(
                  labelText: '申请要求',
                  alignLabelWithHint: true,
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
                      : const Text('保存计划'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final DateFormat _apiFormatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
  static final DateFormat _displayFormatter = DateFormat('yyyy-MM-dd HH:mm');

  static String _apiDateTime(DateTime value) => _apiFormatter.format(value);

  static String _displayDateTime(DateTime value) =>
      _displayFormatter.format(value);
}

class _PlanStatusFilter {
  const _PlanStatusFilter({required this.label, required this.value});

  final String label;
  final String? value;
}
