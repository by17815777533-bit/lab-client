import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/panel_card.dart';
import '../../models/latest_lab_application.dart';

class LatestLabApplyPanel extends StatelessWidget {
  const LatestLabApplyPanel({super.key, required this.items});

  final List<LatestLabApplication> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  '最近申请动态',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/admin/applications'),
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: items
                .map(
                  (LatestLabApplication item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FD),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE3EAF7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  item.studentName ?? '未命名学生',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF12223A),
                                  ),
                                ),
                              ),
                              _StatusChip(status: item.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.studentId ?? '-'} · ${item.major ?? '未填写专业'}',
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.planTitle ?? '未命名计划',
                            style: const TextStyle(
                              color: Color(0xFF2F76FF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateTimeFormatter.dateTime(item.createTime),
                            style: const TextStyle(
                              color: Color(0xFF98A2B3),
                              fontSize: 12,
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
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    late final String label;

    switch (status) {
      case 'approved':
        background = const Color(0xFFDFF7EA);
        foreground = const Color(0xFF067647);
        label = '已通过';
        break;
      case 'rejected':
        background = const Color(0xFFFDE7EA);
        foreground = const Color(0xFFB42318);
        label = '已驳回';
        break;
      case 'leader_approved':
        background = const Color(0xFFE8F1FF);
        foreground = const Color(0xFF1D4ED8);
        label = '初审通过';
        break;
      default:
        background = const Color(0xFFFFF4D6);
        foreground = const Color(0xFFB54708);
        label = '待审核';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
