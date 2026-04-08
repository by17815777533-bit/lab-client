import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/user_profile.dart';
import '../../models/paged_result.dart';
import 'attendance_controller.dart';
import 'attendance_models.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  late final AttendanceController _controller;
  final GlobalKey<FormState> _signFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _makeupFormKey = GlobalKey<FormState>();
  final TextEditingController _signCodeController = TextEditingController();
  final TextEditingController _signRemarkController = TextEditingController();
  final TextEditingController _makeupRemarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AttendanceController(
      ref.read(attendanceWorkflowRepositoryProvider),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _signCodeController.dispose();
    _signRemarkController.dispose();
    _makeupRemarkController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    if (!(_signFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await _controller.submitSignIn(
      signCode: _signCodeController.text,
      remark: _signRemarkController.text,
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '签到已提交' : _controller.errorMessage ?? '签到失败'),
      ),
    );
  }

  Future<void> _submitMakeup() async {
    if (!(_makeupFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await _controller.submitMakeup(
      remark: _makeupRemarkController.text,
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '补签申请已提交' : _controller.errorMessage ?? '补签申请失败',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;
    if (profile == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final session = _controller.currentSession;
        final historyPage = _controller.historyPage;
        final hasLab = profile.labId != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('考勤签到'),
            actions: <Widget>[
              IconButton(
                tooltip: '刷新',
                onPressed: _controller.loading ? null : _controller.load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: ResponsiveListView(
            onRefresh: _controller.load,
            children: <Widget>[
              _AttendanceHero(profile: profile, session: session),
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
              if (!hasLab)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.apartment_outlined,
                    title: '当前未加入实验室',
                    message: '加入实验室后，这里会显示当前会话、签到与历史记录。',
                  ),
                )
              else ...<Widget>[
                _SessionMetrics(session: session),
                const SizedBox(height: 16),
                _SessionPanel(
                  session: session,
                  signFormKey: _signFormKey,
                  signCodeController: _signCodeController,
                  signRemarkController: _signRemarkController,
                  makeupFormKey: _makeupFormKey,
                  makeupRemarkController: _makeupRemarkController,
                  onSubmitSignIn: _controller.signingIn ? null : _submitSignIn,
                  onSubmitMakeup: _controller.requestingMakeup
                      ? null
                      : _submitMakeup,
                  signingIn: _controller.signingIn,
                  requestingMakeup: _controller.requestingMakeup,
                ),
                const SizedBox(height: 16),
                _HistoryPanel(
                  historyPage: historyPage,
                  loading: _controller.loadingHistory,
                  pageNum: _controller.historyPageNum,
                  totalPages: _controller.historyTotalPages,
                  total: _controller.historyTotal,
                  onPrevious: _controller.previousHistoryPage,
                  onNext: _controller.nextHistoryPage,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceHero extends StatelessWidget {
  const _AttendanceHero({required this.profile, required this.session});

  final UserProfile profile;
  final AttendanceCurrentSession? session;

  @override
  Widget build(BuildContext context) {
    final labId = profile.labId;

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
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.how_to_reg_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '考勤签到',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labId == null ? '当前未绑定实验室' : '实验室 #$labId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session?.statusLabel ?? '今日尚无可用会话',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionMetrics extends StatelessWidget {
  const _SessionMetrics({required this.session});

  final AttendanceCurrentSession? session;

  @override
  Widget build(BuildContext context) {
    final cards = <_MetricData>[
      _MetricData(
        label: '会话状态',
        value: session?.statusLabel ?? '暂无',
        hint: '来自当前考勤会话',
      ),
      _MetricData(
        label: '出勤率',
        value: session == null
            ? '0%'
            : '${session!.attendanceRate.toStringAsFixed(0)}%',
        hint: '按当前会话汇总',
      ),
      _MetricData(
        label: '我的状态',
        value: session?.myRecord?.statusLabel ?? '未签到',
        hint: '我的最新记录',
      ),
      _MetricData(
        label: '历史记录',
        value: (session?.totalCount ?? 0).toString(),
        hint: '会话汇总数量',
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map(
            (card) => SizedBox(
              width: 220,
              child: PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      card.label,
                      style: const TextStyle(
                        color: Color(0xFF6D7B92),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12223A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.hint,
                      style: const TextStyle(
                        color: Color(0xFF8792A6),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SessionPanel extends StatelessWidget {
  const _SessionPanel({
    required this.session,
    required this.signFormKey,
    required this.signCodeController,
    required this.signRemarkController,
    required this.makeupFormKey,
    required this.makeupRemarkController,
    required this.onSubmitSignIn,
    required this.onSubmitMakeup,
    required this.signingIn,
    required this.requestingMakeup,
  });

  final AttendanceCurrentSession? session;
  final GlobalKey<FormState> signFormKey;
  final TextEditingController signCodeController;
  final TextEditingController signRemarkController;
  final GlobalKey<FormState> makeupFormKey;
  final TextEditingController makeupRemarkController;
  final VoidCallback? onSubmitSignIn;
  final VoidCallback? onSubmitMakeup;
  final bool signingIn;
  final bool requestingMakeup;

  @override
  Widget build(BuildContext context) {
    if (session == null || !session!.available) {
      return const PanelCard(
        child: EmptyState(
          icon: Icons.schedule_outlined,
          title: '今日暂无考勤会话',
          message: '当前没有可用的签到会话，等实验室发布后这里会自动显示。',
        ),
      );
    }

    return Column(
      children: <Widget>[
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '当前会话',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _Pill(label: DateTimeFormatter.date(session!.sessionDate)),
                  _Pill(label: session!.statusLabel),
                  _Pill(label: '照片 ${session!.photoCount}'),
                  if (session!.canSignIn) const _Pill(label: '可签到'),
                  if (!session!.canSignIn) const _Pill(label: '不可签到'),
                ],
              ),
              const SizedBox(height: 16),
              _KeyValueRow(
                label: '开始时间',
                value: DateTimeFormatter.dateTime(session!.signStartTime),
              ),
              _KeyValueRow(
                label: '结束时间',
                value: DateTimeFormatter.dateTime(session!.signEndTime),
              ),
              _KeyValueRow(
                label: '迟到时间',
                value: DateTimeFormatter.dateTime(session!.lateTime),
              ),
              _KeyValueRow(
                label: '口令过期',
                value: DateTimeFormatter.dateTime(session!.codeExpireTime),
              ),
              if (session!.myRecord != null) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '我的记录',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF12223A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session!.myRecord!.statusLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F76FF),
                        ),
                      ),
                      if ((session!.myRecord!.remark ?? '')
                          .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          session!.myRecord!.remark!,
                          style: const TextStyle(
                            color: Color(0xFF516074),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '今日签到',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '输入实验室当天公布的签到口令后提交。',
                style: TextStyle(color: Color(0xFF6D7B92), height: 1.6),
              ),
              const SizedBox(height: 16),
              Form(
                key: signFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: signCodeController,
                      decoration: const InputDecoration(
                        labelText: '签到口令',
                        prefixIcon: Icon(Icons.key_rounded),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入签到口令';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: signRemarkController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: (session!.canSignIn && !signingIn)
                          ? onSubmitSignIn
                          : null,
                      child: signingIn
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('提交签到'),
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
              const Text(
                '补签申请',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '会话结束后可提交补签说明，等待管理员处理。',
                style: TextStyle(color: Color(0xFF6D7B92), height: 1.6),
              ),
              const SizedBox(height: 16),
              Form(
                key: makeupFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: makeupRemarkController,
                      maxLines: 3,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: '补签说明',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                      validator: (String? value) {
                        if ((value ?? '').trim().isEmpty) {
                          return '请填写补签说明';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        session!.isClosed
                            ? '当前会话已结束，可以提交补签申请。'
                            : '补签申请会在会话结束后开放。',
                        style: const TextStyle(
                          color: Color(0xFF8792A6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.tonal(
                      onPressed: !requestingMakeup && session!.isClosed
                          ? onSubmitMakeup
                          : null,
                      child: requestingMakeup
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('提交补签申请'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.historyPage,
    required this.loading,
    required this.pageNum,
    required this.totalPages,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final PagedResult<AttendanceHistoryRecord>? historyPage;
  final bool loading;
  final int pageNum;
  final int totalPages;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final records = historyPage?.records ?? const <AttendanceHistoryRecord>[];

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '历史记录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          const SizedBox(height: 14),
          if (loading && records.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (records.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: '暂无历史记录',
              message: '签到与补签记录会按时间顺序显示在这里。',
            )
          else
            Column(
              children: records
                  .map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HistoryItem(record: record),
                    ),
                  )
                  .toList(),
            ),
          if (total > 0) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: pageNum > 1 ? onPrevious : null,
                  child: const Text('上一页'),
                ),
                const Spacer(),
                Text(
                  '$pageNum / ${totalPages == 0 ? 1 : totalPages} · 共 $total 条',
                  style: const TextStyle(
                    color: Color(0xFF6D7B92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: pageNum < totalPages ? onNext : null,
                  child: const Text('下一页'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.record});

  final AttendanceHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final colorToken = AttendanceStatusFormatter.color(record.signStatus);
    final color = switch (colorToken) {
      ColorToken.success => const Color(0xFF0F9D58),
      ColorToken.warning => const Color(0xFFF59E0B),
      ColorToken.info => const Color(0xFF2F76FF),
      ColorToken.danger => const Color(0xFFE53935),
      ColorToken.neutral => const Color(0xFF6D7B92),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  record.labName ?? '实验室',
                  style: const TextStyle(
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.statusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            DateTimeFormatter.date(record.sessionDate),
            style: const TextStyle(
              color: Color(0xFF516074),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '签到时间：${DateTimeFormatter.dateTime(record.signTime)}',
            style: const TextStyle(color: Color(0xFF8792A6)),
          ),
          if ((record.remark ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              record.remark!,
              style: const TextStyle(color: Color(0xFF516074), height: 1.6),
            ),
          ],
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 76,
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
              ),
            ),
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
        color: const Color(0x142F76FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2F76FF),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;
}
