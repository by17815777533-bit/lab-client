import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../features/auth/auth_controller.dart';
import '../../repositories/lab_repository.dart';
import 'lab_info_management_controller.dart';

class LabInfoManagementPage extends StatefulWidget {
  const LabInfoManagementPage({super.key});

  @override
  State<LabInfoManagementPage> createState() => _LabInfoManagementPageState();
}

class _LabInfoManagementPageState extends State<LabInfoManagementPage> {
  late final LabInfoManagementController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _labNameController;
  late final TextEditingController _labDescController;
  late final TextEditingController _requireSkillController;
  late final TextEditingController _recruitNumController;
  late final TextEditingController _foundingDateController;
  late final TextEditingController _advisorsController;
  late final TextEditingController _currentAdminsController;
  late final TextEditingController _awardsController;
  late final TextEditingController _basicInfoController;
  late final TextEditingController _teacherNameController;
  late final TextEditingController _locationController;
  late final TextEditingController _contactEmailController;
  int _status = 1;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthController>().profile!;
    _controller = LabInfoManagementController(
      repository: context.read<LabRepository>(),
      labId: profile.labId!,
    )..load();
    _labNameController = TextEditingController();
    _labDescController = TextEditingController();
    _requireSkillController = TextEditingController();
    _recruitNumController = TextEditingController();
    _foundingDateController = TextEditingController();
    _advisorsController = TextEditingController();
    _currentAdminsController = TextEditingController();
    _awardsController = TextEditingController();
    _basicInfoController = TextEditingController();
    _teacherNameController = TextEditingController();
    _locationController = TextEditingController();
    _contactEmailController = TextEditingController();
    _controller.addListener(_syncFormIfReady);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncFormIfReady);
    _controller.dispose();
    _labNameController.dispose();
    _labDescController.dispose();
    _requireSkillController.dispose();
    _recruitNumController.dispose();
    _foundingDateController.dispose();
    _advisorsController.dispose();
    _currentAdminsController.dispose();
    _awardsController.dispose();
    _basicInfoController.dispose();
    _teacherNameController.dispose();
    _locationController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  void _syncFormIfReady() {
    final lab = _controller.lab;
    if (lab == null) {
      return;
    }
    _labNameController.text = lab.labName;
    _labDescController.text = lab.labDesc ?? '';
    _requireSkillController.text = lab.requireSkill ?? '';
    _recruitNumController.text = '${lab.recruitNum}';
    _foundingDateController.text = lab.foundingDate ?? '';
    _advisorsController.text = lab.advisors ?? '';
    _currentAdminsController.text = lab.currentAdmins ?? '';
    _awardsController.text = lab.awards ?? '';
    _basicInfoController.text = lab.basicInfo ?? '';
    _teacherNameController.text = lab.teacherName ?? '';
    _locationController.text = lab.location ?? '';
    _contactEmailController.text = lab.contactEmail ?? '';
    _status = lab.status == 1 ? 1 : 2;
  }

  Future<void> _submit() async {
    final lab = _controller.lab;
    if (lab == null || !_formKey.currentState!.validate()) {
      return;
    }
    final recruitNum = int.tryParse(_recruitNumController.text.trim());
    if (recruitNum == null || recruitNum < lab.currentNum) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成员上限不能小于当前正式成员数 ${lab.currentNum}')),
      );
      return;
    }

    final success = await _controller.saveLabInfo(
      labName: _labNameController.text.trim(),
      labCode: lab.labCode,
      collegeId: lab.collegeId,
      labDesc: _labDescController.text.trim(),
      teacherName: _teacherNameController.text.trim(),
      location: _locationController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      requireSkill: _requireSkillController.text.trim(),
      recruitNum: recruitNum,
      currentNum: lab.currentNum,
      status: _status,
      foundingDate: _foundingDateController.text.trim(),
      awards: _awardsController.text.trim(),
      basicInfo: _basicInfoController.text.trim(),
      advisors: _advisorsController.text.trim(),
      currentAdmins: _currentAdminsController.text.trim(),
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '实验室信息已保存' : _controller.errorMessage ?? '保存失败',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile!;
    final canUse = profile.labManager;

    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final lab = _controller.lab;

        return Scaffold(
          appBar: AppBar(
            title: const Text('实验室信息'),
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
              _LabInfoHeroCard(labName: lab?.labName ?? '实验室信息'),
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
              if (!canUse)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: '当前账号不可维护',
                    message: '只有实验室管理员可以维护实验室信息。',
                  ),
                )
              else if (_controller.loading && lab == null)
                const PanelCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (lab == null)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.apartment_outlined,
                    title: '未获取到实验室信息',
                    message: '当前未读取到实验室详情。',
                  ),
                )
              else ...<Widget>[
                PanelCard(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/admin/graduates'),
                        icon: const Icon(Icons.workspace_premium_outlined),
                        label: const Text('优秀毕业生'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/admin/workspace'),
                        icon: const Icon(Icons.folder_open_outlined),
                        label: const Text('空间工作台'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '基础状态',
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
                          _StatusTile(
                            title: '实验室编码',
                            value: lab.labCode ?? '-',
                          ),
                          _StatusTile(
                            title: '当前成员',
                            value: '${lab.currentNum} 人',
                          ),
                          _StatusTile(title: '当前状态', value: lab.statusLabel),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PanelCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          '信息维护',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12223A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _labNameController,
                          decoration: const InputDecoration(labelText: '实验室名称'),
                          validator: (String? value) =>
                              (value ?? '').trim().isEmpty ? '请输入实验室名称' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _status,
                          decoration: const InputDecoration(labelText: '招新状态'),
                          items: const <DropdownMenuItem<int>>[
                            DropdownMenuItem<int>(value: 1, child: Text('招新中')),
                            DropdownMenuItem<int>(value: 2, child: Text('已关闭')),
                          ],
                          onChanged: (int? value) {
                            if (value != null) {
                              setState(() {
                                _status = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _recruitNumController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '成员总数上限',
                            helperText: '当前正式成员数为 ${lab.currentNum} 人',
                          ),
                          validator: (String? value) {
                            final parsed = int.tryParse((value ?? '').trim());
                            if (parsed == null || parsed <= 0) {
                              return '请输入有效人数';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _requireSkillController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: '技能要求',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _foundingDateController,
                          decoration: const InputDecoration(
                            labelText: '成立时间',
                            hintText: '例如 2021-09',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _teacherNameController,
                          decoration: const InputDecoration(labelText: '指导老师'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _advisorsController,
                          decoration: const InputDecoration(
                            labelText: '指导教师说明',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _currentAdminsController,
                          decoration: const InputDecoration(labelText: '当前管理员'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: '地点'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _contactEmailController,
                          decoration: const InputDecoration(labelText: '联系邮箱'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _awardsController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: '获奖情况',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _basicInfoController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: '基础信息',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _labDescController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: '实验室简介',
                            alignLabelWithHint: true,
                          ),
                          validator: (String? value) =>
                              (value ?? '').trim().isEmpty ? '请输入实验室简介' : null,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _controller.saving ? null : _submit,
                            child: Text(_controller.saving ? '保存中...' : '保存修改'),
                          ),
                        ),
                      ],
                    ),
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

class _LabInfoHeroCard extends StatelessWidget {
  const _LabInfoHeroCard({required this.labName});

  final String labName;

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
          Text(
            labName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '维护实验室基础介绍、招新状态与展示信息，保证学生看到的内容始终是新的。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF4F7FC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF12223A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
