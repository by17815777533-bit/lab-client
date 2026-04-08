import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/user_profile.dart';
import 'lab_create_apply_controller.dart';
import 'lab_create_apply_models.dart';
import '../../repositories/lab_create_apply_repository.dart';

class LabCreateApplyPage extends ConsumerStatefulWidget {
  const LabCreateApplyPage({super.key});

  @override
  ConsumerState<LabCreateApplyPage> createState() => _LabCreateApplyPageState();
}

class _LabCreateApplyPageState extends ConsumerState<LabCreateApplyPage> {
  late final LabCreateApplyController _controller;
  final TextEditingController _keywordController = TextEditingController();

  static const List<_StatusFilter> _filters = <_StatusFilter>[
    _StatusFilter(label: '全部', value: null),
    _StatusFilter(label: '待学院审核', value: 'submitted'),
    _StatusFilter(label: '待学校审核', value: 'college_approved'),
    _StatusFilter(label: '已通过', value: 'approved'),
    _StatusFilter(label: '已驳回', value: 'rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = LabCreateApplyController(
      ref.read(labCreateApplyRepositoryProvider),
    )..load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCreateSheet() async {
    final auth = ref.read(authControllerProvider);
    final profile = auth.profile!;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _CreateApplySheet(
          profile: profile,
          colleges: _controller.collegeOptions,
          onSubmit:
              (
                int collegeId,
                String labName,
                String teacherName,
                String? location,
                String? contactEmail,
                String researchDirection,
                String applyReason,
              ) {
                return _controller.submitApply(
                  collegeId: collegeId,
                  labName: labName,
                  teacherName: teacherName,
                  location: location,
                  contactEmail: contactEmail,
                  researchDirection: researchDirection,
                  applyReason: applyReason,
                );
              },
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('实验室创建申请已提交')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('实验室创建申请'),
            actions: <Widget>[
              IconButton(
                tooltip: '刷新',
                onPressed: _controller.loading ? null : _controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: '新建申请',
                onPressed: _controller.submitting ? null : _openCreateSheet,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          body: ResponsiveListView(
            onRefresh: _controller.refresh,
            children: <Widget>[
              PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '在线发起实验室创建申请并跟踪审批状态',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '提交后会进入学院审核，再由学校审核并在通过后生成实验室。',
                      style: TextStyle(height: 1.65, color: Color(0xFF6D7B92)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _keywordController,
                      decoration: InputDecoration(
                        hintText: '搜索实验室名称、指导教师或学院',
                        suffixIcon: IconButton(
                          onPressed: () =>
                              _controller.applyKeyword(_keywordController.text),
                          icon: const Icon(Icons.search_rounded),
                        ),
                      ),
                      onSubmitted: (_) =>
                          _controller.applyKeyword(_keywordController.text),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filters
                          .map(
                            (filter) => ChoiceChip(
                              label: Text(filter.label),
                              selected:
                                  _controller.statusFilter == filter.value,
                              onSelected: (_) =>
                                  _controller.applyStatus(filter.value),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_controller.loading && _controller.records.isEmpty)
                const PanelCard(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_controller.records.isEmpty)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: '暂无申请记录',
                    message: '当前筛选条件下没有查询到实验室创建申请。',
                  ),
                )
              else
                ..._controller.records.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ApplyItemCard(
                      item: item,
                      statusLabel: _controller.statusLabel(item.status),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              PanelCard(
                child: Row(
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: _controller.pageNum > 1
                          ? _controller.previousPage
                          : null,
                      child: const Text('上一页'),
                    ),
                    const Spacer(),
                    Text(
                      '${_controller.pageNum} / ${_controller.totalPages} · 共 ${_controller.total} 条',
                      style: const TextStyle(
                        color: Color(0xFF6D7B92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: _controller.pageNum < _controller.totalPages
                          ? _controller.nextPage
                          : null,
                      child: const Text('下一页'),
                    ),
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

class _ApplyItemCard extends StatelessWidget {
  const _ApplyItemCard({required this.item, required this.statusLabel});

  final LabCreateApplyItem item;
  final String statusLabel;

  Color get _statusColor {
    switch (item.status) {
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

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.labName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
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
                  statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${item.collegeName ?? '未命名学院'} · ${item.teacherName}',
            style: const TextStyle(
              color: Color(0xFF516074),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.researchDirection,
            style: const TextStyle(height: 1.65, color: Color(0xFF516074)),
          ),
          const SizedBox(height: 10),
          Text(
            item.applyReason,
            style: const TextStyle(height: 1.65, color: Color(0xFF6D7B92)),
          ),
          if ((item.collegeAuditComment ?? '').isNotEmpty ||
              (item.schoolAuditComment ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if ((item.collegeAuditComment ?? '').isNotEmpty)
                    Text(
                      '学院审核：${item.collegeAuditComment}',
                      style: const TextStyle(
                        color: Color(0xFF516074),
                        height: 1.55,
                      ),
                    ),
                  if ((item.schoolAuditComment ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      '学校审核：${item.schoolAuditComment}',
                      style: const TextStyle(
                        color: Color(0xFF516074),
                        height: 1.55,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: <Widget>[
              Text(
                '提交时间：${DateTimeFormatter.dateTime(item.createTime)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8792A6)),
              ),
              if (item.generatedLabId != null)
                Text(
                  '生成实验室 #${item.generatedLabId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8792A6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusFilter {
  const _StatusFilter({required this.label, required this.value});

  final String label;
  final String? value;
}

class _CreateApplySheet extends StatefulWidget {
  const _CreateApplySheet({
    required this.profile,
    required this.colleges,
    required this.onSubmit,
  });

  final UserProfile profile;
  final List<LabCreateApplyCollegeOption> colleges;
  final Future<bool> Function(
    int collegeId,
    String labName,
    String teacherName,
    String? location,
    String? contactEmail,
    String researchDirection,
    String applyReason,
  )
  onSubmit;

  @override
  State<_CreateApplySheet> createState() => _CreateApplySheetState();
}

class _CreateApplySheetState extends State<_CreateApplySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _labNameController;
  late final TextEditingController _teacherNameController;
  late final TextEditingController _locationController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _researchDirectionController;
  late final TextEditingController _applyReasonController;
  int? _collegeId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _labNameController = TextEditingController();
    _teacherNameController = TextEditingController(
      text: widget.profile.realName,
    );
    _locationController = TextEditingController();
    _contactEmailController = TextEditingController(
      text: widget.profile.email ?? '',
    );
    _researchDirectionController = TextEditingController();
    _applyReasonController = TextEditingController();
    _collegeId = widget.colleges.isNotEmpty ? widget.colleges.first.id : null;
    _syncCollegeByProfile();
  }

  @override
  void didUpdateWidget(covariant _CreateApplySheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.colleges != widget.colleges) {
      _syncCollegeByProfile();
    }
  }

  void _syncCollegeByProfile() {
    final profileCollege = widget.profile.college?.toString().trim();
    if (profileCollege == null || profileCollege.isEmpty) {
      return;
    }
    final matched = widget.colleges.where(
      (item) => item.collegeName == profileCollege,
    );
    if (matched.isNotEmpty) {
      _collegeId = matched.first.id;
    }
  }

  @override
  void dispose() {
    _labNameController.dispose();
    _teacherNameController.dispose();
    _locationController.dispose();
    _contactEmailController.dispose();
    _researchDirectionController.dispose();
    _applyReasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final collegeId = _collegeId;
    if (collegeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择所属学院')));
      return;
    }

    setState(() {
      _submitting = true;
    });

    final success = await widget.onSubmit(
      collegeId,
      _labNameController.text.trim(),
      _teacherNameController.text.trim(),
      _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      _contactEmailController.text.trim().isEmpty
          ? null
          : _contactEmailController.text.trim(),
      _researchDirectionController.text.trim(),
      _applyReasonController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('提交失败，请检查表单后重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                '发起实验室创建申请',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '填写实验室信息后提交，系统会进入学院和学校的审批流程。',
                style: TextStyle(height: 1.6, color: Color(0xFF6D7B92)),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: _collegeId,
                items: widget.colleges
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item.id,
                        child: Text(item.collegeName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _collegeId = value),
                decoration: const InputDecoration(labelText: '所属学院'),
                validator: (value) => value == null ? '请选择所属学院' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _labNameController,
                decoration: const InputDecoration(labelText: '实验室名称'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入实验室名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _teacherNameController,
                decoration: const InputDecoration(labelText: '指导教师'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入指导教师';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: '地点'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contactEmailController,
                decoration: const InputDecoration(labelText: '联系邮箱'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _researchDirectionController,
                decoration: const InputDecoration(labelText: '研究方向'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入研究方向';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _applyReasonController,
                decoration: const InputDecoration(labelText: '申请说明'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入申请说明';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
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
