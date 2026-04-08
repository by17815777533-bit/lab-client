import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/user_profile.dart';
import '../lab_create_apply/lab_create_apply_models.dart';
import 'attendance_management_controller.dart';
import 'attendance_management_models.dart';

class AttendanceManagementPage extends ConsumerStatefulWidget {
  const AttendanceManagementPage({super.key});

  @override
  ConsumerState<AttendanceManagementPage> createState() =>
      _AttendanceManagementPageState();
}

class _AttendanceManagementPageState
    extends ConsumerState<AttendanceManagementPage> {
  late final AttendanceManagementController _controller;
  late final TextEditingController _keywordController;
  late final UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = ref.read(authControllerProvider).profile!;
    _controller = AttendanceManagementController(
      repository: ref.read(attendanceWorkflowRepositoryProvider),
      profile: _profile,
    )..load();
    _keywordController = TextEditingController(text: _controller.keyword);
  }

  @override
  void dispose() {
    _controller.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _showTaskEditor({AttendanceTaskItem? task}) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _TaskEditorSheet(
          profile: _profile,
          options: _controller.collegeOptions,
          initialTask: task,
          initialCollegeId:
              task?.collegeId ??
              (_profile.collegeManager && !_profile.schoolDirector
                  ? _profile.managedCollegeId
                  : _controller.collegeId),
          onSubmit:
              ({
                required int? collegeId,
                required String semesterName,
                required String taskName,
                required String description,
                required String startDate,
                required String endDate,
              }) async {
                final saved = await _controller.saveTask(
                  id: task?.id,
                  collegeId: collegeId,
                  semesterName: semesterName,
                  taskName: taskName,
                  description: description.trim().isEmpty ? null : description,
                  startDate: startDate,
                  endDate: endDate,
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
    ).showSnackBar(const SnackBar(content: Text('考勤任务已保存')));
  }

  Future<void> _showScheduleEditor(AttendanceTaskItem task) async {
    final schedules = await _controller.loadTaskSchedules(task.id);
    if (!mounted) {
      return;
    }

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _ScheduleEditorSheet(
          task: task,
          initialSchedules: schedules,
          onSubmit: (List<AttendanceScheduleItem> items) async {
            final saved = await _controller.saveTaskSchedules(task.id, items);
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
    ).showSnackBar(const SnackBar(content: Text('排班设置已更新')));
  }

  Future<void> _publishTask(AttendanceTaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('发布考勤任务'),
          content: Text('发布后，${task.taskName} 会进入正式使用状态，是否继续？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认发布'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await _controller.publishTask(task.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '考勤任务已发布' : _controller.errorMessage ?? '发布失败'),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png'],
      withData: kIsWeb,
    );
    final file = result != null && result.files.isNotEmpty
        ? result.files.first
        : null;
    if (file == null) {
      return;
    }

    final success = await _controller.uploadPhoto(file);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '现场照片已上传' : _controller.errorMessage ?? '上传失败'),
      ),
    );
  }

  Future<void> _assignDuty() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设为值班负责人'),
          content: const Text('当前账号会被设为本场考勤的值班负责人。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await _controller.assignCurrentUserDuty();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '值班负责人已设置' : _controller.errorMessage ?? '设置失败',
        ),
      ),
    );
  }

  Future<void> _reviewRecord(
    AttendanceLabCurrentSession session,
    AttendanceLabSessionRecord record,
  ) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _ReviewRecordSheet(
          record: record,
          onSubmit: ({required String signStatus, String? remark}) async {
            final saved = await _controller.reviewRecord(
              sessionId: session.id,
              userId: record.userId,
              signStatus: signStatus,
              remark: remark,
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
    ).showSnackBar(const SnackBar(content: Text('签到结果已更新')));
  }

  Future<void> _runSearch() async {
    _controller.setKeyword(_keywordController.text);
    await _controller.searchTasks();
  }

  Future<void> _resetSearch() async {
    _keywordController.clear();
    _controller.setKeyword('');
    if (_profile.schoolDirector) {
      _controller.setCollegeId(null);
    }
    await _controller.searchTasks();
  }

  String _workspaceLabel() {
    if (_profile.schoolDirector) {
      return '全校范围';
    }
    if (_profile.collegeManager) {
      return _profile.college ?? '当前学院';
    }
    if (_profile.labManager) {
      return '当前实验室';
    }
    if (_profile.isTeacher) {
      return '任教实验室';
    }
    return '当前账号';
  }

  @override
  Widget build(BuildContext context) {
    final canUsePage =
        _controller.canManageTasks ||
        _controller.canViewSummary ||
        _controller.canViewCurrentSession;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final summary = _controller.summary;
        final session = _controller.currentSession;
        final showTaskTools = _controller.canManageTasks;
        final showSummary = _controller.canViewSummary && summary != null;
        final showCurrentSession = _controller.canViewCurrentSession;

        return Scaffold(
          appBar: AppBar(
            title: const Text('考勤工作台'),
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
              _HeroBanner(
                profile: _profile,
                scopeLabel: _workspaceLabel(),
                taskCount: summary?.taskCount ?? _controller.total,
                sessionStatus: session?.statusLabel,
                canManageTasks: _controller.canManageTasks,
                canReviewRecords: _controller.canReviewRecords,
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
              if (!canUsePage)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: '当前账号暂不可使用',
                    message: '只有教师、实验室管理员、学院管理员和学校管理员可以进入考勤工作台。',
                  ),
                )
              else ...<Widget>[
                if (showSummary) ...<Widget>[
                  const _SectionCaption(
                    title: '工作概览',
                    subtitle: '今日任务、现场到勤和补签情况一目了然。',
                  ),
                  const SizedBox(height: 10),
                  _SummaryGrid(summary: summary),
                  const SizedBox(height: 16),
                ],
                if (showCurrentSession) ...<Widget>[
                  const _SectionCaption(
                    title: '今日会话',
                    subtitle: '查看签到码、现场状态和成员签到结果。',
                  ),
                  const SizedBox(height: 10),
                  _CurrentSessionCard(
                    loading: _controller.loadingSession,
                    session: session,
                    hint: _controller.sessionHint,
                    canUploadPhoto: _controller.canUploadPhoto,
                    canAssignDuty: _controller.canAssignDuty,
                    uploadingPhoto: _controller.uploadingPhoto,
                    assigningDuty: _controller.assigningDuty,
                    onUploadPhoto: _pickAndUploadPhoto,
                    onAssignDuty: _assignDuty,
                  ),
                  const SizedBox(height: 16),
                  _SessionRecordsCard(
                    loading: _controller.loadingSession,
                    session: session,
                    hint: _controller.sessionHint,
                    canReview: _controller.canReviewRecords,
                    reviewing: _controller.reviewingRecord,
                    onReview: session == null
                        ? null
                        : (AttendanceLabSessionRecord record) =>
                              _reviewRecord(session, record),
                  ),
                  const SizedBox(height: 16),
                ],
                if (showTaskTools) ...<Widget>[
                  const _SectionCaption(
                    title: '任务安排',
                    subtitle: '按学院或学期管理考勤任务，并配置每周排班。',
                  ),
                  const SizedBox(height: 10),
                  _TaskFilterCard(
                    profile: _profile,
                    collegeId: _controller.collegeId,
                    collegeOptions: _controller.collegeOptions,
                    keywordController: _keywordController,
                    loading: _controller.loadingTasks,
                    onCollegeChanged: _controller.setCollegeId,
                    onSearch: _runSearch,
                    onReset: _resetSearch,
                    onCreate: _showTaskEditor,
                  ),
                  const SizedBox(height: 16),
                  _TaskListCard(
                    loading: _controller.loadingTasks,
                    savingSchedules: _controller.savingSchedules,
                    publishingTask: _controller.publishingTask,
                    tasks: _controller.tasks,
                    pageNum: _controller.pageNum,
                    totalPages: _controller.totalPages,
                    total: _controller.total,
                    onEditTask: _showTaskEditor,
                    onEditSchedules: _showScheduleEditor,
                    onPublish: _publishTask,
                    onPrevious: _controller.pageNum > 1
                        ? _controller.previousPage
                        : null,
                    onNext: _controller.pageNum < _controller.totalPages
                        ? _controller.nextPage
                        : null,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.profile,
    required this.scopeLabel,
    required this.taskCount,
    required this.sessionStatus,
    required this.canManageTasks,
    required this.canReviewRecords,
  });

  final UserProfile profile;
  final String scopeLabel;
  final int taskCount;
  final String? sessionStatus;
  final bool canManageTasks;
  final bool canReviewRecords;

  @override
  Widget build(BuildContext context) {
    final title = canManageTasks ? '考勤安排总览' : '实验室签到现场';
    final subtitle = canManageTasks
        ? '统一管理考勤任务、每周排班与签到秩序。'
        : canReviewRecords
        ? '实时跟进现场签到状态，必要时可及时调整结果。'
        : '查看今日签到情况，及时关注实验室成员出勤。';

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
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
            title,
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
            subtitle,
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
              _HeroPill(label: '任务 $taskCount'),
              _HeroPill(label: sessionStatus ?? '等待今日会话'),
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

class _SectionCaption extends StatelessWidget {
  const _SectionCaption({required this.title, required this.subtitle});

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
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF12223A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6D7B92), height: 1.5),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final AttendanceWorkflowSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryMetricData>[
      _SummaryMetricData(
        label: '考勤任务',
        value: '${summary.taskCount}',
        hint: '当前已创建',
      ),
      _SummaryMetricData(
        label: '今日场次',
        value: '${summary.todaySessionCount}',
        hint: '今日已生成',
      ),
      _SummaryMetricData(
        label: '出勤率',
        value: '${summary.attendanceRate.toStringAsFixed(1)}%',
        hint: '总体表现',
      ),
      _SummaryMetricData(
        label: '现场照片',
        value: '${summary.photoCount}',
        hint: '已上传',
      ),
      _SummaryMetricData(
        label: '待补签审核',
        value: '${summary.makeupPendingCount}',
        hint: '需要跟进',
      ),
      _SummaryMetricData(
        label: '异常人数',
        value: '${summary.anomalyCount}',
        hint: '迟到 / 缺勤 / 请假',
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = constraints.maxWidth >= 860
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 2;
        final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (item) => SizedBox(
                  width: cardWidth,
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
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.hint,
                          style: const TextStyle(
                            color: Color(0xFF9AA4B2),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _SummaryMetricData {
  const _SummaryMetricData({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;
}

class _TaskFilterCard extends StatelessWidget {
  const _TaskFilterCard({
    required this.profile,
    required this.collegeId,
    required this.collegeOptions,
    required this.keywordController,
    required this.loading,
    required this.onCollegeChanged,
    required this.onSearch,
    required this.onReset,
    required this.onCreate,
  });

  final UserProfile profile;
  final int? collegeId;
  final List<LabCreateApplyCollegeOption> collegeOptions;
  final TextEditingController keywordController;
  final bool loading;
  final ValueChanged<int?> onCollegeChanged;
  final Future<void> Function() onSearch;
  final Future<void> Function() onReset;
  final Future<void> Function({AttendanceTaskItem? task}) onCreate;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
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
          if (profile.schoolDirector) ...<Widget>[
            DropdownButtonFormField<int?>(
              key: ValueKey<int?>(collegeId),
              initialValue: collegeId,
              decoration: const InputDecoration(
                labelText: '学院范围',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              items: <DropdownMenuItem<int?>>[
                const DropdownMenuItem<int?>(value: null, child: Text('全部学院')),
                ...collegeOptions.map(
                  (item) => DropdownMenuItem<int?>(
                    value: item.id,
                    child: Text(item.collegeName),
                  ),
                ),
              ],
              onChanged: onCollegeChanged,
            ),
            const SizedBox(height: 12),
          ] else if (profile.collegeManager) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE5F3)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.account_balance_outlined,
                    color: Color(0xFF2F76FF),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profile.college ?? '当前学院',
                      style: const TextStyle(
                        color: Color(0xFF12223A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Text(
                    '已锁定',
                    style: TextStyle(
                      color: Color(0xFF8792A6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: keywordController,
            decoration: const InputDecoration(
              labelText: '关键词',
              hintText: '输入学期名称或任务名称',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onSubmitted: (_) => onSearch(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: loading ? null : onSearch,
                icon: const Icon(Icons.search_rounded),
                label: const Text('查询'),
              ),
              OutlinedButton.icon(
                onPressed: loading ? null : onReset,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('重置'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => onCreate(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('新建任务'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskListCard extends StatelessWidget {
  const _TaskListCard({
    required this.loading,
    required this.savingSchedules,
    required this.publishingTask,
    required this.tasks,
    required this.pageNum,
    required this.totalPages,
    required this.total,
    required this.onEditTask,
    required this.onEditSchedules,
    required this.onPublish,
    required this.onPrevious,
    required this.onNext,
  });

  final bool loading;
  final bool savingSchedules;
  final bool publishingTask;
  final List<AttendanceTaskItem> tasks;
  final int pageNum;
  final int totalPages;
  final int total;
  final Future<void> Function({AttendanceTaskItem? task}) onEditTask;
  final Future<void> Function(AttendanceTaskItem task) onEditSchedules;
  final Future<void> Function(AttendanceTaskItem task) onPublish;
  final Future<void> Function()? onPrevious;
  final Future<void> Function()? onNext;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  '任务列表',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
                ),
              ),
              Text(
                '共 $total 条',
                style: const TextStyle(
                  color: Color(0xFF6D7B92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading && tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (tasks.isEmpty)
            const EmptyState(
              icon: Icons.event_note_outlined,
              title: '暂无考勤任务',
              message: '先创建任务，再为每周签到安排排班。',
            )
          else
            Column(
              children: tasks
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TaskCard(
                        task: task,
                        savingSchedules: savingSchedules,
                        publishingTask: publishingTask,
                        onEditTask: () {
                          onEditTask(task: task);
                        },
                        onEditSchedules: () {
                          onEditSchedules(task);
                        },
                        onPublish: task.isPublished
                            ? null
                            : () {
                                onPublish(task);
                              },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          if (totalPages > 1) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                OutlinedButton(onPressed: onPrevious, child: const Text('上一页')),
                const Spacer(),
                Text(
                  '$pageNum / $totalPages',
                  style: const TextStyle(
                    color: Color(0xFF6D7B92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(onPressed: onNext, child: const Text('下一页')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.savingSchedules,
    required this.publishingTask,
    this.onEditTask,
    this.onEditSchedules,
    this.onPublish,
  });

  final AttendanceTaskItem task;
  final bool savingSchedules;
  final bool publishingTask;
  final VoidCallback? onEditTask;
  final VoidCallback? onEditSchedules;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final statusColor = task.isPublished
        ? const Color(0xFF059669)
        : const Color(0xFF2563EB);

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
                      task.taskName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${task.semesterName} · ${task.collegeName ?? '当前范围'}',
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  task.statusLabel,
                  style: TextStyle(
                    color: statusColor,
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
              _InfoChip(
                icon: Icons.date_range_outlined,
                label: '${task.startDate ?? '-'} 至 ${task.endDate ?? '-'}',
              ),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: '已配 ${task.scheduleCount} 条排班',
              ),
              _InfoChip(
                icon: Icons.history_rounded,
                label: task.publishedTime == null
                    ? '创建于 ${DateTimeFormatter.date(task.createTime)}'
                    : '发布于 ${DateTimeFormatter.date(task.publishedTime)}',
              ),
            ],
          ),
          if ((task.description ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              task.description!,
              style: const TextStyle(color: Color(0xFF4A5567), height: 1.6),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onEditTask,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑'),
              ),
              FilledButton.tonalIcon(
                onPressed: savingSchedules ? null : onEditSchedules,
                icon: const Icon(Icons.calendar_view_week_rounded),
                label: const Text('排班'),
              ),
              if (onPublish != null)
                FilledButton.icon(
                  onPressed: publishingTask ? null : onPublish,
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('发布'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF2F76FF)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4A5567),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentSessionCard extends StatelessWidget {
  const _CurrentSessionCard({
    required this.loading,
    required this.session,
    required this.hint,
    required this.canUploadPhoto,
    required this.canAssignDuty,
    required this.uploadingPhoto,
    required this.assigningDuty,
    this.onUploadPhoto,
    this.onAssignDuty,
  });

  final bool loading;
  final AttendanceLabCurrentSession? session;
  final String? hint;
  final bool canUploadPhoto;
  final bool canAssignDuty;
  final bool uploadingPhoto;
  final bool assigningDuty;
  final Future<void> Function()? onUploadPhoto;
  final Future<void> Function()? onAssignDuty;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: loading && session == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          : session == null
          ? EmptyState(
              icon: Icons.event_busy_outlined,
              title: '当前暂无会话',
              message: hint ?? '今日还没有可跟进的考勤会话。',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        '今日签到码',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12223A),
                        ),
                      ),
                    ),
                    _StatusBadge(
                      label: session!.statusLabel,
                      color: _sessionStatusColor(session!.status),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        _formatSessionCode(session!.sessionCode),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: Color(0xFF2F76FF),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${DateTimeFormatter.date(session!.sessionDate)} · ${_timeRange(session!)}',
                        style: const TextStyle(
                          color: Color(0xFF6D7B92),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _SessionMetricCard(
                      label: '应到',
                      value: '${session!.totalCount}',
                    ),
                    _SessionMetricCard(
                      label: '出勤',
                      value: '${session!.normalCount}',
                    ),
                    _SessionMetricCard(
                      label: '迟到',
                      value: '${session!.lateCount}',
                    ),
                    _SessionMetricCard(
                      label: '缺勤',
                      value: '${session!.absentCount}',
                    ),
                    _SessionMetricCard(
                      label: '补签待审',
                      value: '${session!.makeupPendingCount}',
                    ),
                    _SessionMetricCard(
                      label: '照片',
                      value: '${session!.photoCount}',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  children: <Widget>[
                    _DetailLine(label: '签到时段', value: _timeRange(session!)),
                    _DetailLine(
                      label: '迟到截止',
                      value: DateTimeFormatter.dateTime(session!.lateTime),
                    ),
                    _DetailLine(
                      label: '口令有效期',
                      value: DateTimeFormatter.dateTime(
                        session!.codeExpireTime,
                      ),
                    ),
                    _DetailLine(
                      label: '现场记录',
                      value: '${session!.records.length} 人已登记',
                    ),
                    if ((session!.dutyRemark ?? '').isNotEmpty)
                      _DetailLine(label: '值班说明', value: session!.dutyRemark!),
                  ],
                ),
                if (canUploadPhoto || canAssignDuty) ...<Widget>[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      if (canUploadPhoto)
                        FilledButton.tonalIcon(
                          onPressed: uploadingPhoto ? null : onUploadPhoto,
                          icon: uploadingPhoto
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.photo_camera_back_outlined),
                          label: const Text('上传现场照片'),
                        ),
                      if (canAssignDuty)
                        OutlinedButton.icon(
                          onPressed: assigningDuty ? null : onAssignDuty,
                          icon: const Icon(Icons.assignment_ind_outlined),
                          label: const Text('设为值班负责人'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  static String _formatSessionCode(String? value) {
    final source = (value ?? '').trim();
    if (source.isEmpty) {
      return '----';
    }
    return source.split('').join(' ');
  }

  static String _timeRange(AttendanceLabCurrentSession session) {
    final start = session.signStartTime;
    final end = session.signEndTime;
    if (start == null || end == null) {
      return '-';
    }
    final startText = DateTimeFormatter.dateTime(start).split(' ').last;
    final endText = DateTimeFormatter.dateTime(end).split(' ').last;
    return '$startText - $endText';
  }

  static Color _sessionStatusColor(String? value) {
    switch (value) {
      case 'active':
        return const Color(0xFF2563EB);
      case 'closed':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}

class _SessionMetricCard extends StatelessWidget {
  const _SessionMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(color: Color(0xFF8792A6), fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF12223A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF8792A6)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF12223A),
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionRecordsCard extends StatelessWidget {
  const _SessionRecordsCard({
    required this.loading,
    required this.session,
    required this.hint,
    required this.canReview,
    required this.reviewing,
    this.onReview,
  });

  final bool loading;
  final AttendanceLabCurrentSession? session;
  final String? hint;
  final bool canReview;
  final bool reviewing;
  final Future<void> Function(AttendanceLabSessionRecord record)? onReview;

  @override
  Widget build(BuildContext context) {
    final records = session?.records ?? const <AttendanceLabSessionRecord>[];

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  '成员签到',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
                ),
              ),
              Text(
                '${records.length} 人',
                style: const TextStyle(
                  color: Color(0xFF6D7B92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading && session == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (session == null)
            EmptyState(
              icon: Icons.people_outline_rounded,
              title: '暂无签到名单',
              message: hint ?? '今日还没有可查看的签到成员记录。',
            )
          else if (records.isEmpty)
            const EmptyState(
              icon: Icons.fact_check_outlined,
              title: '还没有人签到',
              message: '现场签到开始后，成员记录会陆续出现在这里。',
            )
          else
            Column(
              children: records
                  .map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecordCard(
                        record: record,
                        reviewing: reviewing,
                        canReview: canReview,
                        onReview: onReview == null
                            ? null
                            : () {
                                onReview!(record);
                              },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.reviewing,
    required this.canReview,
    this.onReview,
  });

  final AttendanceLabSessionRecord record;
  final bool reviewing;
  final bool canReview;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final statusColor = _signStatusColor(record.signStatus);

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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  record.realName.isEmpty
                      ? 'U'
                      : record.realName.substring(0, 1),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            record.realName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12223A),
                            ),
                          ),
                        ),
                        _StatusBadge(
                          label: record.statusLabel,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.studentId ?? '-'} · ${record.major ?? '-'} · ${record.memberRole ?? '成员'}',
                      style: const TextStyle(
                        color: Color(0xFF6D7B92),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: <Widget>[
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: DateTimeFormatter.dateTime(record.signTime),
              ),
              _InfoChip(
                icon: Icons.radar_outlined,
                label: record.source ?? '现场签到',
              ),
            ],
          ),
          if ((record.remark ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              record.remark!,
              style: const TextStyle(color: Color(0xFF4A5567), height: 1.55),
            ),
          ],
          if (canReview) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: reviewing ? null : onReview,
                icon: const Icon(Icons.rule_rounded),
                label: const Text('调整结果'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _signStatusColor(String? value) {
    switch (value) {
      case 'normal':
      case 'makeup_approved':
        return const Color(0xFF059669);
      case 'late':
        return const Color(0xFFF59E0B);
      case 'leave':
        return const Color(0xFF6366F1);
      case 'absent':
      case 'makeup_rejected':
        return const Color(0xFFE53935);
      case 'makeup_pending':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF94A3B8);
    }
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

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({
    required this.profile,
    required this.options,
    required this.initialTask,
    required this.initialCollegeId,
    required this.onSubmit,
  });

  final UserProfile profile;
  final List<LabCreateApplyCollegeOption> options;
  final AttendanceTaskItem? initialTask;
  final int? initialCollegeId;
  final Future<String?> Function({
    required int? collegeId,
    required String semesterName,
    required String taskName,
    required String description,
    required String startDate,
    required String endDate,
  })
  onSubmit;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _semesterController;
  late final TextEditingController _taskNameController;
  late final TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _endDate;
  int? _collegeId;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _semesterController = TextEditingController(
      text: widget.initialTask?.semesterName ?? '',
    );
    _taskNameController = TextEditingController(
      text: widget.initialTask?.taskName ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialTask?.description ?? '',
    );
    _startDate =
        DateTime.tryParse(widget.initialTask?.startDate ?? '') ??
        DateTime.now();
    _endDate =
        DateTime.tryParse(widget.initialTask?.endDate ?? '') ??
        _startDate.add(const Duration(days: 120));
    _collegeId = widget.initialCollegeId;
  }

  @override
  void dispose() {
    _semesterController.dispose();
    _taskNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      setState(() {
        _errorText = '结束日期不能早于开始日期';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final error = await widget.onSubmit(
      collegeId: widget.profile.schoolDirector
          ? _collegeId
          : widget.profile.managedCollegeId,
      semesterName: _semesterController.text.trim(),
      taskName: _taskNameController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: DateTimeFormatter.date(_startDate),
      endDate: DateTimeFormatter.date(_endDate),
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
                widget.initialTask == null ? '新建考勤任务' : '编辑考勤任务',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '按照学期和日期范围创建任务，后续可继续补充每周排班。',
                style: TextStyle(color: Color(0xFF6D7B92), height: 1.5),
              ),
              const SizedBox(height: 18),
              if (widget.profile.schoolDirector) ...<Widget>[
                DropdownButtonFormField<int?>(
                  key: ValueKey<int?>(_collegeId),
                  initialValue: _collegeId,
                  decoration: const InputDecoration(labelText: '学院'),
                  items: widget.options
                      .map(
                        (item) => DropdownMenuItem<int?>(
                          value: item.id,
                          child: Text(item.collegeName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _collegeId = value),
                  validator: (value) {
                    if (value == null) {
                      return '请选择学院';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ] else if (widget.profile.collegeManager) ...<Widget>[
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
                    widget.profile.college ?? '当前学院',
                    style: const TextStyle(
                      color: Color(0xFF12223A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _semesterController,
                decoration: const InputDecoration(labelText: '学期'),
                validator: (String? value) {
                  if ((value ?? '').trim().isEmpty) {
                    return '请输入学期名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _taskNameController,
                decoration: const InputDecoration(labelText: '任务名称'),
                validator: (String? value) {
                  if ((value ?? '').trim().isEmpty) {
                    return '请输入任务名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 4,
                maxLength: 180,
                decoration: const InputDecoration(
                  labelText: '任务说明',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(start: true),
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(DateTimeFormatter.date(_startDate)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(start: false),
                      icon: const Icon(Icons.event_outlined),
                      label: Text(DateTimeFormatter.date(_endDate)),
                    ),
                  ),
                ],
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
                      : const Text('保存任务'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleEditorSheet extends StatefulWidget {
  const _ScheduleEditorSheet({
    required this.task,
    required this.initialSchedules,
    required this.onSubmit,
  });

  final AttendanceTaskItem task;
  final List<AttendanceScheduleItem> initialSchedules;
  final Future<String?> Function(List<AttendanceScheduleItem> schedules)
  onSubmit;

  @override
  State<_ScheduleEditorSheet> createState() => _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends State<_ScheduleEditorSheet> {
  late final List<_EditableSchedule> _drafts;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _drafts = widget.initialSchedules.isEmpty
        ? <_EditableSchedule>[_EditableSchedule.fallback()]
        : widget.initialSchedules
              .map((item) => _EditableSchedule.fromItem(item))
              .toList();
  }

  Future<void> _pickTime({required int index, required bool start}) async {
    final current = _drafts[index];
    final currentText = start ? current.signInStart : current.signInEnd;
    final parts = currentText.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 19,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected == null) {
      return;
    }

    final text =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}:00';
    setState(() {
      if (start) {
        _drafts[index] = _drafts[index].copyWith(signInStart: text);
      } else {
        _drafts[index] = _drafts[index].copyWith(signInEnd: text);
      }
    });
  }

  Future<void> _submit() async {
    if (_drafts.isEmpty) {
      setState(() {
        _errorText = '请至少保留一条排班';
      });
      return;
    }
    final weekDays = _drafts.map((item) => item.weekDay).toList();
    if (weekDays.toSet().length != weekDays.length) {
      setState(() {
        _errorText = '同一天只需保留一条排班';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final error = await widget.onSubmit(
      _drafts.map((item) => item.toItem()).toList(growable: false),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '${widget.task.taskName} · 排班',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12223A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '为每周签到设置时段、迟到阈值和口令时效。',
              style: TextStyle(color: Color(0xFF6D7B92), height: 1.5),
            ),
            const SizedBox(height: 18),
            ..._drafts.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ScheduleDraftCard(
                  index: index,
                  item: item,
                  onWeekDayChanged: (int value) => setState(() {
                    _drafts[index] = item.copyWith(weekDay: value);
                  }),
                  onPickStart: () => _pickTime(index: index, start: true),
                  onPickEnd: () => _pickTime(index: index, start: false),
                  onLateChanged: (String value) => setState(() {
                    _drafts[index] = item.copyWith(
                      lateThresholdMinutes: int.tryParse(value) ?? 15,
                    );
                  }),
                  onCodeLengthChanged: (String value) => setState(() {
                    _drafts[index] = item.copyWith(
                      signCodeLength: int.tryParse(value) ?? 4,
                    );
                  }),
                  onCodeTtlChanged: (String value) => setState(() {
                    _drafts[index] = item.copyWith(
                      codeTtlMinutes: int.tryParse(value) ?? 90,
                    );
                  }),
                  onRemarkChanged: (String value) => setState(() {
                    _drafts[index] = item.copyWith(remark: value);
                  }),
                  onRemove: _drafts.length <= 1
                      ? null
                      : () => setState(() => _drafts.removeAt(index)),
                ),
              );
            }),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _drafts.add(_EditableSchedule.fallback())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('新增排班'),
                ),
              ],
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
                    : const Text('保存排班'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleDraftCard extends StatelessWidget {
  const _ScheduleDraftCard({
    required this.index,
    required this.item,
    required this.onWeekDayChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onLateChanged,
    required this.onCodeLengthChanged,
    required this.onCodeTtlChanged,
    required this.onRemarkChanged,
    this.onRemove,
  });

  final int index;
  final _EditableSchedule item;
  final ValueChanged<int> onWeekDayChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onLateChanged;
  final ValueChanged<String> onCodeLengthChanged;
  final ValueChanged<String> onCodeTtlChanged;
  final ValueChanged<String> onRemarkChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
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
            children: <Widget>[
              Text(
                '排班 ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  tooltip: '删除',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            key: ValueKey<String>(
              'week-$index-${item.id ?? 'new'}-${item.weekDay}',
            ),
            initialValue: item.weekDay,
            decoration: const InputDecoration(labelText: '签到日'),
            items: const <DropdownMenuItem<int>>[
              DropdownMenuItem<int>(value: 1, child: Text('周一')),
              DropdownMenuItem<int>(value: 2, child: Text('周二')),
              DropdownMenuItem<int>(value: 3, child: Text('周三')),
              DropdownMenuItem<int>(value: 4, child: Text('周四')),
              DropdownMenuItem<int>(value: 5, child: Text('周五')),
              DropdownMenuItem<int>(value: 6, child: Text('周六')),
              DropdownMenuItem<int>(value: 7, child: Text('周日')),
            ],
            onChanged: (int? value) {
              if (value != null) {
                onWeekDayChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickStart,
                  icon: const Icon(Icons.login_rounded),
                  label: Text(_compactTime(item.signInStart)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickEnd,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(_compactTime(item.signInEnd)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>('late-$index-${item.id ?? 'new'}'),
                  initialValue: '${item.lateThresholdMinutes}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '迟到阈值'),
                  onChanged: onLateChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>('len-$index-${item.id ?? 'new'}'),
                  initialValue: '${item.signCodeLength}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '口令长度'),
                  onChanged: onCodeLengthChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>('ttl-$index-${item.id ?? 'new'}'),
                  initialValue: '${item.codeTtlMinutes}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '有效分钟'),
                  onChanged: onCodeTtlChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>('remark-$index-${item.id ?? 'new'}'),
            initialValue: item.remark ?? '',
            decoration: const InputDecoration(labelText: '说明'),
            onChanged: onRemarkChanged,
          ),
        ],
      ),
    );
  }

  static String _compactTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) {
      return value;
    }
    return '${parts[0]}:${parts[1]}';
  }
}

class _ReviewRecordSheet extends StatefulWidget {
  const _ReviewRecordSheet({required this.record, required this.onSubmit});

  final AttendanceLabSessionRecord record;
  final Future<String?> Function({required String signStatus, String? remark})
  onSubmit;

  @override
  State<_ReviewRecordSheet> createState() => _ReviewRecordSheetState();
}

class _ReviewRecordSheetState extends State<_ReviewRecordSheet> {
  late final TextEditingController _remarkController;
  late String _selectedStatus;
  bool _saving = false;
  String? _errorText;

  static const List<_ReviewOption> _options = <_ReviewOption>[
    _ReviewOption(code: 'normal', label: '出勤'),
    _ReviewOption(code: 'late', label: '迟到'),
    _ReviewOption(code: 'leave', label: '请假'),
    _ReviewOption(code: 'absent', label: '缺勤'),
    _ReviewOption(code: 'makeup_approved', label: '补签通过'),
    _ReviewOption(code: 'makeup_rejected', label: '补签驳回'),
  ];

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController(text: widget.record.remark ?? '');
    _selectedStatus =
        _options.any((item) => item.code == widget.record.signStatus)
        ? widget.record.signStatus!
        : 'normal';
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });

    final error = await widget.onSubmit(
      signStatus: _selectedStatus,
      remark: _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              widget.record.realName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12223A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.record.studentId ?? '-'} · ${widget.record.major ?? '-'}',
              style: const TextStyle(color: Color(0xFF6D7B92)),
            ),
            const SizedBox(height: 18),
            const Text(
              '签到结果',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12223A),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options
                  .map(
                    (item) => ChoiceChip(
                      label: Text(item.label),
                      selected: _selectedStatus == item.code,
                      onSelected: (_) =>
                          setState(() => _selectedStatus = item.code),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _remarkController,
              minLines: 3,
              maxLines: 4,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: '备注',
                alignLabelWithHint: true,
              ),
            ),
            if ((_errorText ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
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
                    : const Text('保存结果'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableSchedule {
  const _EditableSchedule({
    required this.id,
    required this.taskId,
    required this.weekDay,
    required this.signInStart,
    required this.signInEnd,
    required this.lateThresholdMinutes,
    required this.signCodeLength,
    required this.codeTtlMinutes,
    required this.remark,
  });

  final int? id;
  final int? taskId;
  final int weekDay;
  final String signInStart;
  final String signInEnd;
  final int lateThresholdMinutes;
  final int signCodeLength;
  final int codeTtlMinutes;
  final String? remark;

  factory _EditableSchedule.fromItem(AttendanceScheduleItem item) {
    return _EditableSchedule(
      id: item.id,
      taskId: item.taskId,
      weekDay: item.weekDay,
      signInStart: item.signInStart,
      signInEnd: item.signInEnd,
      lateThresholdMinutes: item.lateThresholdMinutes,
      signCodeLength: item.signCodeLength,
      codeTtlMinutes: item.codeTtlMinutes,
      remark: item.remark,
    );
  }

  factory _EditableSchedule.fallback() {
    return const _EditableSchedule(
      id: null,
      taskId: null,
      weekDay: 1,
      signInStart: '19:00:00',
      signInEnd: '21:00:00',
      lateThresholdMinutes: 15,
      signCodeLength: 4,
      codeTtlMinutes: 90,
      remark: '',
    );
  }

  _EditableSchedule copyWith({
    int? weekDay,
    String? signInStart,
    String? signInEnd,
    int? lateThresholdMinutes,
    int? signCodeLength,
    int? codeTtlMinutes,
    String? remark,
  }) {
    return _EditableSchedule(
      id: id,
      taskId: taskId,
      weekDay: weekDay ?? this.weekDay,
      signInStart: signInStart ?? this.signInStart,
      signInEnd: signInEnd ?? this.signInEnd,
      lateThresholdMinutes: lateThresholdMinutes ?? this.lateThresholdMinutes,
      signCodeLength: signCodeLength ?? this.signCodeLength,
      codeTtlMinutes: codeTtlMinutes ?? this.codeTtlMinutes,
      remark: remark ?? this.remark,
    );
  }

  AttendanceScheduleItem toItem() {
    return AttendanceScheduleItem(
      id: id,
      taskId: taskId,
      weekDay: weekDay,
      signInStart: signInStart,
      signInEnd: signInEnd,
      lateThresholdMinutes: lateThresholdMinutes,
      signCodeLength: signCodeLength,
      codeTtlMinutes: codeTtlMinutes,
      status: 1,
      remark: remark,
      createTime: null,
      updateTime: null,
    );
  }
}

class _ReviewOption {
  const _ReviewOption({required this.code, required this.label});

  final String code;
  final String label;
}
