import 'package:flutter/material.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/equipment_borrow_record.dart';
import '../../models/equipment_item.dart';
import '../../models/user_profile.dart';
import '../../repositories/equipment_repository.dart';
import 'equipment_controller.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({
    super.key,
    required this.repository,
    required this.profile,
  });

  final EquipmentRepository repository;
  final UserProfile profile;

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  late final EquipmentController _controller;
  final TextEditingController _searchController = TextEditingController();
  int _sectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = EquipmentController(
      repository: widget.repository,
      profile: widget.profile,
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openBorrowDialog(EquipmentItem item) async {
    if (!item.isIdle) {
      return;
    }

    final reasonController = TextEditingController();
    var expectedReturnAt = _defaultExpectedReturnTime();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return AlertDialog(
              title: Text('借用 ${item.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '仅空闲设备可发起借用，提交后由实验室管理员审核。',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: '借用理由',
                        hintText: '说明借用用途、使用时长和预计归还安排',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final now = DateTime.now();
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: expectedReturnAt,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (pickedDate == null || !mounted) {
                          return;
                        }
                        if (!context.mounted) {
                          return;
                        }
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(expectedReturnAt),
                        );
                        if (pickedTime == null || !mounted) {
                          return;
                        }
                        setState(() {
                          expectedReturnAt = _combineDateAndTime(
                            pickedDate,
                            pickedTime,
                          );
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD9E2F1)),
                          color: const Color(0xFFF7FAFF),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.schedule_rounded,
                              size: 20,
                              color: Color(0xFF2F76FF),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '预计归还时间  ${DateTimeFormatter.dateTime(expectedReturnAt)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF12223A),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF6D7B92),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: _controller.submittingBorrow
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('请填写借用理由')),
                            );
                            return;
                          }
                          if (expectedReturnAt.isBefore(DateTime.now())) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('预计归还时间必须晚于当前时间')),
                            );
                            return;
                          }
                          Navigator.of(context).pop(true);
                        },
                  child: const Text('提交申请'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !mounted) {
      reasonController.dispose();
      return;
    }

    final success = await _controller.submitBorrow(
      equipmentId: item.id,
      reason: reasonController.text.trim(),
      expectedReturnTime: expectedReturnAt,
    );
    reasonController.dispose();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '借用申请已提交' : _controller.borrowErrorMessage ?? '借用申请失败',
        ),
      ),
    );
  }

  DateTime _defaultExpectedReturnTime() {
    final now = DateTime.now().add(const Duration(days: 7));
    return DateTime(now.year, now.month, now.day, 18);
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFF2F76FF);
      case 2:
        return const Color(0xFFF04438);
      default:
        return const Color(0xFF0F9D58);
    }
  }

  Color _borrowStatusColor(int status) {
    switch (status) {
      case 1:
      case 4:
        return const Color(0xFF2F76FF);
      case 2:
        return const Color(0xFFF04438);
      case 3:
        return const Color(0xFF0F9D58);
      case 5:
        return const Color(0xFFF59E0B);
      case 6:
        return const Color(0xFFB42318);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final hasLab = widget.profile.labId != null;
        final availableCount = _controller.equipmentItems
            .where((item) => item.isIdle)
            .length;
        final activeBorrowCount = _controller.borrowRecords
            .where((record) => record.status != 2 && record.status != 3)
            .length;
        final overdueCount = _controller.borrowRecords
            .where((record) => record.status == 6)
            .length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('设备借用'),
            actions: <Widget>[
              IconButton(
                tooltip: '刷新',
                onPressed:
                    _controller.loadingEquipment ||
                        _controller.loadingBorrowRecords
                    ? null
                    : _controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: ResponsiveListView(
            onRefresh: _controller.refresh,
            children: <Widget>[
              _HeroCard(
                profile: widget.profile,
                availableCount: availableCount,
                activeBorrowCount: activeBorrowCount,
                overdueCount: overdueCount,
              ),
              const SizedBox(height: 16),
              PanelCard(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final compact = constraints.maxWidth < 680;
                    final children = <Widget>[
                      Expanded(
                        child: _SwitchCard(
                          title: '设备目录',
                          subtitle: '查看空闲设备并发起借用申请',
                          icon: Icons.inventory_2_outlined,
                          selected: _sectionIndex == 0,
                          onTap: () => setState(() => _sectionIndex = 0),
                        ),
                      ),
                      Expanded(
                        child: _SwitchCard(
                          title: '我的借用',
                          subtitle: '追踪申请、借出、归还和验收状态',
                          icon: Icons.receipt_long_outlined,
                          selected: _sectionIndex == 1,
                          onTap: () => setState(() => _sectionIndex = 1),
                        ),
                      ),
                    ];

                    if (compact) {
                      return Column(
                        children: <Widget>[
                          children.first,
                          const SizedBox(height: 12),
                          children.last,
                        ],
                      );
                    }

                    return Row(
                      children: <Widget>[
                        children.first,
                        const SizedBox(width: 12),
                        children.last,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_sectionIndex == 0) ...<Widget>[
                if (_controller.equipmentErrorMessage != null) ...<Widget>[
                  PanelCard(
                    child: Text(
                      _controller.equipmentErrorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!hasLab)
                  const PanelCard(
                    child: EmptyState(
                      icon: Icons.build_outlined,
                      title: '当前未加入实验室',
                      message: '加入实验室后，这里会展示可借用设备。只有空闲设备可以发起借用申请。',
                    ),
                  )
                else ...<Widget>[
                  PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _SectionHeader(
                          title: '检索设备',
                          subtitle: '只展示当前实验室可见设备，空闲状态才可发起借用。',
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                final compact = constraints.maxWidth < 720;
                                if (compact) {
                                  return Column(
                                    children: <Widget>[
                                      TextField(
                                        controller: _searchController,
                                        textInputAction: TextInputAction.search,
                                        onSubmitted:
                                            _controller.searchEquipment,
                                        decoration: const InputDecoration(
                                          hintText: '输入设备名称或编号搜索',
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: FilledButton(
                                              onPressed:
                                                  _controller.loadingEquipment
                                                  ? null
                                                  : () => _controller
                                                        .searchEquipment(
                                                          _searchController
                                                              .text,
                                                        ),
                                              child: const Text('搜索'),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed:
                                                  _controller.loadingEquipment
                                                  ? null
                                                  : () async {
                                                      _searchController.clear();
                                                      await _controller
                                                          .clearEquipmentKeyword();
                                                    },
                                              child: const Text('清空'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        textInputAction: TextInputAction.search,
                                        onSubmitted:
                                            _controller.searchEquipment,
                                        decoration: const InputDecoration(
                                          hintText: '输入设备名称或编号搜索',
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton(
                                      onPressed: _controller.loadingEquipment
                                          ? null
                                          : () => _controller.searchEquipment(
                                              _searchController.text,
                                            ),
                                      child: const Text('搜索'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: _controller.loadingEquipment
                                          ? null
                                          : () async {
                                              _searchController.clear();
                                              await _controller
                                                  .clearEquipmentKeyword();
                                            },
                                      child: const Text('清空'),
                                    ),
                                  ],
                                );
                              },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '设备总数 ${_controller.equipmentTotal} 台，当前页可借用 $availableCount 台。',
                          style: const TextStyle(
                            color: Color(0xFF8792A6),
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_controller.loadingEquipment &&
                      _controller.equipmentItems.isEmpty)
                    const PanelCard(
                      child: SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_controller.equipmentItems.isEmpty)
                    const PanelCard(
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: '暂无可展示设备',
                        message: '当前筛选条件下没有查询到设备。',
                      ),
                    )
                  else
                    ..._controller.equipmentItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _EquipmentCard(
                          item: item,
                          statusColor: _statusColor(item.status),
                          onBorrow: item.isIdle && _controller.canBorrow
                              ? () => _openBorrowDialog(item)
                              : null,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  PanelCard(
                    child: Row(
                      children: <Widget>[
                        OutlinedButton(
                          onPressed:
                              _controller.equipmentPageNum > 1 &&
                                  !_controller.loadingEquipment
                              ? _controller.previousEquipmentPage
                              : null,
                          child: const Text('上一页'),
                        ),
                        const Spacer(),
                        Text(
                          '${_controller.equipmentPageNum} / ${_controller.equipmentTotalPages} · 共 ${_controller.equipmentTotal} 条',
                          style: const TextStyle(
                            color: Color(0xFF6D7B92),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.tonal(
                          onPressed:
                              (_controller.equipmentTotalPages == 0
                                      ? false
                                      : _controller.equipmentPageNum <
                                            _controller.equipmentTotalPages) &&
                                  !_controller.loadingEquipment
                              ? _controller.nextEquipmentPage
                              : null,
                          child: const Text('下一页'),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...<Widget>[
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _SectionHeader(
                        title: '我的借用记录',
                        subtitle: '按状态查看处理进度，及时关注借出、归还和逾期提醒。',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _StatusChip(
                            label: '全部',
                            selected: _controller.borrowStatusFilter == null,
                            onSelected: () =>
                                _controller.setBorrowStatusFilter(null),
                          ),
                          _StatusChip(
                            label: '申请中',
                            selected: _controller.borrowStatusFilter == 0,
                            onSelected: () =>
                                _controller.setBorrowStatusFilter(0),
                          ),
                          _StatusChip(
                            label: '已借出',
                            selected: _controller.borrowStatusFilter == 1,
                            onSelected: () =>
                                _controller.setBorrowStatusFilter(1),
                          ),
                          _StatusChip(
                            label: '已拒绝',
                            selected: _controller.borrowStatusFilter == 2,
                            onSelected: () =>
                                _controller.setBorrowStatusFilter(2),
                          ),
                          _StatusChip(
                            label: '已归还',
                            selected: _controller.borrowStatusFilter == 3,
                            onSelected: () =>
                                _controller.setBorrowStatusFilter(3),
                          ),
                          _StatusChip(
                            label: '待验收',
                            selected: _controller.borrowStatusFilter == 5,
                            onSelected: () =>
                                _controller.setBorrowStatusFilter(5),
                          ),
                          _StatusChip(
                            label: '已逾期',
                            selected: _controller.borrowStatusFilter == 6,
                            onSelected: () =>
                                _controller.setBorrowStatusFilter(6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_controller.borrowErrorMessage != null) ...<Widget>[
                  PanelCard(
                    child: Text(
                      _controller.borrowErrorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_controller.loadingBorrowRecords &&
                    _controller.borrowRecords.isEmpty)
                  const PanelCard(
                    child: SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (_controller.borrowRecords.isEmpty)
                  const PanelCard(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: '暂无借用记录',
                      message: '你的借用申请和处理结果会显示在这里。',
                    ),
                  )
                else
                  ..._controller.borrowRecords.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _BorrowRecordCard(
                        record: record,
                        title: _controller.equipmentName(record.equipmentId),
                        statusColor: _borrowStatusColor(record.status),
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
                PanelCard(
                  child: Row(
                    children: <Widget>[
                      OutlinedButton(
                        onPressed:
                            _controller.borrowPageNum > 1 &&
                                !_controller.loadingBorrowRecords
                            ? _controller.previousBorrowPage
                            : null,
                        child: const Text('上一页'),
                      ),
                      const Spacer(),
                      Text(
                        '${_controller.borrowPageNum} / ${_controller.borrowTotalPages} · 共 ${_controller.borrowTotal} 条',
                        style: const TextStyle(
                          color: Color(0xFF6D7B92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.tonal(
                        onPressed:
                            (_controller.borrowTotalPages == 0
                                    ? false
                                    : _controller.borrowPageNum <
                                          _controller.borrowTotalPages) &&
                                !_controller.loadingBorrowRecords
                            ? _controller.nextBorrowPage
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.availableCount,
    required this.activeBorrowCount,
    required this.overdueCount,
  });

  final UserProfile profile;
  final int availableCount;
  final int activeBorrowCount;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    final labText = profile.labId == null
        ? '当前未加入实验室'
        : '实验室 #${profile.labId}';

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
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -18,
            top: -16,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: -20,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final compact = constraints.maxWidth < 760;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '设备借用',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (compact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          labText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '仅空闲设备可发起借用，借用申请提交后由实验室管理员审核。',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.65,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                labText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '仅空闲设备可发起借用，借用申请提交后由实验室管理员审核。',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.65,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '借用概览',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '可借用 $availableCount 台',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '处理中 $activeBorrowCount 条',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _Pill(label: profile.roleLabel),
                      _Pill(label: profile.realName),
                      _Pill(label: profile.labId == null ? '未绑定实验室' : '可借用设备'),
                      _Pill(label: '待处理 $activeBorrowCount'),
                      _Pill(label: '逾期 $overdueCount'),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF12223A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF8792A6), height: 1.55),
        ),
      ],
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? const Color(0xFF2F76FF) : const Color(0xFF6D7B92);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFFBFD5FF) : const Color(0xFFE5ECF8),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12223A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6D7B92),
                      height: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.item,
    required this.statusColor,
    required this.onBorrow,
  });

  final EquipmentItem item;
  final Color statusColor;
  final VoidCallback? onBorrow;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x142F76FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.isIdle
                      ? Icons.check_circle_outline_rounded
                      : item.isBorrowed
                      ? Icons.event_busy_outlined
                      : Icons.build_circle_outlined,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _Tag(label: item.type ?? '未分类'),
                        _Tag(label: item.serialNumber ?? '无编号'),
                        _Tag(label: item.statusLabel, color: statusColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((item.description ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              item.description!,
              style: const TextStyle(height: 1.7, color: Color(0xFF6D7B92)),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Text(
                item.isIdle ? '当前可发起借用' : '暂不可借用',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: onBorrow,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(item.isIdle ? '发起借用' : item.statusLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BorrowRecordCard extends StatelessWidget {
  const _BorrowRecordCard({
    required this.record,
    required this.title,
    required this.statusColor,
  });

  final EquipmentBorrowRecord record;
  final String title;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            record.reason ?? '未填写借用理由',
            style: const TextStyle(height: 1.7, color: Color(0xFF6D7B92)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: '借用时间',
                value: DateTimeFormatter.dateTime(record.borrowTime),
              ),
              _InfoChip(
                icon: Icons.event_available_outlined,
                label: '预计归还',
                value: DateTimeFormatter.dateTime(record.expectedReturnTime),
              ),
              _InfoChip(
                icon: Icons.event_repeat_outlined,
                label: '归还时间',
                value: DateTimeFormatter.dateTime(record.returnTime),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color = const Color(0xFF6D7B92)});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6F5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFF2F76FF)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF8792A6)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF12223A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
