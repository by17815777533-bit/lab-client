import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../repositories/notice_repository.dart';
import 'notices_controller.dart';

class NoticesPage extends StatefulWidget {
  const NoticesPage({super.key});

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  late final NoticesController _controller;
  final TextEditingController _keywordController = TextEditingController();

  static const List<_ScopeFilter> _scopeOptions = <_ScopeFilter>[
    _ScopeFilter(label: '全部', value: null),
    _ScopeFilter(label: '学校', value: 'school'),
    _ScopeFilter(label: '学院', value: 'college'),
    _ScopeFilter(label: '实验室', value: 'lab'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = NoticesController(context.read<NoticeRepository>())..load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        return ResponsiveListView(
          onRefresh: _controller.load,
          children: <Widget>[
            const _NoticesHero(),
            const SizedBox(height: 16),
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '筛选公告',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12223A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '按范围和关键词过滤，快速找到与你当前身份相关的公告。',
                    style: TextStyle(height: 1.65, color: Color(0xFF6D7B92)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _keywordController,
                    decoration: InputDecoration(
                      hintText: '搜索标题或正文',
                      suffixIcon: IconButton(
                        onPressed: () => _controller.applyFilter(
                          keyword: _keywordController.text,
                          scope: _controller.scope,
                        ),
                        icon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    onSubmitted: (_) => _controller.applyFilter(
                      keyword: _keywordController.text,
                      scope: _controller.scope,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _scopeOptions
                        .map(
                          (option) => ChoiceChip(
                            label: Text(option.label),
                            selected: _controller.scope == option.value,
                            onSelected: (_) => _controller.applyFilter(
                              keyword: _keywordController.text,
                              scope: option.value,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_controller.loading && _controller.items.isEmpty)
              const PanelCard(child: Center(child: CircularProgressIndicator()))
            else if (_controller.items.isEmpty)
              const PanelCard(
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: '暂无公告',
                  message: '当前筛选条件下没有查询到公告。',
                ),
              )
            else
              ..._controller.items.map(
                (notice) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 58,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F76FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x142F76FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                notice.scopeLabel,
                                style: const TextStyle(
                                  color: Color(0xFF2F76FF),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateTimeFormatter.dateTime(notice.publishTime),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8792A6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          notice.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12223A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          notice.content,
                          style: const TextStyle(
                            height: 1.7,
                            color: Color(0xFF516074),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: <Widget>[
                            Text(
                              notice.collegeName ?? '全校',
                              style: const TextStyle(color: Color(0xFF6D7B92)),
                            ),
                            Text(
                              notice.labName ?? '公共公告',
                              style: const TextStyle(color: Color(0xFF6D7B92)),
                            ),
                            Text(
                              notice.publisherName ?? '系统',
                              style: const TextStyle(color: Color(0xFF6D7B92)),
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
                    onPressed: _controller.pageNum > 1
                        ? _controller.previousPage
                        : null,
                    child: const Text('上一页'),
                  ),
                  const Spacer(),
                  Text(
                    '${_controller.pageNum} / ${_controller.totalPages} · 共 ${_controller.total} 条',
                    style: const TextStyle(
                      color: Color(0xFF6D7B92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
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
        );
      },
    );
  }
}

class _ScopeFilter {
  const _ScopeFilter({required this.label, required this.value});

  final String label;
  final String? value;
}

class _NoticesHero extends StatelessWidget {
  const _NoticesHero();

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
              width: 102,
              height: 102,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '公告中心',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '学校、学院和实验室的公告会统一出现在这里，重要信息不再分散在不同入口里。',
                style: TextStyle(color: Colors.white, height: 1.7),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
