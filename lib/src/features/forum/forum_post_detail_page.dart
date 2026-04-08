import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../auth/auth_controller.dart';
import '../../repositories/forum_repository.dart';
import 'forum_post_detail_controller.dart';

class ForumPostDetailPage extends StatefulWidget {
  const ForumPostDetailPage({super.key, required this.postId});

  final int postId;

  @override
  State<ForumPostDetailPage> createState() => _ForumPostDetailPageState();
}

class _ForumPostDetailPageState extends State<ForumPostDetailPage> {
  late final ForumPostDetailController _controller;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ForumPostDetailController(
      repository: context.read<ForumRepository>(),
      postId: widget.postId,
    )..load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      return;
    }
    final success = await _controller.createComment(content);
    if (success) {
      _commentController.clear();
    }
  }

  Future<void> _confirmDeletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除帖子'),
          content: const Text('删除后将无法恢复，是否继续？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _controller.deletePost();
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile!;

    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        final post = _controller.post;
        final canManagePost =
            post != null && (profile.isAdmin || post.userId == profile.id);

        return Scaffold(
          appBar: AppBar(title: const Text('帖子详情')),
          body: ResponsiveListView(
            onRefresh: _controller.refresh,
            children: <Widget>[
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
              if (_controller.loading && post == null)
                const PanelCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (post == null)
                const PanelCard(
                  child: EmptyState(
                    icon: Icons.article_outlined,
                    title: '帖子不存在',
                    message: '当前内容可能已被删除，或暂时无法访问。',
                  ),
                )
              else ...<Widget>[
                PanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          if (post.isPinned)
                            const _Tag(text: '置顶', tone: Color(0xFFFFE4E1)),
                          if (post.isEssence)
                            const _Tag(text: '精华', tone: Color(0xFFFFF3D8)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12223A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: <Widget>[
                          Text(
                            post.authorName ?? '匿名用户',
                            style: const TextStyle(color: Color(0xFF2F76FF)),
                          ),
                          Text(
                            DateTimeFormatter.dateTime(post.createTime),
                            style: const TextStyle(color: Color(0xFF8792A6)),
                          ),
                          Text(
                            '浏览 ${post.viewCount}',
                            style: const TextStyle(color: Color(0xFF8792A6)),
                          ),
                          Text(
                            '评论 ${post.commentCount}',
                            style: const TextStyle(color: Color(0xFF8792A6)),
                          ),
                          Text(
                            '点赞 ${post.likeCount}',
                            style: const TextStyle(color: Color(0xFF8792A6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        post.content,
                        style: const TextStyle(
                          height: 1.8,
                          color: Color(0xFF516074),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton.tonalIcon(
                            onPressed: _controller.mutating
                                ? null
                                : _controller.toggleLike,
                            icon: Icon(
                              post.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                            ),
                            label: Text(post.isLiked ? '已点赞' : '点赞'),
                          ),
                          if (canManagePost)
                            OutlinedButton.icon(
                              onPressed: _controller.mutating
                                  ? null
                                  : _confirmDeletePost,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('删除帖子'),
                            ),
                          if (profile.isAdmin)
                            OutlinedButton.icon(
                              onPressed: _controller.mutating
                                  ? null
                                  : _controller.togglePinned,
                              icon: const Icon(Icons.push_pin_outlined),
                              label: Text(post.isPinned ? '取消置顶' : '设为置顶'),
                            ),
                          if (profile.isAdmin)
                            OutlinedButton.icon(
                              onPressed: _controller.mutating
                                  ? null
                                  : _controller.toggleEssence,
                              icon: const Icon(
                                Icons.workspace_premium_outlined,
                              ),
                              label: Text(post.isEssence ? '取消精华' : '设为精华'),
                            ),
                        ],
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
                        '发表评论',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12223A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _commentController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: '写下你的想法、建议或补充',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _controller.mutating
                              ? null
                              : _submitComment,
                          child: const Text('发布评论'),
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
                      Text(
                        '全部评论（${post.commentCount}）',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12223A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_controller.comments.isEmpty)
                        const EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: '还没有评论',
                          message: '可以先写下你的想法，帮助这个讨论继续往前走。',
                        )
                      else
                        ..._controller.comments.map((comment) {
                          final canDelete =
                              profile.isAdmin || comment.userId == profile.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFF),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(
                                          0xFFEAF2FF,
                                        ),
                                        child: Text(
                                          comment.initials,
                                          style: const TextStyle(
                                            color: Color(0xFF1D4ED8),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              comment.authorName ?? '匿名用户',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF12223A),
                                              ),
                                            ),
                                            Text(
                                              DateTimeFormatter.dateTime(
                                                comment.createTime,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF8792A6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (canDelete)
                                        TextButton(
                                          onPressed: _controller.mutating
                                              ? null
                                              : () => _controller.deleteComment(
                                                  comment.id,
                                                ),
                                          child: const Text('删除'),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    comment.content,
                                    style: const TextStyle(
                                      height: 1.7,
                                      color: Color(0xFF516074),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      if (_controller.comments.isNotEmpty) ...<Widget>[
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
                                      _controller.pageNum >=
                                          _controller.totalPages
                                  ? null
                                  : _controller.nextPage,
                              child: const Text('下一页'),
                            ),
                          ],
                        ),
                      ],
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

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.tone});

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
