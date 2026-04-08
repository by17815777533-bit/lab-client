import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/shells/portal_shell_scaffold.dart';
import '../../features/applications/applications_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/labs/labs_page.dart';
import '../../features/profile/profile_page.dart';
import '../shared/workspace_route_page.dart';

class StudentPortal {
  static const List<PortalDestinationSpec> destinations =
      <PortalDestinationSpec>[
        PortalDestinationSpec(
          label: '首页',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        PortalDestinationSpec(
          label: '实验室',
          icon: Icons.science_outlined,
          selectedIcon: Icons.science_rounded,
        ),
        PortalDestinationSpec(
          label: '空间',
          icon: Icons.folder_open_outlined,
          selectedIcon: Icons.folder_open_rounded,
        ),
        PortalDestinationSpec(
          label: '申请',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment_rounded,
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
      LabsPage(),
      WorkspaceRoutePage(),
      ApplicationsPage(),
      ProfilePage(),
    ];
  }
}

class StudentShellPage extends StatefulWidget {
  const StudentShellPage({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<StudentShellPage> createState() => _StudentShellPageState();
}

class _StudentShellPageState extends State<StudentShellPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant StudentShellPage oldWidget) {
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
        context.go('/student/labs');
        break;
      case 2:
        context.go('/student/workspace');
        break;
      case 3:
        context.go('/student/applications');
        break;
      case 4:
        context.go('/student/profile');
        break;
      default:
        context.go('/student');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PortalShellScaffold(
      title: '学生门户',
      currentIndex: _currentIndex,
      destinations: StudentPortal.destinations,
      pages: StudentPortal.buildPages(),
      onDestinationSelected: _goTo,
    );
  }
}
