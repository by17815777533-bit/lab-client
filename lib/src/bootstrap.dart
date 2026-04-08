import 'package:flutter/foundation.dart';

import 'core/network/api_client.dart';
import 'core/storage/session_storage.dart';
import 'features/auth/auth_controller.dart';
import 'features/settings/app_settings_controller.dart';
import 'repositories/application_repository.dart';
import 'repositories/admin_management_repository.dart';
import 'repositories/attendance_workflow_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/delivery_repository.dart';
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
import 'repositories/student_management_repository.dart';
import 'repositories/teacher_register_audit_repository.dart';
import 'repositories/written_exam_repository.dart';

class AppBootstrap {
  AppBootstrap({
    required this.storage,
    required this.settingsController,
    required this.authController,
    required this.authRepository,
    required this.profileRepository,
    required this.labRepository,
    required this.labSpaceRepository,
    required this.planRepository,
    required this.noticeRepository,
    required this.applicationRepository,
    required this.adminManagementRepository,
    required this.studentManagementRepository,
    required this.deliveryRepository,
    required this.guideRepository,
    required this.graduateRepository,
    required this.growthCenterRepository,
    required this.attendanceWorkflowRepository,
    required this.equipmentRepository,
    required this.labExitApplicationRepository,
    required this.exitAuditRepository,
    required this.labApplyAuditRepository,
    required this.statisticsRepository,
    required this.teacherRegisterAuditRepository,
    required this.forumRepository,
    required this.gradPathRepository,
    required this.writtenExamRepository,
  });

  final SessionStorage storage;
  final AppSettingsController settingsController;
  final AuthController authController;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final LabRepository labRepository;
  final LabSpaceRepository labSpaceRepository;
  final PlanRepository planRepository;
  final NoticeRepository noticeRepository;
  final ApplicationRepository applicationRepository;
  final AdminManagementRepository adminManagementRepository;
  final StudentManagementRepository studentManagementRepository;
  final DeliveryRepository deliveryRepository;
  final GuideRepository guideRepository;
  final GraduateRepository graduateRepository;
  final GrowthCenterRepository growthCenterRepository;
  final AttendanceWorkflowRepository attendanceWorkflowRepository;
  final EquipmentRepository equipmentRepository;
  final LabExitApplicationRepository labExitApplicationRepository;
  final ExitAuditRepository exitAuditRepository;
  final LabApplyAuditRepository labApplyAuditRepository;
  final StatisticsRepository statisticsRepository;
  final TeacherRegisterAuditRepository teacherRegisterAuditRepository;
  final ForumRepository forumRepository;
  final GradPathRepository gradPathRepository;
  final WrittenExamRepository writtenExamRepository;

  static Future<AppBootstrap> create() async {
    final storage = await SessionStorage.create();
    final settingsController = AppSettingsController(storage);
    final apiClient = ApiClient(
      storage: storage,
      settingsController: settingsController,
    );

    final authRepository = AuthRepository(apiClient);
    final profileRepository = ProfileRepository(apiClient);
    final labRepository = LabRepository(apiClient);
    final labSpaceRepository = LabSpaceRepository(apiClient);
    final planRepository = PlanRepository(apiClient);
    final noticeRepository = NoticeRepository(apiClient);
    final applicationRepository = ApplicationRepository(apiClient);
    final adminManagementRepository = AdminManagementRepository(apiClient);
    final studentManagementRepository = StudentManagementRepository(apiClient);
    final deliveryRepository = DeliveryRepository(apiClient);
    final guideRepository = GuideRepository(apiClient);
    final graduateRepository = GraduateRepository(apiClient);
    final growthCenterRepository = GrowthCenterRepository(apiClient);
    final attendanceWorkflowRepository = AttendanceWorkflowRepository(
      apiClient,
    );
    final equipmentRepository = EquipmentRepository(apiClient);
    final labExitApplicationRepository = LabExitApplicationRepository(
      apiClient,
    );
    final exitAuditRepository = ExitAuditRepository(apiClient);
    final labApplyAuditRepository = LabApplyAuditRepository(apiClient);
    final statisticsRepository = StatisticsRepository(apiClient);
    final teacherRegisterAuditRepository = TeacherRegisterAuditRepository(
      apiClient,
    );
    final forumRepository = ForumRepository(apiClient);
    final gradPathRepository = GradPathRepository(apiClient);
    final writtenExamRepository = WrittenExamRepository(apiClient);

    final authController = AuthController(
      storage: storage,
      authRepository: authRepository,
      profileRepository: profileRepository,
    );

    await authController.initialize();

    return AppBootstrap(
      storage: storage,
      settingsController: settingsController,
      authController: authController,
      authRepository: authRepository,
      profileRepository: profileRepository,
      labRepository: labRepository,
      labSpaceRepository: labSpaceRepository,
      planRepository: planRepository,
      noticeRepository: noticeRepository,
      applicationRepository: applicationRepository,
      adminManagementRepository: adminManagementRepository,
      studentManagementRepository: studentManagementRepository,
      deliveryRepository: deliveryRepository,
      guideRepository: guideRepository,
      graduateRepository: graduateRepository,
      growthCenterRepository: growthCenterRepository,
      attendanceWorkflowRepository: attendanceWorkflowRepository,
      equipmentRepository: equipmentRepository,
      labExitApplicationRepository: labExitApplicationRepository,
      exitAuditRepository: exitAuditRepository,
      labApplyAuditRepository: labApplyAuditRepository,
      statisticsRepository: statisticsRepository,
      teacherRegisterAuditRepository: teacherRegisterAuditRepository,
      forumRepository: forumRepository,
      gradPathRepository: gradPathRepository,
      writtenExamRepository: writtenExamRepository,
    );
  }

  @visibleForTesting
  ApiClient createTestClient() =>
      ApiClient(storage: storage, settingsController: settingsController);
}
