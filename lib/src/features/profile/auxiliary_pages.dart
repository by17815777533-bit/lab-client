import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';

class BiometricCollectionPage extends StatelessWidget {
  const BiometricCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('生物信息采集')),
      body: ResponsiveListView(
        children: <Widget>[
          const _FeatureHero(
            title: '身份核验信息',
            subtitle: '用于实验室门禁、签到和身份核验的基础信息登记。',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 16),
          PanelCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              children: const <Widget>[
                _StatusTile(
                  title: '人脸信息',
                  description: '用于设备登录与现场核验',
                  status: '未登记',
                ),
                _StatusTile(
                  title: '指纹信息',
                  description: '用于门禁与实验室登记',
                  status: '未登记',
                ),
                _StatusTile(
                  title: '声纹信息',
                  description: '用于语音核验场景',
                  status: '未登记',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '采集说明',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
                ),
                SizedBox(height: 12),
                _BulletLine(text: '请在学院或实验室统一安排的登记设备上完成采集。'),
                _BulletLine(text: '登记完成后，相关状态会自动更新到个人中心。'),
                _BulletLine(text: '如已完成线下登记但页面未更新，请联系管理员核对。'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我收藏的')),
      body: ResponsiveListView(
        children: const <Widget>[
          _FeatureHero(
            title: '个人收藏',
            subtitle: '实验室、公告和资料等内容会在这里统一展示。',
            icon: Icons.star_border_rounded,
          ),
          SizedBox(height: 16),
          PanelCard(
            child: EmptyState(
              icon: Icons.collections_bookmark_outlined,
              title: '还没有收藏内容',
              message: '当你收藏实验室、公告或资料后，会在这里集中查看。',
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackRecordsPage extends StatelessWidget {
  const FeedbackRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我反馈的')),
      body: ResponsiveListView(
        children: <Widget>[
          const _FeatureHero(
            title: '意见与反馈',
            subtitle: '查看你提交过的问题记录，并了解常见反馈渠道。',
            icon: Icons.note_alt_outlined,
          ),
          const SizedBox(height: 16),
          const PanelCard(
            child: EmptyState(
              icon: Icons.forum_outlined,
              title: '暂无反馈记录',
              message: '目前还没有你的反馈内容，遇到问题可联系实验室管理员或学院管理员协助处理。',
            ),
          ),
          const SizedBox(height: 16),
          const PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '常见受理场景',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12223A),
                  ),
                ),
                SizedBox(height: 12),
                _BulletLine(text: '登录信息异常或身份显示错误'),
                _BulletLine(text: '实验室申请状态与实际流程不一致'),
                _BulletLine(text: '公告、资料或个人信息显示异常'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帮助与反馈')),
      body: ResponsiveListView(
        children: <Widget>[
          const _FeatureHero(
            title: '帮助中心',
            subtitle: '常见问题、资料说明和申请流程指引都集中在这里。',
            icon: Icons.help_outline_rounded,
          ),
          const SizedBox(height: 16),
          const PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _FaqTile(
                  question: '如何申请加入实验室？',
                  answer: '进入“实验室”页面，选择开放中的实验室和招新计划，填写申请理由后提交即可。',
                ),
                _FaqTile(
                  question: '为什么不能提交实验室申请？',
                  answer: '加入实验室前需要先完善个人资料，并上传简历；已加入实验室后不能重复申请。',
                ),
                _FaqTile(
                  question: '如何查看公告？',
                  answer: '在“资讯”页面可按学校、学院、实验室范围筛选最新公告。',
                ),
                _FaqTile(
                  question: '如何更新头像和个人资料？',
                  answer: '进入“我的”页面，可直接修改头像、资料和简历信息。',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureHero extends StatelessWidget {
  const _FeatureHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF2D78FF), Color(0xFF67CFFF)],
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
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    height: 1.65,
                    color: Colors.white.withValues(alpha: 0.88),
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

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.description,
    required this.status,
    this.isLast = false,
  });

  final String title;
  final String description;
  final String status;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
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
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFF6D7B92)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x14F59E0B),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '•',
            style: TextStyle(color: Color(0xFF2F76FF), fontSize: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.65, color: Color(0xFF516074)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    this.isLast = false,
  });

  final String question;
  final String answer;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12223A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: const TextStyle(height: 1.7, color: Color(0xFF516074)),
          ),
        ],
      ),
    );
  }
}
