import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap.dart';
import '../features/auth/auth_controller.dart';
import '../features/settings/app_settings_controller.dart';
import '../repositories/application_repository.dart';
import '../repositories/admin_management_repository.dart';
import '../repositories/attendance_workflow_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/delivery_repository.dart';
import '../repositories/equipment_repository.dart';
import '../repositories/exit_audit_repository.dart';
import '../repositories/forum_repository.dart';
import '../repositories/gradpath_repository.dart';
import '../repositories/graduate_repository.dart';
import '../repositories/growth_center_repository.dart';
import '../repositories/guide_repository.dart';
import '../repositories/lab_apply_audit_repository.dart';
import '../repositories/lab_exit_application_repository.dart';
import '../repositories/lab_repository.dart';
import '../repositories/lab_space_repository.dart';
import '../repositories/notice_repository.dart';
import '../repositories/plan_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/statistics_repository.dart';
import '../repositories/student_management_repository.dart';
import '../repositories/teacher_register_audit_repository.dart';
import '../repositories/written_exam_repository.dart';

final appBootstrapProvider = Provider<AppBootstrap>(
  (ref) => throw UnimplementedError('App bootstrap is not available.'),
);

final appSettingsControllerProvider =
    ChangeNotifierProvider<AppSettingsController>((ref) {
      return ref.read(appBootstrapProvider).settingsController;
    });

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return ref.read(appBootstrapProvider).authController;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.read(appBootstrapProvider).authRepository;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ref.read(appBootstrapProvider).profileRepository;
});

final labRepositoryProvider = Provider<LabRepository>((ref) {
  return ref.read(appBootstrapProvider).labRepository;
});

final labSpaceRepositoryProvider = Provider<LabSpaceRepository>((ref) {
  return ref.read(appBootstrapProvider).labSpaceRepository;
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return ref.read(appBootstrapProvider).planRepository;
});

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return ref.read(appBootstrapProvider).noticeRepository;
});

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ref.read(appBootstrapProvider).applicationRepository;
});

final adminManagementRepositoryProvider = Provider<AdminManagementRepository>((
  ref,
) {
  return ref.read(appBootstrapProvider).adminManagementRepository;
});

final studentManagementRepositoryProvider =
    Provider<StudentManagementRepository>((ref) {
      return ref.read(appBootstrapProvider).studentManagementRepository;
    });

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return ref.read(appBootstrapProvider).deliveryRepository;
});

final guideRepositoryProvider = Provider<GuideRepository>((ref) {
  return ref.read(appBootstrapProvider).guideRepository;
});

final graduateRepositoryProvider = Provider<GraduateRepository>((ref) {
  return ref.read(appBootstrapProvider).graduateRepository;
});

final growthCenterRepositoryProvider = Provider<GrowthCenterRepository>((ref) {
  return ref.read(appBootstrapProvider).growthCenterRepository;
});

final attendanceWorkflowRepositoryProvider =
    Provider<AttendanceWorkflowRepository>((ref) {
      return ref.read(appBootstrapProvider).attendanceWorkflowRepository;
    });

final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) {
  return ref.read(appBootstrapProvider).equipmentRepository;
});

final labExitApplicationRepositoryProvider =
    Provider<LabExitApplicationRepository>((ref) {
      return ref.read(appBootstrapProvider).labExitApplicationRepository;
    });

final exitAuditRepositoryProvider = Provider<ExitAuditRepository>((ref) {
  return ref.read(appBootstrapProvider).exitAuditRepository;
});

final labApplyAuditRepositoryProvider = Provider<LabApplyAuditRepository>((
  ref,
) {
  return ref.read(appBootstrapProvider).labApplyAuditRepository;
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return ref.read(appBootstrapProvider).statisticsRepository;
});

final teacherRegisterAuditRepositoryProvider =
    Provider<TeacherRegisterAuditRepository>((ref) {
      return ref.read(appBootstrapProvider).teacherRegisterAuditRepository;
    });

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ref.read(appBootstrapProvider).forumRepository;
});

final gradPathRepositoryProvider = Provider<GradPathRepository>((ref) {
  return ref.read(appBootstrapProvider).gradPathRepository;
});

final writtenExamRepositoryProvider = Provider<WrittenExamRepository>((ref) {
  return ref.read(appBootstrapProvider).writtenExamRepository;
});
