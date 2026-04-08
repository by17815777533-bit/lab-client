import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/lab_summary.dart';
import '../../models/user_profile.dart';
import '../admin_management/admin_management_models.dart';
import 'admin_accounts_controller.dart';

class AdminAccountsPage extends ConsumerStatefulWidget {
  const AdminAccountsPage({super.key});

  @override
  ConsumerState<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends ConsumerState<AdminAccountsPage> {
  late final AdminAccountsController _controller;
  late final UserProfile _profile;
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = ref.read(authControllerProvider).profile!;
    _controller = AdminAccountsController(
      repository: ref.read(adminManagementRepositoryProvider),
      labRepository: ref.read(labRepositoryProvider),
    )..load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEditor({AdminManagerUser? admin}) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _AdminEditorSheet(
          admin: admin,
          labs: _controller.labs,
          onSubmit:
              ({
                String? username,
                String? password,
                required String realName,
                required String email,
                required String phone,
                required int labId,
              }) async {
                final saved = await _controller.saveAdmin(
                  id: admin?.id,
                  username: username,
                  password: password,
                  realName: realName,
                  email: email,
                  phone: phone,
                  labId: labId,
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
    ).showSnackBar(const SnackBar(content: Text('管理员账号已保存')));
  }

  Future<void> _deleteAdmin(AdminManagerUser admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除管理员账号'),
          content: Text('确认删除 ${admin.realName} 的管理员账号吗？'),
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

    final success = await _controller.deleteAdmin(admin.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '管理员账号已删除' : _controller.errorMessage ?? '删除失败',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPermission = _profile.schoolDirector;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final admins = _controller.admins;
        final editableCount = admins.where((item) => item.editable).length;
        final lockedCount = admins.length - editableCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text('管理员账号'),
            actions: <Widget>[
              IconButton(
                tooltip: '刷新',
                onPressed: _controller.loading ? null : _controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: '新增账号',
                onPressed: _controller.saving ? null : _openEditor,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          body: ResponsiveListView(
            onRefresh: _controller.refresh,
            children: <Widget>[
              _HeroCard(
                profile: _profile,
                total: admins.length,
                editableCount: editableCount,
                lockedCount: lockedCount,
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
              if (!hasPermission)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: '当前账号暂不可使用',
                    message: '只有学校管理员可以管理管理员账号。',
                  ),
                )
              else ...<Widget>[
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '账号筛选',
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
                          hintText: '姓名 / 账号 / 邮箱 / 学院',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: _controller.setKeyword,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  total: admins.length,
                  editableCount: editableCount,
                  lockedCount: lockedCount,
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
                              '账号列表',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF12223A),
                              ),
                            ),
                          ),
                          Text(
                            '${admins.length} 个账号',
                            style: const TextStyle(
                              color: Color(0xFF6D7B92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_controller.loading && admins.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (admins.isEmpty)
                        const EmptyState(
                          icon: Icons.manage_accounts_outlined,
                          title: '暂无管理员账号',
                          message: '当前没有可展示的管理员账号。',
                        )
                      else
                        Column(
                          children: admins
                              .map(
                                (AdminManagerUser admin) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _AdminCard(
                                    admin: admin,
                                    labName: _labNameById(admin.labId),
                                    saving: _controller.saving,
                                    deleting: _controller.deleting,
                                    onEdit: admin.editable
                                        ? () => _openEditor(admin: admin)
                                        : null,
                                    onDelete: admin.editable
                                        ? () => _deleteAdmin(admin)
                                        : null,
                                  ),
                                ),
                              )
                              .toList(growable: false),
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

  String _labNameById(int? labId) {
    if (labId == null) {
      return '未绑定实验室';
    }
    final found = _controller.labs.cast<LabSummary?>().firstWhere(
      (LabSummary? item) => item?.id == labId,
      orElse: () => null,
    );
    return found?.labName ?? '实验室 #$labId';
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.total,
    required this.editableCount,
    required this.lockedCount,
  });

  final UserProfile profile;
  final int total;
  final int editableCount;
  final int lockedCount;

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
            '管理员账号管理',
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
            '统一维护管理员账号资料、实验室绑定和可编辑状态。',
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
              _HeroPill(label: '账号 $total 个'),
              _HeroPill(label: '可维护 $editableCount 个'),
              _HeroPill(label: '系统内置 $lockedCount 个'),
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
    required this.editableCount,
    required this.lockedCount,
  });

  final int total;
  final int editableCount;
  final int lockedCount;

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryData>[
      _SummaryData(label: '账号总数', value: '$total'),
      _SummaryData(label: '可维护', value: '$editableCount'),
      _SummaryData(label: '系统内置', value: '$lockedCount'),
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

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.admin,
    required this.labName,
    required this.saving,
    required this.deleting,
    this.onEdit,
    this.onDelete,
  });

  final AdminManagerUser admin;
  final String labName;
  final bool saving;
  final bool deleting;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = admin.editable
        ? const Color(0xFF2563EB)
        : const Color(0xFF6B7280);

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
                      admin.realName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${admin.username} · ${admin.email ?? '未填写邮箱'}',
                      style: const TextStyle(
                        color: Color(0xFF6D7B92),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: admin.editable ? '可维护' : '系统内置',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: <Widget>[
              _InfoPill(
                icon: Icons.phone_outlined,
                label: admin.phone ?? '未填写电话',
              ),
              _InfoPill(
                icon: Icons.apartment_outlined,
                label: admin.college ?? labName,
              ),
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: DateTimeFormatter.date(admin.createTime),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: saving ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑'),
              ),
              OutlinedButton.icon(
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
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

class _AdminEditorSheet extends StatefulWidget {
  const _AdminEditorSheet({
    required this.admin,
    required this.labs,
    required this.onSubmit,
  });

  final AdminManagerUser? admin;
  final List<LabSummary> labs;
  final Future<String?> Function({
    String? username,
    String? password,
    required String realName,
    required String email,
    required String phone,
    required int labId,
  })
  onSubmit;

  @override
  State<_AdminEditorSheet> createState() => _AdminEditorSheetState();
}

class _AdminEditorSheetState extends State<_AdminEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _realNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  int? _labId;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.admin?.username ?? '',
    );
    _passwordController = TextEditingController();
    _realNameController = TextEditingController(
      text: widget.admin?.realName ?? '',
    );
    _emailController = TextEditingController(text: widget.admin?.email ?? '');
    _phoneController = TextEditingController(text: widget.admin?.phone ?? '');
    _labId = widget.admin?.labId;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _realNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.admin != null;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_labId == null) {
      setState(() {
        _errorText = '请选择所属实验室';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final error = await widget.onSubmit(
      username: _isEdit ? null : _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      realName: _realNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      labId: _labId!,
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
                _isEdit ? '编辑管理员账号' : '新增管理员账号',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '维护账号资料并绑定实验室，用于日常审批与实验室管理。',
                style: TextStyle(color: Color(0xFF6D7B92), height: 1.5),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _usernameController,
                enabled: !_isEdit,
                decoration: const InputDecoration(labelText: '账号'),
                validator: (String? value) {
                  if (!_isEdit && (value ?? '').trim().isEmpty) {
                    return '请输入账号';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _isEdit ? '新密码' : '密码',
                  hintText: _isEdit ? '留空则保持不变' : null,
                ),
                validator: (String? value) {
                  if (!_isEdit && (value ?? '').trim().length < 6) {
                    return '密码至少 6 位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _realNameController,
                decoration: const InputDecoration(labelText: '姓名'),
                validator: (String? value) {
                  if ((value ?? '').trim().isEmpty) {
                    return '请输入姓名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '邮箱'),
                validator: (String? value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty || !text.contains('@')) {
                    return '请输入正确邮箱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '电话'),
                validator: (String? value) {
                  if ((value ?? '').trim().isEmpty) {
                    return '请输入电话';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
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
                      : const Text('保存账号'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
