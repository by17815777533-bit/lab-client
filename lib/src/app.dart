import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;

import 'app/providers.dart';
import 'app/router/app_router.dart';
import 'bootstrap.dart';
import 'core/config/app_environment.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_logo.dart';
import 'features/auth/auth_controller.dart';
import 'features/settings/app_settings_controller.dart';
import 'repositories/application_repository.dart';
import 'repositories/admin_management_repository.dart';
import 'repositories/attendance_workflow_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/equipment_repository.dart';
import 'repositories/exit_audit_repository.dart';
import 'repositories/forum_repository.dart';
import 'repositories/gradpath_repository.dart';
import 'repositories/graduate_repository.dart';
import 'repositories/growth_center_repository.dart';
import 'repositories/guide_repository.dart';
import 'repositories/lab_apply_audit_repository.dart';
import 'repositories/lab_exit_application_repository.dart';
import 'repositories/lab_repository.dart';
import 'repositories/lab_space_repository.dart';
import 'repositories/notice_repository.dart';
import 'repositories/plan_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/statistics_repository.dart';
import 'repositories/teacher_register_audit_repository.dart';
import 'repositories/written_exam_repository.dart';

class LabClientApp extends StatelessWidget {
  const LabClientApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: <Override>[appBootstrapProvider.overrideWithValue(bootstrap)],
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.ChangeNotifierProvider<AppSettingsController>.value(
            value: bootstrap.settingsController,
          ),
          legacy_provider.ChangeNotifierProvider<AuthController>.value(
            value: bootstrap.authController,
          ),
          legacy_provider.Provider<AuthRepository>.value(
            value: bootstrap.authRepository,
          ),
          legacy_provider.Provider<ProfileRepository>.value(
            value: bootstrap.profileRepository,
          ),
          legacy_provider.Provider<LabRepository>.value(
            value: bootstrap.labRepository,
          ),
          legacy_provider.Provider<LabSpaceRepository>.value(
            value: bootstrap.labSpaceRepository,
          ),
          legacy_provider.Provider<PlanRepository>.value(
            value: bootstrap.planRepository,
          ),
          legacy_provider.Provider<NoticeRepository>.value(
            value: bootstrap.noticeRepository,
          ),
          legacy_provider.Provider<ApplicationRepository>.value(
            value: bootstrap.applicationRepository,
          ),
          legacy_provider.Provider<AdminManagementRepository>.value(
            value: bootstrap.adminManagementRepository,
          ),
          legacy_provider.Provider<AttendanceWorkflowRepository>.value(
            value: bootstrap.attendanceWorkflowRepository,
          ),
          legacy_provider.Provider<GuideRepository>.value(
            value: bootstrap.guideRepository,
          ),
          legacy_provider.Provider<GraduateRepository>.value(
            value: bootstrap.graduateRepository,
          ),
          legacy_provider.Provider<GrowthCenterRepository>.value(
            value: bootstrap.growthCenterRepository,
          ),
          legacy_provider.Provider<EquipmentRepository>.value(
            value: bootstrap.equipmentRepository,
          ),
          legacy_provider.Provider<LabExitApplicationRepository>.value(
            value: bootstrap.labExitApplicationRepository,
          ),
          legacy_provider.Provider<ExitAuditRepository>.value(
            value: bootstrap.exitAuditRepository,
          ),
          legacy_provider.Provider<LabApplyAuditRepository>.value(
            value: bootstrap.labApplyAuditRepository,
          ),
          legacy_provider.Provider<StatisticsRepository>.value(
            value: bootstrap.statisticsRepository,
          ),
          legacy_provider.Provider<TeacherRegisterAuditRepository>.value(
            value: bootstrap.teacherRegisterAuditRepository,
          ),
          legacy_provider.Provider<ForumRepository>.value(
            value: bootstrap.forumRepository,
          ),
          legacy_provider.Provider<GradPathRepository>.value(
            value: bootstrap.gradPathRepository,
          ),
          legacy_provider.Provider<WrittenExamRepository>.value(
            value: bootstrap.writtenExamRepository,
          ),
        ],
        child: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (auth.initializing) {
      return const _BootPage();
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppEnvironment.appName,
      theme: AppTheme.build(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

class _BootPage extends StatelessWidget {
  const _BootPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF2D78FF), Color(0xFFEDF4FF)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppLogo(size: 72, tone: AppLogoTone.light, showText: true),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
