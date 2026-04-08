import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../features/auth/auth_controller.dart';
import '../../models/lab_summary.dart';
import '../../models/outstanding_graduate.dart';
import '../../models/recruit_plan.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/graduate_repository.dart';
import '../../repositories/lab_repository.dart';
import '../../repositories/plan_repository.dart';
import 'labs_controller.dart';

class LabsPage extends StatefulWidget {
  const LabsPage({super.key});

  @override
  State<LabsPage> createState() => _LabsPageState();
}

class _LabsPageState extends State<LabsPage> {
  late final LabsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LabsController(
      labRepository: context.read<LabRepository>(),
      planRepository: context.read<PlanRepository>(),
      applicationRepository: context.read<ApplicationRepository>(),
      graduateRepository: context.read<GraduateRepository>(),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _canApply(LabSummary lab) {
    final profile = context.read<AuthController>().profile!;
    if (!profile.isStudent) {
      return false;
    }
    if (profile.labId != null) {
      return false;
    }
    if (!profile.hasResume) {
      return false;
    }
    if (!lab.isOpen) {
      return false;
    }
    return _controller.plansForLab(lab.id).isNotEmpty;
  }

  Future<void> _showLabDetail(LabSummary lab) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return FutureBuilder<(LabSummary, List<OutstandingGraduate>)>(
          future:
              Future.wait<dynamic>(<Future<dynamic>>[
                _controller.loadLabDetail(lab.id),
                _controller.loadLabGraduates(lab.id),
              ]).then(
                (List<dynamic> value) => (
                  value[0] as LabSummary,
                  value[1] as List<OutstandingGraduate>,
                ),
              ),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<(LabSummary, List<OutstandingGraduate>)> snapshot,
              ) {
                final detail = snapshot.data?.$1 ?? lab;
                final graduates =
                    snapshot.data?.$2 ?? const <OutstandingGraduate>[];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          detail.labName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12223A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          detail.labDesc ?? detail.basicInfo ?? '暂无实验室介绍',
                          style: const TextStyle(
                            height: 1.7,
                            color: Color(0xFF516074),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _MetaChip(
                              label: '编码',
                              value: detail.labCode ?? '-',
                            ),
                            _MetaChip(
                              label: '教师',
                              value: detail.teacherName ?? '-',
                            ),
                            _MetaChip(
                              label: '地点',
                              value: detail.location ?? '-',
                            ),
                            _MetaChip(
                              label: '容量',
                              value: '${detail.recruitNum} 人',
                            ),
                            _MetaChip(label: '状态', value: detail.statusLabel),
                          ],
                        ),
                        if ((detail.requireSkill ?? '').isNotEmpty) ...<Widget>[
                          const SizedBox(height: 20),
                          const Text(
                            '技能要求',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12223A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            detail.requireSkill!,
                            style: const TextStyle(
                              height: 1.7,
                              color: Color(0xFF516074),
                            ),
                          ),
                        ],
                        if ((detail.awards ?? '').isNotEmpty) ...<Widget>[
                          const SizedBox(height: 20),
                          const Text(
                            '成果与奖项',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12223A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            detail.awards!,
                            style: const TextStyle(
                              height: 1.7,
                              color: Color(0xFF516074),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          '更新时间：${DateTimeFormatter.dateTime(detail.updateTime)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8792A6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '优秀毕业生',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12223A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (graduates.isEmpty)
                          const Text(
                            '暂无优秀毕业生信息',
                            style: TextStyle(
                              color: Color(0xFF8792A6),
                              height: 1.6,
                            ),
                          )
                        else
                          Column(
                            children: graduates
                                .map(
                                  (OutstandingGraduate item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F7FC),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            '${item.name} · ${item.graduationYear ?? '未填写年份'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF12223A),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.destinationLabel,
                                            style: const TextStyle(
                                              color: Color(0xFF2F76FF),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            (item.description ?? '')
                                                    .trim()
                                                    .isEmpty
                                                ? '暂无介绍'
                                                : item.description!.trim(),
                                            style: const TextStyle(
                                              color: Color(0xFF516074),
                                              height: 1.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                      ],
                    ),
                  ),
                );
              },
        );
      },
    );
  }

  Future<void> _showApplySheet(LabSummary lab) async {
    final profile = context.read<AuthController>().profile!;
    if (!profile.hasResume) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先在“我的”页上传简历后再提交申请')));
      return;
    }

    final plans = _controller.plansForLab(lab.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _ApplySheet(
          lab: lab,
          plans: plans,
          onSubmit:
              ({
                required int recruitPlanId,
                required String applyReason,
                String? researchInterest,
                String? skillSummary,
              }) async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(this.context);
                try {
                  await _controller.submitApplication(
                    labId: lab.id,
                    recruitPlanId: recruitPlanId,
                    applyReason: applyReason,
                    researchInterest: researchInterest,
                    skillSummary: skillSummary,
                  );
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('申请已提交，请等待审核')),
                  );
                } on ApiException catch (error) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                }
              },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile!;

    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        return ResponsiveListView(
          onRefresh: _controller.load,
          children: <Widget>[
            _LabsHero(profile: profile),
            const SizedBox(height: 16),
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '实验室总览',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12223A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '浏览实验室介绍、老师信息和招新计划，满足条件时可直接提交入组申请。',
                    style: TextStyle(height: 1.65, color: Color(0xFF6D7B92)),
                  ),
                  if (profile.labId != null) ...<Widget>[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFAF3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        '你已加入实验室，仍可浏览实验室信息，但不能重复提交入组申请。',
                        style: TextStyle(
                          color: Color(0xFF0F9D58),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_controller.loading && _controller.labs.isEmpty)
              const PanelCard(child: Center(child: CircularProgressIndicator()))
            else if (_controller.labs.isEmpty)
              const PanelCard(
                child: EmptyState(
                  icon: Icons.apartment_rounded,
                  title: '暂无实验室',
                  message: '当前没有可展示的实验室信息。',
                ),
              )
            else
              ..._controller.labs.map(
                (lab) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 58,
                          height: 4,
                          decoration: BoxDecoration(
                            color: lab.isOpen
                                ? const Color(0xFF0F9D58)
                                : const Color(0xFF8792A6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    lab.labCode ?? '未配置编码',
                                    style: const TextStyle(
                                      color: Color(0xFF2F76FF),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lab.labName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF12223A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: lab.isOpen
                                    ? const Color(0xFFEFFAF3)
                                    : const Color(0xFFF3F5F9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                lab.statusLabel,
                                style: TextStyle(
                                  color: lab.isOpen
                                      ? const Color(0xFF0F9D58)
                                      : const Color(0xFF6D7B92),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lab.labDesc ?? '暂无实验室简介',
                          style: const TextStyle(
                            height: 1.7,
                            color: Color(0xFF516074),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _MetaChip(
                              label: '教师',
                              value: lab.teacherName ?? '-',
                            ),
                            _MetaChip(label: '地点', value: lab.location ?? '-'),
                            _MetaChip(
                              label: '容量',
                              value: '${lab.recruitNum} 人',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _controller
                              .plansForLab(lab.id)
                              .map(
                                (plan) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x142F76FF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    plan.title,
                                    style: const TextStyle(
                                      color: Color(0xFF2F76FF),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showLabDetail(lab),
                                child: const Text('查看详情'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _canApply(lab)
                                    ? () => _showApplySheet(lab)
                                    : null,
                                child: Text(_canApply(lab) ? '申请加入' : '当前不可申请'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label：$value',
        style: const TextStyle(
          color: Color(0xFF516074),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LabsHero extends StatelessWidget {
  const _LabsHero({required this.profile});

  final dynamic profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
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
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '实验室查询',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                profile.labId == null
                    ? '挑选实验室时，先看研究方向、指导老师和招新计划，再决定是否提交申请。'
                    : '你已经加入实验室，当前页仍可继续浏览其他实验室介绍与展示信息。',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplySheet extends StatefulWidget {
  const _ApplySheet({
    required this.lab,
    required this.plans,
    required this.onSubmit,
  });

  final LabSummary lab;
  final List<RecruitPlan> plans;
  final Future<void> Function({
    required int recruitPlanId,
    required String applyReason,
    String? researchInterest,
    String? skillSummary,
  })
  onSubmit;

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _applyReasonController = TextEditingController();
  final TextEditingController _researchInterestController =
      TextEditingController();
  final TextEditingController _skillSummaryController = TextEditingController();
  late int _selectedPlanId = widget.plans.first.id;
  bool _submitting = false;

  @override
  void dispose() {
    _applyReasonController.dispose();
    _researchInterestController.dispose();
    _skillSummaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await widget.onSubmit(
        recruitPlanId: _selectedPlanId,
        applyReason: _applyReasonController.text.trim(),
        researchInterest: _researchInterestController.text.trim(),
        skillSummary: _skillSummaryController.text.trim(),
      );
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '申请加入 ${widget.lab.labName}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12223A),
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<int>(
              initialValue: _selectedPlanId,
              decoration: const InputDecoration(labelText: '招新计划'),
              items: widget.plans
                  .map(
                    (plan) => DropdownMenuItem<int>(
                      value: plan.id,
                      child: Text(plan.title),
                    ),
                  )
                  .toList(),
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    _selectedPlanId = value;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _applyReasonController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '申请理由'),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return '请填写申请理由';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _researchInterestController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '研究兴趣'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _skillSummaryController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '技能概述'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('提交申请'),
            ),
          ],
        ),
      ),
    );
  }
}
