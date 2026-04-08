import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin_management/admin_management_page.dart';
import '../../features/admin_accounts/admin_accounts_page.dart';
import '../../features/attendance/attendance_page.dart';
import '../../features/attendance_management/attendance_management_page.dart';
import '../../features/delivery_management/delivery_management_page.dart';
import '../../features/equipment/equipment_page.dart';
import '../../features/equipment_admin/equipment_admin_page.dart';
import '../../features/exit_audit/exit_audit_page.dart';
import '../../features/exit_application/exit_application_page.dart';
import '../../features/forum/forum_page.dart';
import '../../features/forum/forum_post_detail_page.dart';
import '../../features/gradpath/gradpath_page.dart';
import '../../features/graduate_management/graduate_management_page.dart';
import '../../features/growth_center/growth_center_page.dart';
import '../../features/growth_center/growth_practice_page.dart';
import '../../features/growth_question_bank/growth_question_bank_page.dart';
import '../../features/lab_apply_audit/lab_apply_audit_page.dart';
import '../../features/lab_info_management/lab_info_management_page.dart';
import '../../features/notices/notices_page.dart';
import '../../features/path_guide/path_guide_page.dart';
import '../../features/recruit_plan_management/recruit_plan_management_page.dart';
import '../../features/student_management/student_management_page.dart';
import '../../features/teacher_register_audit/teacher_register_audit_page.dart';
import '../../features/written_exam/written_exam_page.dart';
import '../../features/written_exam_management/written_exam_management_page.dart';
import '../../portals/admin/admin_portal.dart';
import '../../portals/public/public_login_page.dart';
import '../../portals/shared/workspace_route_page.dart';
import '../../portals/student/student_portal.dart';
import '../../portals/teacher/teacher_portal.dart';
import '../providers.dart';
import 'portal_resolver.dart';
import 'route_guards.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authController = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authController,
    redirect: (context, state) {
      final currentPath = state.matchedLocation;
      final portalType = resolvePortalType(authController.profile);
      final requestedPortal = portalTypeForPath(currentPath);

      if (authController.initializing) {
        return null;
      }

      if (!authController.isAuthenticated) {
        return isPublicPath(currentPath) ? null : '/login';
      }

      if (isPublicPath(currentPath)) {
        return resolvePortalHome(portalType);
      }

      if (requestedPortal != null && requestedPortal != portalType) {
        return resolvePortalHome(portalType);
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: PublicLoginPage()),
      ),
      GoRoute(path: '/register', redirect: (context, state) => '/login'),
      GoRoute(
        path: '/teacher-register',
        redirect: (context, state) => '/login',
      ),
      GoRoute(path: '/password-reset', redirect: (context, state) => '/login'),
      GoRoute(
        path: '/student',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: StudentShellPage(initialIndex: 0)),
      ),
      GoRoute(
        path: '/student/dashboard',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: StudentShellPage(initialIndex: 0)),
      ),
      GoRoute(
        path: '/student/labs',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: StudentShellPage(initialIndex: 1)),
      ),
      GoRoute(
        path: '/student/workspace',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: StudentShellPage(initialIndex: 2)),
      ),
      GoRoute(
        path: '/student/attendance',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AttendancePage()),
      ),
      GoRoute(
        path: '/student/equipment',
        pageBuilder: (context, state) => NoTransitionPage(
          child: EquipmentPage(
            repository: ref.read(equipmentRepositoryProvider),
            profile: ref.read(authControllerProvider).profile!,
          ),
        ),
      ),
      GoRoute(
        path: '/student/exit-application',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ExitApplicationPage()),
      ),
      GoRoute(
        path: '/student/applications',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: StudentShellPage(initialIndex: 3)),
      ),
      GoRoute(
        path: '/student/services',
        redirect: (context, state) => '/student/applications',
      ),
      GoRoute(
        path: '/student/notices',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: NoticesPage()),
      ),
      GoRoute(
        path: '/student/path-guide',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: PathGuidePage()),
      ),
      GoRoute(
        path: '/student/growth-center',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: GrowthCenterPage()),
      ),
      GoRoute(
        path: '/student/growth-practice',
        pageBuilder: (context, state) => NoTransitionPage(
          child: GrowthPracticePage(
            initialTrackCode: state.uri.queryParameters['track'],
          ),
        ),
      ),
      GoRoute(
        path: '/student/gradpath',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: GradPathPage()),
      ),
      GoRoute(
        path: '/student/written-exams',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: WrittenExamPage()),
      ),
      GoRoute(
        path: '/student/written-exams/:labId',
        pageBuilder: (context, state) => NoTransitionPage(
          child: WrittenExamPage(
            labId: int.tryParse(state.pathParameters['labId'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: '/student/forum',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ForumPage()),
      ),
      GoRoute(
        path: '/student/forum/post/:postId',
        pageBuilder: (context, state) => NoTransitionPage(
          child: ForumPostDetailPage(
            postId: int.tryParse(state.pathParameters['postId'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/student/profile',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: StudentShellPage(initialIndex: 4)),
      ),
      GoRoute(
        path: '/teacher',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TeacherShellPage(initialIndex: 0)),
      ),
      GoRoute(
        path: '/teacher/dashboard',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TeacherShellPage(initialIndex: 0)),
      ),
      GoRoute(
        path: '/teacher/create-applies',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TeacherShellPage(initialIndex: 1)),
      ),
      GoRoute(
        path: '/teacher/workspace',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TeacherShellPage(initialIndex: 2)),
      ),
      GoRoute(
        path: '/teacher/attendance-workbench',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AttendanceManagementPage()),
      ),
      GoRoute(
        path: '/teacher/notices',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: NoticesPage()),
      ),
      GoRoute(
        path: '/teacher/forum',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ForumPage()),
      ),
      GoRoute(
        path: '/teacher/forum/post/:postId',
        pageBuilder: (context, state) => NoTransitionPage(
          child: ForumPostDetailPage(
            postId: int.tryParse(state.pathParameters['postId'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/teacher/profile',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TeacherShellPage(initialIndex: 3)),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AdminShellPage(initialIndex: 0)),
      ),
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AdminShellPage(initialIndex: 0)),
      ),
      GoRoute(
        path: '/admin/statistics',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AdminShellPage(initialIndex: 1)),
      ),
      GoRoute(
        path: '/admin/forum',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ForumPage()),
      ),
      GoRoute(
        path: '/admin/forum/post/:postId',
        pageBuilder: (context, state) => NoTransitionPage(
          child: ForumPostDetailPage(
            postId: int.tryParse(state.pathParameters['postId'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/admin/admin-management',
        redirect: (context, state) {
          final profile = ref.read(authControllerProvider).profile;
          if (profile?.schoolDirector != true) {
            return '/admin/statistics';
          }
          return null;
        },
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AdminManagementPage()),
      ),
      GoRoute(
        path: '/admin/admin-accounts',
        redirect: (context, state) {
          final profile = ref.read(authControllerProvider).profile;
          if (profile?.schoolDirector != true) {
            return '/admin/statistics';
          }
          return null;
        },
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AdminAccountsPage()),
      ),
      GoRoute(
        path: '/admin/students',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: StudentManagementPage()),
      ),
      GoRoute(
        path: '/admin/deliveries',
        pageBuilder: (context, state) => NoTransitionPage(
          child: DeliveryManagementPage(
            initialRealName: state.uri.queryParameters['realName'],
            initialStudentId: state.uri.queryParameters['studentId'],
            initialAuditStatus: int.tryParse(
              state.uri.queryParameters['auditStatus'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/recruit-plans',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RecruitPlanManagementPage()),
      ),
      GoRoute(
        path: '/admin/growth-question-bank',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: GrowthQuestionBankPage()),
      ),
      GoRoute(
        path: '/admin/written-exams',
        redirect: (context, state) {
          final profile = ref.read(authControllerProvider).profile;
          if (profile?.labManager != true) {
            return '/admin/statistics';
          }
          return null;
        },
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: WrittenExamManagementPage()),
      ),
      GoRoute(
        path: '/admin/graduates',
        redirect: (context, state) {
          final profile = ref.read(authControllerProvider).profile;
          if (profile?.labManager != true) {
            return '/admin/statistics';
          }
          return null;
        },
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: GraduateManagementPage()),
      ),
      GoRoute(
        path: '/admin/lab-info',
        redirect: (context, state) {
          final profile = ref.read(authControllerProvider).profile;
          if (profile?.labManager != true) {
            return '/admin/statistics';
          }
          return null;
        },
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LabInfoManagementPage()),
      ),
      GoRoute(
        path: '/admin/attendance-workbench',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AttendanceManagementPage()),
      ),
      GoRoute(
        path: '/admin/exit-audits',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ExitAuditPage()),
      ),
      GoRoute(
        path: '/admin/equipment',
        redirect: (context, state) {
          final profile = ref.read(authControllerProvider).profile;
          if (profile?.labManager != true) {
            return '/admin/statistics';
          }
          return null;
        },
        pageBuilder: (context, state) => NoTransitionPage(
          child: EquipmentAdminPage(
            repository: ref.read(equipmentRepositoryProvider),
            baseUrl: ref.read(appSettingsControllerProvider).baseUrl,
            labId: ref.read(authControllerProvider).profile?.labId,
          ),
        ),
      ),
      GoRoute(
        path: '/admin/workspace',
        redirect: (context, state) {
          final profile = ref.read(authControllerProvider).profile;
          if (profile?.labManager != true) {
            return '/admin/statistics';
          }
          return null;
        },
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: WorkspaceRoutePage()),
      ),
      GoRoute(
        path: '/admin/applications',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LabApplyAuditPage()),
      ),
      GoRoute(
        path: '/admin/teacher-register-applies',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TeacherRegisterAuditPage()),
      ),
      GoRoute(
        path: '/admin/operations',
        redirect: (context, state) => '/admin/statistics',
      ),
      GoRoute(
        path: '/admin/notices',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AdminShellPage(initialIndex: 2)),
      ),
      GoRoute(
        path: '/admin/profile',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AdminShellPage(initialIndex: 3)),
      ),
      GoRoute(
        path: '/:pathMatch(.*)*',
        redirect: (context, state) {
          if (!authController.isAuthenticated) {
            return '/login';
          }
          return resolvePortalHome(resolvePortalType(authController.profile));
        },
      ),
    ],
  );
});
