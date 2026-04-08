import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/shells/portal_shell_scaffold.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/notices/notices_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/statistics/statistics_page.dart';

class AdminPortal {
  static const List<PortalDestinationSpec> destinations =
      <PortalDestinationSpec>[
        PortalDestinationSpec(
          label: '首页',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        PortalDestinationSpec(
          label: '统计',
          icon: Icons.query_stats_outlined,
          selectedIcon: Icons.query_stats_rounded,
        ),
        PortalDestinationSpec(
          label: '公告',
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications_rounded,
        ),
        PortalDestinationSpec(
          label: '我的',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ];

  static List<Widget> buildPages() {
    return const <Widget>[
      DashboardPage(),
      StatisticsWorkbenchPage(),
      NoticesPage(),
      ProfilePage(),
    ];
  }
}

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant AdminShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  void _goTo(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 1:
        context.go('/admin/statistics');
        break;
      case 2:
        context.go('/admin/notices');
        break;
      case 3:
        context.go('/admin/profile');
        break;
      default:
        context.go('/admin');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PortalShellScaffold(
      title: '管理门户',
      currentIndex: _currentIndex,
      destinations: AdminPortal.destinations,
      pages: AdminPortal.buildPages(),
      onDestinationSelected: _goTo,
    );
  }
}
