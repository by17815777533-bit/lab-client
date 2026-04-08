import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../features/auth/auth_controller.dart';
import '../../models/outstanding_graduate.dart';
import '../../repositories/graduate_repository.dart';
import 'graduate_management_controller.dart';

class GraduateManagementPage extends StatefulWidget {
  const GraduateManagementPage({super.key});

  @override
  State<GraduateManagementPage> createState() => _GraduateManagementPageState();
}

class _GraduateManagementPageState extends State<GraduateManagementPage> {
  late final GraduateManagementController _controller;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthController>().profile!;
    _controller = GraduateManagementController(
      repository: context.read<GraduateRepository>(),
      profile: profile,
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEditor({OutstandingGraduate? graduate}) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _GraduateEditorSheet(
          graduate: graduate,
          onSubmit:
              ({
                required String name,
                required String major,
                required String graduationYear,
                String? company,
                String? position,
                String? description,
              }) async {
                final saved = await _controller.saveGraduate(
                  id: graduate?.id,
                  name: name,
                  major: major,
                  graduationYear: graduationYear,
                  company: company,
                  position: position,
                  description: description,
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
    ).showSnackBar(const SnackBar(content: Text('优秀毕业生信息已保存')));
  }

  Future<void> _deleteGraduate(OutstandingGraduate graduate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除毕业生信息'),
          content: Text('确认删除 ${graduate.name} 的展示信息吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D),
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

    final success = await _controller.deleteGraduate(graduate.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '优秀毕业生信息已删除' : _controller.errorMessage ?? '删除失败',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final graduates = _controller.graduates;

        return Scaffold(
          appBar: AppBar(
            title: const Text('优秀毕业生'),
            actions: <Widget>[
              if (_controller.canManage)
                IconButton(
                  tooltip: '新增',
                  onPressed: _controller.saving ? null : _openEditor,
                  icon: const Icon(Icons.add_circle_outline_rounded),
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
              _GraduateHeroCard(total: _controller.total),
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
              if (!_controller.canManage)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: '当前账号不可维护',
                    message: '只有实验室管理员可以维护优秀毕业生内容。',
                  ),
                )
              else if (_controller.loading && graduates.isEmpty)
                const PanelCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (graduates.isEmpty)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.workspace_premium_outlined,
                    title: '暂无优秀毕业生',
                    message: '当前实验室还没有展示中的优秀毕业生信息。',
                  ),
                )
              else
                ...graduates.map(
                  (OutstandingGraduate graduate) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _GraduateCard(
                      graduate: graduate,
                      onEdit: () => _openEditor(graduate: graduate),
                      onDelete: () => _deleteGraduate(graduate),
                    ),
                  ),
                ),
              if (_controller.totalPages > 1) ...<Widget>[
                const SizedBox(height: 8),
                PanelCard(
                  child: Row(
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
                        onPressed: _controller.pageNum < _controller.totalPages
                            ? _controller.nextPage
                            : null,
                        child: const Text('下一页'),
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

class _GraduateHeroCard extends StatelessWidget {
  const _GraduateHeroCard({required this.total});

  final int total;

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
            '沉淀实验室成长样本',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '展示真实去向、专业背景和成长经历，方便新成员判断方向。',
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
              _HeroPill(
                icon: Icons.workspace_premium_outlined,
                label: '当前 $total 位',
              ),
              const _HeroPill(icon: Icons.apartment_outlined, label: '当前实验室'),
              const _HeroPill(icon: Icons.school_outlined, label: '真实去向展示'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GraduateCard extends StatelessWidget {
  const _GraduateCard({
    required this.graduate,
    required this.onEdit,
    required this.onDelete,
  });

  final OutstandingGraduate graduate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDCEBFF),
                child: Text(
                  graduate.initials,
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      graduate.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${graduate.major ?? '未填写专业'} · ${graduate.graduationYear ?? '未填写年份'}',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      graduate.destinationLabel,
                      style: const TextStyle(
                        color: Color(0xFF2F76FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            (graduate.description ?? '').trim().isEmpty
                ? '暂无介绍'
                : graduate.description!.trim(),
            style: const TextStyle(height: 1.65, color: Color(0xFF516074)),
          ),
          const SizedBox(height: 12),
          Text(
            '更新时间：${DateTimeFormatter.dateTime(graduate.updateTime ?? graduate.createTime)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8792A6)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB42318),
                ),
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

class _GraduateEditorSheet extends StatefulWidget {
  const _GraduateEditorSheet({required this.onSubmit, this.graduate});

  final OutstandingGraduate? graduate;
  final Future<String?> Function({
    required String name,
    required String major,
    required String graduationYear,
    String? company,
    String? position,
    String? description,
  })
  onSubmit;

  @override
  State<_GraduateEditorSheet> createState() => _GraduateEditorSheetState();
}

class _GraduateEditorSheetState extends State<_GraduateEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _majorController;
  late final TextEditingController _graduationYearController;
  late final TextEditingController _companyController;
  late final TextEditingController _positionController;
  late final TextEditingController _descriptionController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final graduate = widget.graduate;
    _nameController = TextEditingController(text: graduate?.name ?? '');
    _majorController = TextEditingController(text: graduate?.major ?? '');
    _graduationYearController = TextEditingController(
      text: graduate?.graduationYear ?? '',
    );
    _companyController = TextEditingController(text: graduate?.company ?? '');
    _positionController = TextEditingController(text: graduate?.position ?? '');
    _descriptionController = TextEditingController(
      text: graduate?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    _graduationYearController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _descriptionController.dispose();
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
      final error = await widget.onSubmit(
        name: _nameController.text.trim(),
        major: _majorController.text.trim(),
        graduationYear: _graduationYearController.text.trim(),
        company: _companyController.text.trim(),
        position: _positionController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.graduate == null ? '新增优秀毕业生' : '编辑优秀毕业生',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12223A),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '姓名'),
              validator: (String? value) =>
                  (value ?? '').trim().isEmpty ? '请输入姓名' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _majorController,
              decoration: const InputDecoration(labelText: '专业'),
              validator: (String? value) =>
                  (value ?? '').trim().isEmpty ? '请输入专业' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _graduationYearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '毕业年份',
                hintText: '例如 2025',
              ),
              validator: (String? value) {
                final raw = (value ?? '').trim();
                if (raw.isEmpty) {
                  return '请输入毕业年份';
                }
                if (raw.length != 4 || int.tryParse(raw) == null) {
                  return '请输入四位年份';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: '就业单位'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _positionController,
              decoration: const InputDecoration(labelText: '职位'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '介绍',
                hintText: '补充成长经历、方向建议或去向说明',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '保存中...' : '确认保存'),
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
