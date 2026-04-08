import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../repositories/forum_repository.dart';
import 'forum_controller.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  late final ForumController _controller;
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ForumController(context.read<ForumRepository>())..load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openComposer() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '发布帖子',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12223A),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '写一个清晰的问题或观点',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: '内容',
                  hintText: '描述你的问题、经验或讨论点',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    if (title.isEmpty || content.isEmpty) {
                      return;
                    }
                    final ok = await _controller.createPost(
                      title: title,
                      content: content,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop(ok);
                  },
                  child: const Text('发布'),
                ),
              ),
            ],
          ),
        );
      },
    );
    titleController.dispose();
    contentController.dispose();

    if (success == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('帖子已发布')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final detailPrefix = location.startsWith('/admin')
        ? '/admin/forum/post'
        : location.startsWith('/teacher')
        ? '/teacher/forum/post'
        : '/student/forum/post';

    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final pinnedCount = _controller.posts
            .where((post) => post.isPinned)
            .length;
        final essenceCount = _controller.posts
            .where((post) => post.isEssence)
            .length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('交流论坛'),
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
              _ForumHero(
                totalCount: _controller.total,
                pinnedCount: pinnedCount,
                essenceCount: essenceCount,
                onCompose: _openComposer,
                submitting: _controller.submitting,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _SectionHeading(
                      title: '查找讨论',
                      subtitle: '支持关键词检索和精华筛选，快速找到真正有价值的内容。',
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final compact = constraints.maxWidth < 720;
                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  TextField(
                                    controller: _keywordController,
                                    decoration: const InputDecoration(
                                      labelText: '搜索讨论',
                                      hintText: '标题、内容、关键词',
                                      prefixIcon: Icon(Icons.search_rounded),
                                    ),
                                    onChanged: _controller.setKeyword,
                                    onSubmitted: (_) => _controller.search(),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: <Widget>[
                                      ChoiceChip(
                                        label: const Text('全部帖子'),
                                        selected: !_controller.essenceOnly,
                                        onSelected: (_) => _controller
                                            .updateEssenceOnly(false),
                                      ),
                                      ChoiceChip(
                                        label: const Text('精华区'),
                                        selected: _controller.essenceOnly,
                                        onSelected: (_) =>
                                            _controller.updateEssenceOnly(true),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _controller.loading
                                            ? null
                                            : _controller.search,
                                        icon: const Icon(Icons.tune_rounded),
                                        label: const Text('应用筛选'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _controller.submitting
                                          ? null
                                          : _openComposer,
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('发布帖子'),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextField(
                                    controller: _keywordController,
                                    decoration: const InputDecoration(
                                      labelText: '搜索讨论',
                                      hintText: '标题、内容、关键词',
                                      prefixIcon: Icon(Icons.search_rounded),
                                    ),
                                    onChanged: _controller.setKeyword,
                                    onSubmitted: (_) => _controller.search(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ChoiceChip(
                                  label: const Text('全部帖子'),
                                  selected: !_controller.essenceOnly,
                                  onSelected: (_) =>
                                      _controller.updateEssenceOnly(false),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('精华区'),
                                  selected: _controller.essenceOnly,
                                  onSelected: (_) =>
                                      _controller.updateEssenceOnly(true),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _controller.loading
                                      ? null
                                      : _controller.search,
                                  icon: const Icon(Icons.tune_rounded),
                                  label: const Text('应用筛选'),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: _controller.submitting
                                      ? null
                                      : _openComposer,
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('发布帖子'),
                                ),
                              ],
                            );
                          },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_controller.loading && _controller.posts.isEmpty)
                const PanelCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_controller.posts.isEmpty)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.forum_outlined,
                    title: '还没有帖子',
                    message: '可以先发起第一个讨论，或者稍后再来看看最新交流内容。',
                  ),
                )
              else
                ..._controller.posts.map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ForumPostCard(
                      title: post.title,
                      preview: post.content,
                      author: post.authorName ?? '匿名用户',
                      time: DateTimeFormatter.dateTime(post.createTime),
                      likeCount: post.likeCount,
                      commentCount: post.commentCount,
                      viewCount: post.viewCount,
                      isPinned: post.isPinned,
                      isEssence: post.isEssence,
                      onTap: () => context.push('$detailPrefix/${post.id}'),
                    ),
                  ),
                ),
              if (_controller.posts.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: _controller.pageNum <= 1
                          ? null
                          : _controller.previousPage,
                      child: const Text('上一页'),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_controller.pageNum} / ${_controller.totalPages == 0 ? 1 : _controller.totalPages}',
                      style: const TextStyle(
                        color: Color(0xFF6D7B92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed:
                          _controller.totalPages == 0 ||
                              _controller.pageNum >= _controller.totalPages
                          ? null
                          : _controller.nextPage,
                      child: const Text('下一页'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ForumHero extends StatelessWidget {
  const _ForumHero({
    required this.totalCount,
    required this.pinnedCount,
    required this.essenceCount,
    required this.onCompose,
    required this.submitting,
  });

  final int totalCount;
  final int pinnedCount;
  final int essenceCount;
  final VoidCallback onCompose;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1652D0), Color(0xFF3E8CFF)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -18,
            top: -12,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(34),
              ),
            ),
          ),
          Positioned(
            right: 46,
            bottom: -18,
            child: Container(
              width: 72,
              height: 72,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '知识交流区',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (compact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          '把经验、问题和思路沉淀下来',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '发帖、提问、评论和沉淀高质量讨论，把交流区做成真正有用的知识现场。',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.65,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _ForumStatPill(label: '帖子', value: '$totalCount'),
                            _ForumStatPill(label: '置顶', value: '$pinnedCount'),
                            _ForumStatPill(label: '精华', value: '$essenceCount'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: submitting ? null : onCompose,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1652D0),
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('发起新讨论'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '把经验、问题和思路沉淀下来',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '发帖、提问、评论和沉淀高质量讨论，把交流区做成真正有用的知识现场。',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.65,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: <Widget>[
                                  _ForumStatPill(
                                    label: '帖子',
                                    value: '$totalCount',
                                  ),
                                  _ForumStatPill(
                                    label: '置顶',
                                    value: '$pinnedCount',
                                  ),
                                  _ForumStatPill(
                                    label: '精华',
                                    value: '$essenceCount',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 180,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '立即发布',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '记录经验、提出问题，或把实验室里的有效做法写下来。',
                                style: TextStyle(
                                  height: 1.6,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                  onPressed: submitting ? null : onCompose,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1652D0),
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('发布帖子'),
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

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

class _ForumStatPill extends StatelessWidget {
  const _ForumStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForumPostCard extends StatelessWidget {
  const _ForumPostCard({
    required this.title,
    required this.preview,
    required this.author,
    required this.time,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.isPinned,
    required this.isEssence,
    required this.onTap,
  });

  final String title;
  final String preview;
  final String author;
  final String time;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool isPinned;
  final bool isEssence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = isPinned
        ? const Color(0xFFFF8A65)
        : isEssence
        ? const Color(0xFFF59E0B)
        : const Color(0xFF2F76FF);
    final authorInitial = author.trim().isEmpty
        ? '匿'
        : author.trim().substring(0, 1);

    return PanelCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor,
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
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      authorInitial,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            if (isPinned)
                              const _LabelChip(
                                text: '置顶',
                                tone: Color(0xFFFFE4E1),
                              ),
                            if (isEssence)
                              const _LabelChip(
                                text: '精华',
                                tone: Color(0xFFFFF3D8),
                              ),
                          ],
                        ),
                        if (isPinned || isEssence) const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12223A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$author · $time',
                          style: const TextStyle(
                            color: Color(0xFF8792A6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9AA7BA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.7, color: Color(0xFF516074)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _ForumMetaChip(
                    icon: Icons.remove_red_eye_outlined,
                    label: '浏览 $viewCount',
                  ),
                  _ForumMetaChip(
                    icon: Icons.mode_comment_outlined,
                    label: '评论 $commentCount',
                  ),
                  _ForumMetaChip(
                    icon: Icons.thumb_up_off_alt_rounded,
                    label: '点赞 $likeCount',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForumMetaChip extends StatelessWidget {
  const _ForumMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5ECF8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF8792A6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6D7B92),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.text, required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF7A271A),
        ),
      ),
    );
  }
}
