import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/utils/file_url_resolver.dart';
import '../../core/utils/url_launcher_helper.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/portal_shortcut_chip.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/attendance_record.dart';
import '../../models/lab_daily_attendance_member.dart';
import '../../models/lab_member_summary.dart';
import '../../models/space_file_item.dart';
import '../../models/space_folder_node.dart';
import '../../models/user_profile.dart';
import '../../repositories/lab_space_repository.dart';
import 'workspace_controller.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({
    super.key,
    required this.repository,
    required this.profile,
    required this.baseUrl,
  });

  final LabSpaceRepository repository;
  final UserProfile profile;
  final String baseUrl;

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  late final WorkspaceController _controller;
  final TextEditingController _fileKeywordController = TextEditingController();
  final TextEditingController _signReasonController = TextEditingController();
  int _sectionIndex = 0;
  final GlobalKey<FormState> _signFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = WorkspaceController(
      repository: widget.repository,
      profile: widget.profile,
    )..refreshAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fileKeywordController.dispose();
    _signReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.pickFiles(withData: true);
    final file = result != null && result.files.isNotEmpty
        ? result.files.first
        : null;
    if (file == null) {
      return;
    }

    final success = await _controller.uploadFile(file);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '文件已上传' : _controller.errorMessage ?? '文件上传失败'),
      ),
    );
  }

  Future<void> _submitSignIn() async {
    if (!_signFormKey.currentState!.validate()) {
      return;
    }

    _controller.setSignReason(_signReasonController.text);
    final success = await _controller.signIn();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '签到已提交' : _controller.errorMessage ?? '签到失败'),
      ),
    );
  }

  Future<void> _pickDailyAttendanceDate() async {
    final initialDate =
        DateTime.tryParse(_controller.dailyAttendanceDate) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year - 1),
      lastDate: DateTime(initialDate.year + 1),
    );
    if (pickedDate == null) {
      return;
    }
    _controller.setDailyAttendanceDate(pickedDate);
    await _controller.refreshDailyAttendance();
  }

  Future<void> _toggleArchive(SpaceFileItem file) async {
    final success = await _controller.toggleArchive(file);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (file.isArchived ? '已取消归档' : '文件已归档')
              : _controller.errorMessage ?? '操作失败',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final lab = _controller.overview?.lab;
        final hasLab = widget.profile.labId != null;
        final attendanceWorkbenchRoute = widget.profile.isTeacher
            ? '/teacher/attendance-workbench'
            : (widget.profile.isAdmin && widget.profile.labManager)
            ? '/admin/attendance-workbench'
            : null;
        final shortcuts = <PortalShortcutAction>[
          if (widget.profile.isStudent)
            PortalShortcutAction(
              icon: Icons.how_to_reg_rounded,
              label: '考勤流程',
              onPressed: () => context.push('/student/attendance'),
            ),
          if (widget.profile.isStudent)
            PortalShortcutAction(
              icon: Icons.inventory_2_outlined,
              label: '设备借用',
              onPressed: () => context.push('/student/equipment'),
            ),
          if (attendanceWorkbenchRoute != null)
            PortalShortcutAction(
              icon: Icons.fact_check_outlined,
              label: '考勤工作台',
              onPressed: () => context.push(attendanceWorkbenchRoute),
            ),
          if (_controller.canUploadFiles)
            PortalShortcutAction(
              icon: Icons.upload_file_outlined,
              label: '上传资料',
              onPressed: _pickAndUploadFile,
            ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.profile.isStudent ? '我的实验室' : '实验室空间'),
            actions: <Widget>[
              if (widget.profile.isStudent && hasLab)
                IconButton(
                  tooltip: '设备借用',
                  onPressed: () => context.push('/student/equipment'),
                  icon: const Icon(Icons.inventory_2_outlined),
                ),
              if (widget.profile.isStudent)
                IconButton(
                  tooltip: '考勤',
                  onPressed: () => context.push('/student/attendance'),
                  icon: const Icon(Icons.how_to_reg_rounded),
                ),
              if (attendanceWorkbenchRoute != null)
                IconButton(
                  tooltip: '考勤工作台',
                  onPressed: () => context.push(attendanceWorkbenchRoute),
                  icon: const Icon(Icons.fact_check_outlined),
                ),
              IconButton(
                tooltip: '刷新',
                onPressed: _controller.loading ? null : _controller.refreshAll,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: ResponsiveListView(
            onRefresh: _controller.refreshAll,
            children: <Widget>[
              _WorkspaceHeroCard(
                profile: widget.profile,
                labName: lab?.labName ?? '未加入实验室',
                labCode: lab?.labCode,
                statusLabel: lab?.statusLabel ?? '待加入',
                location: lab?.location,
                description: lab?.labDesc,
                onPrimaryAction: widget.profile.isStudent && hasLab
                    ? () => context.push('/student/exit-application')
                    : null,
              ),
              if (hasLab) ...<Widget>[
                const SizedBox(height: 16),
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '常用入口',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12223A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '常用服务',
                        style: TextStyle(color: Color(0xFF6D7B92)),
                      ),
                      const SizedBox(height: 14),
                      PortalShortcutGrid(actions: shortcuts),
                    ],
                  ),
                ),
              ],
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
                runSpacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('概览'),
                    showCheckmark: false,
                    selected: _sectionIndex == 0,
                    onSelected: (_) => setState(() => _sectionIndex = 0),
                  ),
                  ChoiceChip(
                    label: const Text('资料空间'),
                    showCheckmark: false,
                    selected: _sectionIndex == 1,
                    onSelected: (_) => setState(() => _sectionIndex = 1),
                  ),
                  ChoiceChip(
                    label: Text(widget.profile.isStudent ? '考勤概览' : '日考勤'),
                    showCheckmark: false,
                    selected: _sectionIndex == 2,
                    onSelected: (_) => setState(() => _sectionIndex = 2),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!hasLab)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.apartment_outlined,
                    title: '当前未加入实验室',
                    message: '加入实验室后，这里会展示成员、资料空间和考勤概览。',
                  ),
                )
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_sectionIndex) {
                    0 => _OverviewSection(
                      controller: _controller,
                      baseUrl: widget.baseUrl,
                    ),
                    1 => _FilesSection(
                      controller: _controller,
                      baseUrl: widget.baseUrl,
                      onPickAndUpload: _pickAndUploadFile,
                      keywordController: _fileKeywordController,
                      onToggleArchive: _toggleArchive,
                    ),
                    _ => _AttendanceSection(
                      controller: _controller,
                      profile: widget.profile,
                      signFormKey: _signFormKey,
                      signReasonController: _signReasonController,
                      onSubmitSignIn: _submitSignIn,
                      onPickDate: _pickDailyAttendanceDate,
                      onOpenWorkflow: widget.profile.isStudent
                          ? () => context.push('/student/attendance')
                          : null,
                    ),
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkspaceHeroCard extends StatelessWidget {
  const _WorkspaceHeroCard({
    required this.profile,
    required this.labName,
    required this.labCode,
    required this.statusLabel,
    required this.location,
    required this.description,
    this.onPrimaryAction,
  });

  final UserProfile profile;
  final String labName;
  final String? labCode;
  final String statusLabel;
  final String? location;
  final String? description;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 420;

        return Container(
          padding: EdgeInsets.all(compact ? 18 : 22),
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
                top: -18,
                child: Container(
                  width: compact ? 88 : 108,
                  height: compact ? 88 : 108,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(34),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      profile.isStudent ? '我的实验室' : '实验室空间',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    labName,
                    style: TextStyle(
                      fontSize: compact ? 24 : 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.realName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _HeroPill(label: labCode ?? '未配置编码'),
                      _HeroPill(label: statusLabel),
                      if ((location ?? '').isNotEmpty)
                        _HeroPill(label: location!),
                    ],
                  ),
                  if ((description ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      description!,
                      style: TextStyle(
                        height: 1.7,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  if (onPrimaryAction != null) ...<Widget>[
                    const SizedBox(height: 18),
                    FilledButton.tonalIcon(
                      onPressed: onPrimaryAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2F76FF),
                      ),
                      icon: const Icon(Icons.assignment_outlined),
                      label: const Text('退出申请'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
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

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.controller, required this.baseUrl});

  final WorkspaceController controller;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final lab = controller.overview?.lab;
    final summary = controller.attendanceSummary;
    final members = controller.activeMembers;
    final recentFiles = controller.recentFiles;

    return Column(
      children: <Widget>[
        _MetricGrid(
          cards: <_MetricCardData>[
            _MetricCardData(
              label: '成员数量',
              value: controller.overview?.memberCount.toString() ?? '0',
              hint: '当前实验室在组成员',
            ),
            _MetricCardData(
              label: '周出勤率',
              value: '${summary?.weeklyRate ?? 0}%',
              hint: '实验室考勤概览',
            ),
            _MetricCardData(
              label: '月出勤率',
              value: '${summary?.monthlyRate ?? 0}%',
              hint: '最近 30 天数据',
            ),
            _MetricCardData(
              label: '最近资料',
              value: recentFiles.length.toString(),
              hint: '最近更新的资料文件',
            ),
          ],
        ),
        const SizedBox(height: 16),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SectionHeader(
                title: '实验室信息',
                subtitle: '查看当前实验室的基础信息与联系资料。',
              ),
              const SizedBox(height: 14),
              _DetailRow(label: '实验室名称', value: lab?.labName ?? '-'),
              _DetailRow(label: '实验室编码', value: lab?.labCode ?? '-'),
              _DetailRow(label: '指导教师', value: lab?.teacherName ?? '-'),
              _DetailRow(label: '联系方式', value: lab?.contactEmail ?? '-'),
              _DetailRow(
                label: '创建时间',
                value: DateTimeFormatter.date(lab?.createTime),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SectionHeader(title: '成员列表', subtitle: '展示当前实验室的在组成员情况。'),
              const SizedBox(height: 14),
              if (controller.loading && members.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (members.isEmpty)
                const EmptyState(
                  icon: Icons.group_outlined,
                  title: '暂无成员数据',
                  message: '实验室当前没有可展示的活跃成员。',
                )
              else
                ...members.map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MemberTile(member: member),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SectionHeader(
                title: '最近文件',
                subtitle: '查看最近 5 条资料，点击可直接打开。',
              ),
              const SizedBox(height: 14),
              if (recentFiles.isEmpty)
                const EmptyState(
                  icon: Icons.folder_open_outlined,
                  title: '暂无最近文件',
                  message: '上传资料后，这里会展示最新内容。',
                )
              else
                ...recentFiles.map(
                  (file) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FileTile(
                      file: file,
                      baseUrl: baseUrl,
                      onOpen: () => openExternalLink(
                        context,
                        FileUrlResolver.resolve(
                          baseUrl: baseUrl,
                          rawUrl: file.fileUrl,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilesSection extends StatelessWidget {
  const _FilesSection({
    required this.controller,
    required this.baseUrl,
    required this.onPickAndUpload,
    required this.keywordController,
    required this.onToggleArchive,
  });

  final WorkspaceController controller;
  final String baseUrl;
  final Future<void> Function() onPickAndUpload;
  final TextEditingController keywordController;
  final Future<void> Function(SpaceFileItem file) onToggleArchive;

  @override
  Widget build(BuildContext context) {
    final recentFiles = controller.recentFiles;

    return Column(
      children: <Widget>[
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SectionHeader(
                title: '资料空间',
                subtitle: '按目录、归档状态和文件名筛选实验室资料。',
              ),
              const SizedBox(height: 14),
              if (recentFiles.isNotEmpty) ...<Widget>[
                const _SectionHeader(
                  title: '最近更新',
                  subtitle: '优先查看最近整理或上传的资料。',
                ),
                const SizedBox(height: 12),
                ...recentFiles
                    .take(3)
                    .map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FileTile(
                          file: file,
                          baseUrl: baseUrl,
                          onOpen: () => openExternalLink(
                            context,
                            FileUrlResolver.resolve(
                              baseUrl: baseUrl,
                              rawUrl: file.fileUrl,
                            ),
                          ),
                          onToggleArchive: controller.canArchiveFiles
                              ? () => onToggleArchive(file)
                              : null,
                          archiveBusy: controller.isUpdatingArchive(file.id),
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
              ],
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final isWide = constraints.maxWidth >= 920;
                  final folderPanel = _FolderPanel(controller: controller);
                  final filePanel = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: isWide ? 320 : constraints.maxWidth,
                            child: TextField(
                              controller: keywordController,
                              decoration: const InputDecoration(
                                labelText: '文件名关键字',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                              onChanged: controller.setFileKeyword,
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: DropdownButtonFormField<int?>(
                              initialValue: controller.fileArchiveFlag,
                              decoration: const InputDecoration(
                                labelText: '归档状态',
                              ),
                              items: const <DropdownMenuItem<int?>>[
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('全部'),
                                ),
                                DropdownMenuItem<int?>(
                                  value: 0,
                                  child: Text('未归档'),
                                ),
                                DropdownMenuItem<int?>(
                                  value: 1,
                                  child: Text('已归档'),
                                ),
                              ],
                              onChanged: controller.setFileArchiveFlag,
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: controller.loadingFiles
                                ? null
                                : controller.refreshFiles,
                            child: const Text('查询'),
                          ),
                          if (controller.canUploadFiles)
                            FilledButton.icon(
                              onPressed: controller.uploadingFile
                                  ? null
                                  : onPickAndUpload,
                              icon: controller.uploadingFile
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_rounded),
                              label: const Text('上传文件'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (controller.loadingFiles &&
                          controller.filesPage == null)
                        const Center(child: CircularProgressIndicator())
                      else if (controller.filesPage?.records.isEmpty ?? true)
                        const EmptyState(
                          icon: Icons.insert_drive_file_outlined,
                          title: '暂无文件',
                          message: '当前筛选条件下没有可展示的资料。',
                        )
                      else
                        ...controller.filesPage!.records.map(
                          (file) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FileTile(
                              file: file,
                              baseUrl: baseUrl,
                              onOpen: () => openExternalLink(
                                context,
                                FileUrlResolver.resolve(
                                  baseUrl: baseUrl,
                                  rawUrl: file.fileUrl,
                                ),
                              ),
                              onToggleArchive: controller.canArchiveFiles
                                  ? () => onToggleArchive(file)
                                  : null,
                              archiveBusy: controller.isUpdatingArchive(
                                file.id,
                              ),
                            ),
                          ),
                        ),
                      if ((controller.filesPage?.pages ?? 0) > 1) ...<Widget>[
                        const SizedBox(height: 8),
                        _PaginationBar(
                          currentPage: controller.filePageNum,
                          totalPages: controller.fileTotalPages,
                          total: controller.fileTotal,
                          onPrevious: controller.filePageNum > 1
                              ? () => controller.goToFilePage(
                                  controller.filePageNum - 1,
                                )
                              : null,
                          onNext:
                              controller.filePageNum < controller.fileTotalPages
                              ? () => controller.goToFilePage(
                                  controller.filePageNum + 1,
                                )
                              : null,
                        ),
                      ],
                    ],
                  );

                  if (!isWide) {
                    return Column(
                      children: <Widget>[
                        folderPanel,
                        const SizedBox(height: 16),
                        filePanel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 4, child: folderPanel),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: filePanel),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection({
    required this.controller,
    required this.profile,
    required this.signFormKey,
    required this.signReasonController,
    required this.onSubmitSignIn,
    required this.onPickDate,
    this.onOpenWorkflow,
  });

  final WorkspaceController controller;
  final UserProfile profile;
  final GlobalKey<FormState> signFormKey;
  final TextEditingController signReasonController;
  final Future<void> Function() onSubmitSignIn;
  final Future<void> Function() onPickDate;
  final VoidCallback? onOpenWorkflow;

  @override
  Widget build(BuildContext context) {
    final summary = controller.attendanceSummary;
    final records =
        controller.attendancePage?.records ?? const <AttendanceRecord>[];
    final dailyAttendance = controller.dailyAttendance;

    if (!profile.isStudent) {
      return Column(
        children: <Widget>[
          _MetricGrid(
            cards: <_MetricCardData>[
              _MetricCardData(
                label: '周出勤率',
                value: '${summary?.weeklyRate ?? 0}%',
                hint: '最近 7 天',
              ),
              _MetricCardData(
                label: '月出勤率',
                value: '${summary?.monthlyRate ?? 0}%',
                hint: '最近 30 天',
              ),
              _MetricCardData(
                label: '已到人数',
                value: '${summary?.presentCount ?? 0}',
                hint: '累计确认出勤',
              ),
              _MetricCardData(
                label: '异常人数',
                value: '${summary?.absentCount ?? 0}',
                hint: '缺勤与异常记录',
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
                      child: _SectionHeader(
                        title: '日考勤名单',
                        subtitle: '按日期查看成员考勤，管理员可直接确认状态。',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.loadingDailyAttendance
                          ? null
                          : onPickDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(controller.dailyAttendanceDate),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (controller.loadingDailyAttendance &&
                    dailyAttendance.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (dailyAttendance.isEmpty)
                  const EmptyState(
                    icon: Icons.event_note_outlined,
                    title: '暂无日考勤名单',
                    message: '当前日期下还没有可展示的成员考勤数据。',
                  )
                else
                  ...dailyAttendance.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DailyAttendanceTile(
                        item: item,
                        editable: controller.canConfirmDailyAttendance,
                        saving: controller.isSavingAttendance(item.userId),
                        onSave: (int status, String reason) async {
                          final success = await controller
                              .confirmDailyAttendance(
                                userId: item.userId,
                                status: status,
                                reason: reason,
                              );
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '考勤记录已保存'
                                    : controller.errorMessage ?? '保存失败',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        _MetricGrid(
          cards: <_MetricCardData>[
            _MetricCardData(
              label: '周出勤率',
              value: '${summary?.weeklyRate ?? 0}%',
              hint: '最近 7 天',
            ),
            _MetricCardData(
              label: '月出勤率',
              value: '${summary?.monthlyRate ?? 0}%',
              hint: '最近 30 天',
            ),
            _MetricCardData(
              label: '出勤',
              value: '${summary?.presentCount ?? 0}',
              hint: '已确认出勤',
            ),
            _MetricCardData(
              label: '缺勤',
              value: '${summary?.absentCount ?? 0}',
              hint: '异常记录',
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
                    child: _SectionHeader(
                      title: '今日签到',
                      subtitle: '完成签到后，记录会更新到个人考勤中。',
                    ),
                  ),
                  if (onOpenWorkflow != null)
                    OutlinedButton.icon(
                      onPressed: onOpenWorkflow,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('签到页'),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Form(
                key: signFormKey,
                child: Column(
                  children: <Widget>[
                    DropdownButtonFormField<int>(
                      initialValue: controller.signStatus,
                      decoration: const InputDecoration(labelText: '签到状态'),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem<int>(value: 1, child: Text('出勤')),
                        DropdownMenuItem<int>(value: 2, child: Text('迟到')),
                        DropdownMenuItem<int>(value: 5, child: Text('补签')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.setSignStatus(value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: signReasonController,
                      maxLines: 3,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        alignLabelWithHint: true,
                      ),
                      onChanged: controller.setSignReason,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty &&
                            controller.signStatus == 5) {
                          return '补签建议填写备注';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: controller.signingIn ? null : onSubmitSignIn,
                        child: controller.signingIn
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('提交签到'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SectionHeader(title: '考勤记录', subtitle: '集中查看近期签到与出勤情况。'),
              const SizedBox(height: 14),
              if (controller.loadingAttendance && records.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (records.isEmpty)
                const EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: '暂无考勤记录',
                  message: '签到后，最近记录会显示在这里。',
                )
              else
                ...records.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AttendanceTile(record: record),
                  ),
                ),
              if ((controller.attendancePage?.pages ?? 0) > 1) ...<Widget>[
                const SizedBox(height: 8),
                _PaginationBar(
                  currentPage: controller.attendancePageNum,
                  totalPages: controller.attendanceTotalPages,
                  total: controller.attendanceTotal,
                  onPrevious: controller.attendancePageNum > 1
                      ? () => controller.goToAttendancePage(
                          controller.attendancePageNum - 1,
                        )
                      : null,
                  onNext:
                      controller.attendancePageNum <
                          controller.attendanceTotalPages
                      ? () => controller.goToAttendancePage(
                          controller.attendancePageNum + 1,
                        )
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FolderPanel extends StatelessWidget {
  const _FolderPanel({required this.controller});

  final WorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final folders = controller.folders;

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(title: '目录树', subtitle: '选中目录后会刷新右侧文件列表。'),
          const SizedBox(height: 14),
          if (folders.isEmpty)
            const EmptyState(
              icon: Icons.folder_outlined,
              title: '暂无目录',
              message: '当前实验室暂未整理资料目录。',
            )
          else
            ...folders.map(
              (folder) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FolderNodeTile(node: folder, controller: controller),
              ),
            ),
        ],
      ),
    );
  }
}

class _FolderNodeTile extends StatelessWidget {
  const _FolderNodeTile({required this.node, required this.controller});

  final SpaceFolderNode node;
  final WorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedFolderId == node.id;

    if (node.children.isEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          controller.setSelectedFolder(node.id);
          controller.refreshFiles();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0x142D78FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2D78FF)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.folder_rounded,
                color: selected
                    ? const Color(0xFF2D78FF)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  node.folderName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF2D78FF)
                        : const Color(0xFF12223A),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 16, top: 8),
      leading: Icon(
        Icons.folder_rounded,
        color: selected ? const Color(0xFF2D78FF) : const Color(0xFF64748B),
      ),
      title: Text(
        node.folderName,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? const Color(0xFF2D78FF) : const Color(0xFF12223A),
        ),
      ),
      onExpansionChanged: (_) {
        controller.setSelectedFolder(node.id);
        controller.refreshFiles();
      },
      children: node.children
          .map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FolderNodeTile(node: child, controller: controller),
            ),
          )
          .toList(),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final LabMemberSummary member;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 380;
        final avatar = CircleAvatar(
          backgroundColor: const Color(0xFF2D78FF).withValues(alpha: 0.12),
          child: Text(
            member.realName.isEmpty ? 'U' : member.realName.substring(0, 1),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D78FF),
            ),
          ),
        );
        final roleBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x142D78FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            member.memberRoleLabel,
            style: const TextStyle(
              color: Color(0xFF2D78FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        final meta = [
          if ((member.studentId ?? '').isNotEmpty) member.studentId!,
          if ((member.major ?? '').isNotEmpty) member.major!,
        ].join(' · ');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        avatar,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                member.realName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF12223A),
                                ),
                              ),
                              if (meta.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  meta,
                                  style: const TextStyle(
                                    color: Color(0xFF6D7B92),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    roleBadge,
                  ],
                )
              : Row(
                  children: <Widget>[
                    avatar,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            member.realName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12223A),
                            ),
                          ),
                          if (meta.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              meta,
                              style: const TextStyle(color: Color(0xFF6D7B92)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    roleBadge,
                  ],
                ),
        );
      },
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.file,
    required this.baseUrl,
    required this.onOpen,
    this.onToggleArchive,
    this.archiveBusy = false,
  });

  final SpaceFileItem file;
  final String baseUrl;
  final VoidCallback onOpen;
  final VoidCallback? onToggleArchive;
  final bool archiveBusy;

  @override
  Widget build(BuildContext context) {
    final fileUrl = FileUrlResolver.resolve(
      baseUrl: baseUrl,
      rawUrl: file.fileUrl,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 430;
        final leadingIcon = Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: file.isArchived
                ? const Color(0xFF0F9D58).withValues(alpha: 0.12)
                : const Color(0xFF2D78FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            file.isArchived
                ? Icons.inventory_2_rounded
                : Icons.description_rounded,
            color: file.isArchived
                ? const Color(0xFF0F9D58)
                : const Color(0xFF2D78FF),
          ),
        );
        final fileMeta = [
          if ((file.folderName ?? '').isNotEmpty) file.folderName!,
          if ((file.uploadUserName ?? '').isNotEmpty) file.uploadUserName!,
        ].join(' · ');
        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: <Widget>[
            TextButton(
              onPressed: fileUrl.isEmpty ? null : onOpen,
              child: const Text('打开'),
            ),
            if (onToggleArchive != null)
              FilledButton.tonal(
                onPressed: archiveBusy ? null : onToggleArchive,
                child: archiveBusy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(file.isArchived ? '取消归档' : '归档'),
              ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        leadingIcon,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                file.fileName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF12223A),
                                ),
                              ),
                              if (fileMeta.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  fileMeta,
                                  style: const TextStyle(
                                    color: Color(0xFF6D7B92),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                DateTimeFormatter.dateTime(file.createTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    actions,
                  ],
                )
              : Row(
                  children: <Widget>[
                    leadingIcon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            file.fileName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12223A),
                            ),
                          ),
                          if (fileMeta.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              fileMeta,
                              style: const TextStyle(color: Color(0xFF6D7B92)),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            DateTimeFormatter.dateTime(file.createTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 132),
                      child: actions,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DailyAttendanceTile extends StatefulWidget {
  const _DailyAttendanceTile({
    required this.item,
    required this.editable,
    required this.saving,
    required this.onSave,
  });

  final LabDailyAttendanceMember item;
  final bool editable;
  final bool saving;
  final Future<void> Function(int status, String reason) onSave;

  @override
  State<_DailyAttendanceTile> createState() => _DailyAttendanceTileState();
}

class _DailyAttendanceTileState extends State<_DailyAttendanceTile> {
  late final TextEditingController _reasonController;
  late int _status;

  @override
  void initState() {
    super.initState();
    _status = widget.item.status == 0 ? 1 : widget.item.status;
    _reasonController = TextEditingController(text: widget.item.reason ?? '');
  }

  @override
  void didUpdateWidget(covariant _DailyAttendanceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.userId != widget.item.userId ||
        oldWidget.item.confirmTime != widget.item.confirmTime ||
        oldWidget.item.status != widget.item.status ||
        oldWidget.item.reason != widget.item.reason) {
      _status = widget.item.status == 0 ? 1 : widget.item.status;
      _reasonController.text = widget.item.reason ?? '';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (_status) {
      1 || 5 || 6 => const Color(0xFF0F9D58),
      2 || 3 => const Color(0xFFF59E0B),
      4 => const Color(0xFFE53935),
      _ => const Color(0xFF64748B),
    };
    final statusLabel = switch (_status) {
      1 => '出勤',
      2 => '迟到',
      3 => '请假',
      4 => '缺勤',
      5 => '补签',
      6 => '免考勤',
      _ => '未登记',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Text(
                  widget.item.realName.isEmpty
                      ? 'U'
                      : widget.item.realName.substring(0, 1),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.item.realName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ((widget.item.studentId ?? '').isNotEmpty)
                          widget.item.studentId!,
                        if ((widget.item.major ?? '').isNotEmpty)
                          widget.item.major!,
                      ].join(' · '),
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.editable)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: '状态'),
                    items: const <DropdownMenuItem<int>>[
                      DropdownMenuItem(value: 1, child: Text('出勤')),
                      DropdownMenuItem(value: 2, child: Text('迟到')),
                      DropdownMenuItem(value: 3, child: Text('请假')),
                      DropdownMenuItem(value: 4, child: Text('缺勤')),
                      DropdownMenuItem(value: 5, child: Text('补签')),
                      DropdownMenuItem(value: 6, child: Text('免考勤')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: widget.saving
                      ? null
                      : () => widget.onSave(
                          _status,
                          _reasonController.text.trim(),
                        ),
                  child: widget.saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.item.reason?.trim().isNotEmpty == true
                      ? widget.item.reason!
                      : '暂无备注',
                  style: const TextStyle(height: 1.6, color: Color(0xFF6D7B92)),
                ),
                const SizedBox(height: 6),
                Text(
                  '确认时间 ${DateTimeFormatter.dateTime(widget.item.confirmTime)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      1 => const Color(0xFF0F9D58),
      2 => const Color(0xFFF59E0B),
      3 => const Color(0xFF2D78FF),
      4 => const Color(0xFFE53935),
      5 => const Color(0xFF7C3AED),
      6 => const Color(0xFF64748B),
      _ => const Color(0xFF64748B),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.fact_check_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  record.attendanceDate ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.reason ?? '无备注',
                  style: const TextStyle(color: Color(0xFF6D7B92)),
                ),
                const SizedBox(height: 4),
                Text(
                  '确认时间 ${DateTimeFormatter.dateTime(record.confirmTime)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              record.statusLabel,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.cards});

  final List<_MetricCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final crossAxisCount = switch (constraints.maxWidth) {
          >= 880 => 4,
          >= 340 => 2,
          _ => 1,
        };
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.9,
          children: cards
              .map(
                (card) => _MetricCard(
                  label: card.label,
                  value: card.value,
                  hint: card.hint,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6D7B92),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF12223A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(height: 1.6, color: Color(0xFF6D7B92)),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6D7B92)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF12223A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        OutlinedButton(onPressed: onPrevious, child: const Text('上一页')),
        const Spacer(),
        Text(
          '$currentPage / $totalPages · 共 $total 条',
          style: const TextStyle(
            color: Color(0xFF6D7B92),
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        FilledButton.tonal(onPressed: onNext, child: const Text('下一页')),
      ],
    );
  }
}
