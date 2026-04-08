import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/utils/file_url_resolver.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/equipment_borrow_record.dart';
import '../../models/equipment_item.dart';
import '../../repositories/equipment_repository.dart';
import 'equipment_admin_controller.dart';

class EquipmentAdminPage extends StatefulWidget {
  const EquipmentAdminPage({
    super.key,
    required this.repository,
    required this.baseUrl,
    this.labId,
  });

  final EquipmentRepository repository;
  final String baseUrl;
  final int? labId;

  @override
  State<EquipmentAdminPage> createState() => _EquipmentAdminPageState();
}

class _EquipmentAdminPageState extends State<EquipmentAdminPage> {
  late final EquipmentAdminController _controller;
  final TextEditingController _equipmentNameController =
      TextEditingController();
  final TextEditingController _labIdController = TextEditingController();
  final TextEditingController _dialogNameController = TextEditingController();
  final TextEditingController _dialogTypeController = TextEditingController();
  final TextEditingController _dialogSerialController = TextEditingController();
  final TextEditingController _dialogImageController = TextEditingController();
  final TextEditingController _dialogDescriptionController =
      TextEditingController();
  final GlobalKey<FormState> _equipmentFormKey = GlobalKey<FormState>();
  int _tabIndex = 0;
  int _equipmentStatusFilter = -1;
  int _borrowStatusFilter = -1;
  int _equipmentDialogStatus = 0;
  bool _editingEquipment = false;
  int? _editingEquipmentId;
  int? _borrowActionId;
  String? _borrowActionTitle;

  @override
  void initState() {
    super.initState();
    _controller = EquipmentAdminController(
      repository: widget.repository,
      labId: widget.labId,
    );
    if (widget.labId != null) {
      _labIdController.text = widget.labId.toString();
    }
    _controller.refreshAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    _equipmentNameController.dispose();
    _labIdController.dispose();
    _dialogNameController.dispose();
    _dialogTypeController.dispose();
    _dialogSerialController.dispose();
    _dialogImageController.dispose();
    _dialogDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _applyEquipmentFilters() async {
    final labId = int.tryParse(_labIdController.text.trim());
    _controller
      ..setLabId(labId)
      ..setEquipmentName(_equipmentNameController.text)
      ..setEquipmentStatus(
        _equipmentStatusFilter < 0 ? null : _equipmentStatusFilter,
      );
    await Future.wait(<Future<void>>[
      _controller.loadEquipment(),
      _controller.loadBorrowRecords(),
    ]);
  }

  Future<void> _applyBorrowFilters() async {
    final labId = int.tryParse(_labIdController.text.trim());
    _controller
      ..setLabId(labId)
      ..setBorrowStatus(_borrowStatusFilter < 0 ? null : _borrowStatusFilter);
    await _controller.loadBorrowRecords();
  }

  Future<void> _resetEquipmentFilters() async {
    _equipmentNameController.clear();
    _equipmentStatusFilter = -1;
    _labIdController.text = widget.labId?.toString() ?? '';
    _controller
      ..setLabId(widget.labId)
      ..resetEquipmentFilters();
    await Future.wait(<Future<void>>[
      _controller.loadEquipment(),
      _controller.loadBorrowRecords(),
    ]);
  }

  Future<void> _resetBorrowFilters() async {
    _borrowStatusFilter = -1;
    _labIdController.text = widget.labId?.toString() ?? '';
    _controller
      ..setLabId(widget.labId)
      ..resetBorrowFilters();
    await Future.wait(<Future<void>>[
      _controller.loadEquipment(),
      _controller.loadBorrowRecords(),
    ]);
  }

  Future<void> _openEquipmentDialog({EquipmentItem? item}) async {
    _editingEquipment = item != null;
    _editingEquipmentId = item?.id;
    _equipmentDialogStatus = item?.status ?? 0;
    _dialogNameController.text = item?.name ?? '';
    _dialogTypeController.text = item?.type ?? '';
    _dialogSerialController.text = item?.serialNumber ?? '';
    _dialogImageController.text = item?.imageUrl ?? '';
    _dialogDescriptionController.text = item?.description ?? '';

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_editingEquipment ? '编辑设备' : '新增设备'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _equipmentFormKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: _dialogNameController,
                      decoration: const InputDecoration(labelText: '设备名称'),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return '请输入设备名称';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _dialogTypeController,
                      decoration: const InputDecoration(labelText: '设备类型'),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return '请输入设备类型';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _dialogSerialController,
                      decoration: const InputDecoration(labelText: '设备编号'),
                    ),
                    TextFormField(
                      controller: _dialogImageController,
                      decoration: const InputDecoration(labelText: '图片地址'),
                    ),
                    TextFormField(
                      controller: _dialogDescriptionController,
                      decoration: const InputDecoration(labelText: '描述'),
                      maxLines: 3,
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: _equipmentDialogStatus,
                      decoration: const InputDecoration(labelText: '状态'),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(value: 0, child: Text('空闲')),
                        DropdownMenuItem(value: 1, child: Text('借用中')),
                        DropdownMenuItem(value: 2, child: Text('维修中')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _equipmentDialogStatus = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => context.pop(), child: const Text('取消')),
            FilledButton(
              onPressed: _controller.submitting
                  ? null
                  : () async {
                      if (!_equipmentFormKey.currentState!.validate()) {
                        return;
                      }
                      final success = await _controller.saveEquipment(
                        id: _editingEquipmentId,
                        name: _dialogNameController.text.trim(),
                        type: _dialogTypeController.text.trim(),
                        serialNumber:
                            _dialogSerialController.text.trim().isEmpty
                            ? null
                            : _dialogSerialController.text.trim(),
                        imageUrl: _dialogImageController.text.trim().isEmpty
                            ? null
                            : _dialogImageController.text.trim(),
                        description:
                            _dialogDescriptionController.text.trim().isEmpty
                            ? null
                            : _dialogDescriptionController.text.trim(),
                        status: _equipmentDialogStatus,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      if (success) {
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _editingEquipment ? '设备信息已更新' : '设备已新增',
                            ),
                          ),
                        );
                      } else if (_controller.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_controller.errorMessage!)),
                        );
                      }
                    },
              child: Text(_editingEquipment ? '保存' : '新增'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBorrowActionDialog(
    EquipmentBorrowRecord record, {
    required int status,
  }) async {
    _borrowActionId = record.id;
    _borrowActionTitle = status == 1 ? '通过借用申请' : '拒绝借用申请';

    final success = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_borrowActionTitle ?? '借用审核'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              status == 1
                  ? '确认通过这条借用申请后，设备状态将进入借出流程。'
                  : '确认拒绝这条借用申请后，申请人会收到拒绝结果。'
                        '\n\n设备：#${record.equipmentId ?? "-"}\n申请人：#${record.userId ?? "-"}',
              style: const TextStyle(height: 1.65),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: _controller.submitting
                  ? null
                  : () async {
                      final success = await _controller.auditBorrow(
                        id: _borrowActionId!,
                        status: status,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      context.pop(success);
                    },
              child: Text(status == 1 ? '通过' : '拒绝'),
            ),
          ],
        );
      },
    );

    if (!mounted || success != true) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(status == 1 ? '借用申请已通过' : '借用申请已拒绝')),
    );
  }

  Future<void> _confirmReturn(EquipmentBorrowRecord record) async {
    final success = await _controller.confirmReturn(id: record.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '已确认归还' : _controller.errorMessage ?? '确认失败'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('设备管理'),
            actions: <Widget>[
              TextButton.icon(
                onPressed: _controller.submitting
                    ? null
                    : _controller.refreshAll,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('刷新'),
              ),
            ],
          ),
          body: ResponsiveListView(
            onRefresh: _controller.refreshAll,
            children: <Widget>[
              _AdminHeroCard(
                labId: _controller.labId,
                equipmentCount: _controller.equipmentTotal,
                borrowCount: _controller.borrowTotal,
                onOpenWorkspace: () => context.go('/admin/statistics'),
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
              Wrap(
                spacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('设备列表'),
                    selected: _tabIndex == 0,
                    onSelected: (_) => setState(() => _tabIndex = 0),
                  ),
                  ChoiceChip(
                    label: const Text('借用审核'),
                    selected: _tabIndex == 1,
                    onSelected: (_) => setState(() => _tabIndex = 1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_tabIndex == 0)
                _EquipmentTab(
                  controller: _controller,
                  baseUrl: widget.baseUrl,
                  equipmentNameController: _equipmentNameController,
                  labIdController: _labIdController,
                  equipmentStatusFilter: _equipmentStatusFilter,
                  onEquipmentStatusFilterChanged: (value) {
                    setState(() => _equipmentStatusFilter = value);
                  },
                  onSearch: _applyEquipmentFilters,
                  onReset: _resetEquipmentFilters,
                  onAddEquipment: () => _openEquipmentDialog(),
                  onEditEquipment: (item) => _openEquipmentDialog(item: item),
                  onDeleteEquipment: _confirmDeleteEquipment,
                )
              else
                _BorrowTab(
                  controller: _controller,
                  labIdController: _labIdController,
                  borrowStatusFilter: _borrowStatusFilter,
                  onBorrowStatusFilterChanged: (value) {
                    setState(() => _borrowStatusFilter = value);
                  },
                  onSearch: _applyBorrowFilters,
                  onReset: _resetBorrowFilters,
                  onApprove: (record) =>
                      _showBorrowActionDialog(record, status: 1),
                  onReject: (record) =>
                      _showBorrowActionDialog(record, status: 2),
                  onConfirmReturn: _confirmReturn,
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteEquipment(EquipmentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除设备'),
          content: Text('确认删除设备“${item.name}”？该操作不可恢复。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('取消'),
            ),
            FilledButton.tonal(
              onPressed: () => context.pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }
    final success = await _controller.deleteEquipment(item.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '设备已删除' : _controller.errorMessage ?? '删除失败'),
      ),
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({
    required this.labId,
    required this.equipmentCount,
    required this.borrowCount,
    required this.onOpenWorkspace,
  });

  final int? labId;
  final int equipmentCount;
  final int borrowCount;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF163B75), Color(0xFF2F76FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '设备管理',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            labId == null ? '当前按账号权限展示实验室范围' : '当前实验室编号：$labId',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _HeroStatChip(label: '设备 $equipmentCount'),
              _HeroStatChip(label: '借用 $borrowCount'),
              _HeroStatChip(label: '支持审核'),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onOpenWorkspace,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF163B75),
            ),
            icon: const Icon(Icons.query_stats_rounded),
            label: const Text('查看统计'),
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EquipmentTab extends StatelessWidget {
  const _EquipmentTab({
    required this.controller,
    required this.baseUrl,
    required this.equipmentNameController,
    required this.labIdController,
    required this.equipmentStatusFilter,
    required this.onEquipmentStatusFilterChanged,
    required this.onSearch,
    required this.onReset,
    required this.onAddEquipment,
    required this.onEditEquipment,
    required this.onDeleteEquipment,
  });

  final EquipmentAdminController controller;
  final String baseUrl;
  final TextEditingController equipmentNameController;
  final TextEditingController labIdController;
  final int equipmentStatusFilter;
  final ValueChanged<int> onEquipmentStatusFilterChanged;
  final Future<void> Function() onSearch;
  final Future<void> Function() onReset;
  final VoidCallback onAddEquipment;
  final ValueChanged<EquipmentItem> onEditEquipment;
  final ValueChanged<EquipmentItem> onDeleteEquipment;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
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
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: equipmentNameController,
                      decoration: const InputDecoration(
                        labelText: '设备名称',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: labIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '实验室编号'),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<int>(
                      initialValue: equipmentStatusFilter < 0
                          ? null
                          : equipmentStatusFilter,
                      decoration: const InputDecoration(labelText: '状态'),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(value: 0, child: Text('空闲')),
                        DropdownMenuItem(value: 1, child: Text('借用中')),
                        DropdownMenuItem(value: 2, child: Text('维修中')),
                      ],
                      onChanged: (value) =>
                          onEquipmentStatusFilterChanged(value ?? -1),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onSearch,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('搜索'),
                  ),
                  OutlinedButton(onPressed: onReset, child: const Text('重置')),
                  FilledButton.tonalIcon(
                    onPressed: onAddEquipment,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('新增设备'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (controller.loadingEquipment && controller.equipmentItems.isEmpty)
          const PanelCard(child: Center(child: CircularProgressIndicator()))
        else if (controller.equipmentItems.isEmpty)
          const PanelCard(
            child: EmptyState(
              icon: Icons.precision_manufacturing_outlined,
              title: '暂无设备',
              message: '当前筛选条件下没有设备记录。',
            ),
          )
        else
          ...controller.equipmentItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PanelCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _EquipmentImage(baseUrl: baseUrl, imageUrl: item.imageUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF12223A),
                                  ),
                                ),
                              ),
                              _StatusPill(
                                text: item.statusLabel,
                                status: item.status,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.type ?? "-"} · 编号 ${item.serialNumber ?? "-"}',
                            style: const TextStyle(
                              color: Color(0xFF516074),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description ?? '暂无设备描述',
                            style: const TextStyle(
                              height: 1.6,
                              color: Color(0xFF6D7B92),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '创建时间：${DateTimeFormatter.dateTime(item.createTime)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8792A6),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              FilledButton.tonal(
                                onPressed: () => onEditEquipment(item),
                                child: const Text('编辑'),
                              ),
                              OutlinedButton(
                                onPressed: () => onDeleteEquipment(item),
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        PanelCard(
          child: Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: controller.equipmentPageNum > 1
                    ? controller.previousEquipmentPage
                    : null,
                child: const Text('上一页'),
              ),
              const Spacer(),
              Text(
                '${controller.equipmentPageNum} / ${controller.equipmentTotalPages} · 共 ${controller.equipmentTotal} 条',
                style: const TextStyle(
                  color: Color(0xFF6D7B92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed:
                    controller.equipmentPageNum < controller.equipmentTotalPages
                    ? controller.nextEquipmentPage
                    : null,
                child: const Text('下一页'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BorrowTab extends StatelessWidget {
  const _BorrowTab({
    required this.controller,
    required this.labIdController,
    required this.borrowStatusFilter,
    required this.onBorrowStatusFilterChanged,
    required this.onSearch,
    required this.onReset,
    required this.onApprove,
    required this.onReject,
    required this.onConfirmReturn,
  });

  final EquipmentAdminController controller;
  final TextEditingController labIdController;
  final int borrowStatusFilter;
  final ValueChanged<int> onBorrowStatusFilterChanged;
  final Future<void> Function() onSearch;
  final Future<void> Function() onReset;
  final ValueChanged<EquipmentBorrowRecord> onApprove;
  final ValueChanged<EquipmentBorrowRecord> onReject;
  final ValueChanged<EquipmentBorrowRecord> onConfirmReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '借用筛选',
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
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: labIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '实验室编号'),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<int>(
                      initialValue: borrowStatusFilter < 0
                          ? null
                          : borrowStatusFilter,
                      decoration: const InputDecoration(labelText: '状态'),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(value: 0, child: Text('申请中')),
                        DropdownMenuItem(value: 1, child: Text('已借出')),
                        DropdownMenuItem(value: 2, child: Text('已拒绝')),
                        DropdownMenuItem(value: 3, child: Text('已归还')),
                        DropdownMenuItem(value: 4, child: Text('已领用')),
                        DropdownMenuItem(value: 5, child: Text('待验收')),
                        DropdownMenuItem(value: 6, child: Text('已逾期')),
                      ],
                      onChanged: (value) =>
                          onBorrowStatusFilterChanged(value ?? -1),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onSearch,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('搜索'),
                  ),
                  OutlinedButton(onPressed: onReset, child: const Text('重置')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (controller.loadingBorrowRecords && controller.borrowRecords.isEmpty)
          const PanelCard(child: Center(child: CircularProgressIndicator()))
        else if (controller.borrowRecords.isEmpty)
          const PanelCard(
            child: EmptyState(
              icon: Icons.inbox_outlined,
              title: '暂无借用记录',
              message: '当前筛选条件下没有借用申请。',
            ),
          )
        else
          ...controller.borrowRecords.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '设备 #${record.equipmentId ?? "-"}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12223A),
                            ),
                          ),
                        ),
                        _BorrowStatusPill(record: record),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '申请人 #${record.userId ?? "-"}',
                      style: const TextStyle(
                        color: Color(0xFF516074),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.reason ?? '未填写原因',
                      style: const TextStyle(
                        height: 1.6,
                        color: Color(0xFF6D7B92),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: <Widget>[
                        Text(
                          '申请时间：${DateTimeFormatter.dateTime(record.createTime)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8792A6),
                          ),
                        ),
                        Text(
                          '借出时间：${DateTimeFormatter.dateTime(record.borrowTime)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8792A6),
                          ),
                        ),
                        Text(
                          '预计归还：${DateTimeFormatter.dateTime(record.expectedReturnTime)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8792A6),
                          ),
                        ),
                      ],
                    ),
                    if (record.returnTime != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        '实际归还：${DateTimeFormatter.dateTime(record.returnTime)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8792A6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if (record.isPending)
                          FilledButton.tonal(
                            onPressed: () => onApprove(record),
                            child: const Text('通过'),
                          ),
                        if (record.isPending)
                          OutlinedButton(
                            onPressed: () => onReject(record),
                            child: const Text('拒绝'),
                          ),
                        if (record.isBorrowed ||
                            record.isPickedUp ||
                            record.isWaitingReturnCheck)
                          FilledButton(
                            onPressed: () => onConfirmReturn(record),
                            child: const Text('确认归还'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        PanelCard(
          child: Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: controller.borrowPageNum > 1
                    ? controller.previousBorrowPage
                    : null,
                child: const Text('上一页'),
              ),
              const Spacer(),
              Text(
                '${controller.borrowPageNum} / ${controller.borrowTotalPages} · 共 ${controller.borrowTotal} 条',
                style: const TextStyle(
                  color: Color(0xFF6D7B92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed:
                    controller.borrowPageNum < controller.borrowTotalPages
                    ? controller.nextBorrowPage
                    : null,
                child: const Text('下一页'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EquipmentImage extends StatelessWidget {
  const _EquipmentImage({required this.baseUrl, required this.imageUrl});

  final String baseUrl;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = FileUrlResolver.resolve(
      baseUrl: baseUrl,
      rawUrl: imageUrl,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 110,
        height: 110,
        color: const Color(0xFFF4F7FC),
        child: resolvedUrl.isEmpty
            ? const Icon(
                Icons.precision_manufacturing_rounded,
                size: 40,
                color: Color(0xFF9AA7BB),
              )
            : Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 36,
                      color: Color(0xFF9AA7BB),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.status});

  final String text;
  final int status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      1 => const Color(0xFFB54708),
      2 => const Color(0xFFB42318),
      _ => const Color(0xFF067647),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _BorrowStatusPill extends StatelessWidget {
  const _BorrowStatusPill({required this.record});

  final EquipmentBorrowRecord record;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      1 => const Color(0xFF2F76FF),
      2 => const Color(0xFFB42318),
      3 => const Color(0xFF067647),
      4 => const Color(0xFF7F56D9),
      5 => const Color(0xFFB54708),
      6 => const Color(0xFFC01048),
      _ => const Color(0xFFB54708),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        record.statusLabel,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
