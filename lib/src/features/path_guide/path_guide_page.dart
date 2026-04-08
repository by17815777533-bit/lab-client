import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/guide_option.dart';
import '../../repositories/guide_repository.dart';
import 'path_guide_controller.dart';

class PathGuidePage extends StatefulWidget {
  const PathGuidePage({super.key});

  @override
  State<PathGuidePage> createState() => _PathGuidePageState();
}

class _PathGuidePageState extends State<PathGuidePage> {
  late final PathGuideController _controller;
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = PathGuideController(context.read<GuideRepository>())..load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDetail(GuideOption option) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _GuideDetailSheet(option: option);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final options = _controller.options;
        final courseCount = options.fold<int>(
          0,
          (int value, GuideOption item) => value + item.courses.length,
        );
        final bookCount = options.fold<int>(
          0,
          (int value, GuideOption item) => value + item.books.length,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('方向指南'),
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
              _GuideHeroCard(
                total: options.length,
                courseCount: courseCount,
                bookCount: bookCount,
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
              PanelCard(
                child: TextField(
                  controller: _keywordController,
                  decoration: const InputDecoration(
                    labelText: '搜索方向',
                    hintText: '方向、岗位、课程、证书',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: _controller.setKeyword,
                ),
              ),
              const SizedBox(height: 16),
              if (_controller.loading && options.isEmpty)
                const PanelCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (options.isEmpty)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.explore_outlined,
                    title: '暂无方向内容',
                    message: '当前没有可展示的方向指南。',
                  ),
                )
              else
                ...options.map(
                  (GuideOption option) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _GuideCard(
                      option: option,
                      onTap: () => _openDetail(option),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GuideHeroCard extends StatelessWidget {
  const _GuideHeroCard({
    required this.total,
    required this.courseCount,
    required this.bookCount,
  });

  final int total;
  final int courseCount;
  final int bookCount;

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
            '找到更适合自己的方向',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '围绕真实岗位、学习资料、竞赛与证书做方向建议，不是空泛介绍。',
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
              _HeroPill(icon: Icons.explore_rounded, label: '方向 $total'),
              _HeroPill(
                icon: Icons.menu_book_outlined,
                label: '课程 $courseCount',
              ),
              _HeroPill(
                icon: Icons.auto_stories_outlined,
                label: '书单 $bookCount',
              ),
              const _HeroPill(icon: Icons.flag_outlined, label: '竞赛与证书'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.option, required this.onTap});

  final GuideOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: const Color(0xFFEAF2FF),
                    ),
                    child: Icon(
                      _iconFor(option.iconKey),
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          option.intention,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12223A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.career,
                          style: const TextStyle(
                            color: Color(0xFF2F76FF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF98A2B3),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                option.description,
                style: const TextStyle(height: 1.65, color: Color(0xFF516074)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _TagChip(label: '课程 ${option.courses.length}'),
                  _TagChip(label: '书单 ${option.books.length}'),
                  _TagChip(label: '竞赛 ${option.competitions.length}'),
                  _TagChip(label: '证书 ${option.certificates.length}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'backend':
        return Icons.storage_rounded;
      case 'frontend':
        return Icons.web_asset_rounded;
      case 'ai':
        return Icons.psychology_alt_rounded;
      case 'embedded':
        return Icons.memory_rounded;
      case 'security':
        return Icons.shield_outlined;
      case 'bigdata':
        return Icons.hub_outlined;
      case 'analysis':
        return Icons.bar_chart_rounded;
      case 'product':
        return Icons.design_services_outlined;
      case 'design':
        return Icons.palette_outlined;
      case 'qa':
        return Icons.bug_report_outlined;
      case 'cloud':
        return Icons.cloud_outlined;
      case 'game':
        return Icons.sports_esports_outlined;
      default:
        return Icons.explore_outlined;
    }
  }
}

class _GuideDetailSheet extends StatelessWidget {
  const _GuideDetailSheet({required this.option});

  final GuideOption option;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                option.intention,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                option.career,
                style: const TextStyle(
                  color: Color(0xFF2F76FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                option.description,
                style: const TextStyle(height: 1.7, color: Color(0xFF516074)),
              ),
              const SizedBox(height: 18),
              _DetailSection(title: '推荐课程', items: option.courses),
              _DetailSection(title: '推荐书单', items: option.books),
              _DetailSection(title: '推荐竞赛', items: option.competitions),
              _DetailSection(title: '推荐证书', items: option.certificates),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text('暂无内容', style: TextStyle(color: Color(0xFF98A2B3)))
          else
            Column(
              children: items
                  .map(
                    (String item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: Color(0xFF2F76FF),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                height: 1.6,
                                color: Color(0xFF516074),
                              ),
                            ),
                          ),
                        ],
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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF516074),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
