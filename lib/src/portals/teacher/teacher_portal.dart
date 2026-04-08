import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/shells/portal_shell_scaffold.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/lab_create_apply/lab_create_apply_page.dart';
import '../../features/profile/profile_page.dart';
import '../shared/workspace_route_page.dart';

class TeacherPortal {
  static const List<PortalDestinationSpec> destinations =
      <PortalDestinationSpec>[
        PortalDestinationSpec(
          label: '首页',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        PortalDestinationSpec(
          label: '申请',
          icon: Icons.post_add_outlined,
          selectedIcon: Icons.post_add_rounded,
        ),
        PortalDestinationSpec(
          label: '空间',
          icon: Icons.folder_open_outlined,
          selectedIcon: Icons.folder_open_rounded,
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
      LabCreateApplyPage(),
      WorkspaceRoutePage(),
      ProfilePage(),
    ];
  }
}

class TeacherShellPage extends StatefulWidget {
  const TeacherShellPage({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<TeacherShellPage> createState() => _TeacherShellPageState();
}

class _TeacherShellPageState extends State<TeacherShellPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant TeacherShellPage oldWidget) {
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
        context.go('/teacher/create-applies');
        break;
      case 2:
        context.go('/teacher/workspace');
        break;
      case 3:
        context.go('/teacher/profile');
        break;
      default:
        context.go('/teacher');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PortalShellScaffold(
      title: '教师门户',
      currentIndex: _currentIndex,
      destinations: TeacherPortal.destinations,
      pages: TeacherPortal.buildPages(),
      onDestinationSelected: _goTo,
    );
  }
}
