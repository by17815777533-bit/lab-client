# Backend Integration Map

本文用于记录 Flutter 客户端与后端仓库的对接状态，作为后续补全功能的统一参照。

## 已完成接入

### 认证与个人中心

| 模块 | Flutter 入口 | 后端接口 |
| --- | --- | --- |
| 登录 | `lib/src/features/auth/login_page.dart` | `POST /api/auth/login` |
| 退出登录 | `lib/src/features/settings/settings_page.dart` | `POST /api/user/logout` |
| 登录态恢复与资料拉取 | `lib/src/features/auth/auth_controller.dart` | `GET /api/access/profile` |
| 个人资料 | `lib/src/features/profile/profile_page.dart` | `GET /api/user/info` |
| 头像更新 | `lib/src/features/profile/profile_page.dart` | `PUT /api/user/avatar` |
| 资料更新 | `lib/src/features/profile/profile_page.dart` | `PUT /api/user/info` |
| 密码修改 | `lib/src/features/settings/settings_page.dart` | `PUT /api/user/password` |
| 文件上传 | `lib/src/repositories/profile_repository.dart` | `POST /api/file/upload` |
| 文件预览 | `lib/src/core/utils/file_url_resolver.dart` | `GET /api/file/view` |

### 学生端

| 模块 | Flutter 入口 | 后端接口 |
| --- | --- | --- |
| 设备借用 | `lib/src/features/equipment/equipment_page.dart` | `GET /api/equipment/list`，`POST /api/equipment/borrow`，`GET /api/equipment/borrow/my` |
| 工作台概览 | `lib/src/features/dashboard/dashboard_page.dart` | `GET /api/recruit-plans/active`，`GET /api/notices/latest`，`GET /api/lab-applies/my`，`GET /api/labs/stats` |
| 实验室列表与详情 | `lib/src/features/labs/labs_page.dart` | `GET /api/labs/list`，`GET /api/labs/{id}`，`GET /api/graduate/list` |
| 学生入组申请 | `lib/src/features/labs/labs_page.dart`，`lib/src/features/applications/applications_page.dart` | `POST /api/lab-applies`，`GET /api/lab-applies/my` |
| 方向指南 | `lib/src/features/path_guide/path_guide_page.dart` | `GET /api/guide/options` |
| 成长中心测评与推荐 | `lib/src/features/growth_center/growth_center_page.dart` | `GET /api/growth-center/dashboard`，`GET /api/growth-center/assessment/questions`，`POST /api/growth-center/assessment/submit`，`GET /api/growth-center/tracks`，`GET /api/growth-center/tracks/{code}` |
| 成长中心练习题库 | `lib/src/features/growth_center/growth_practice_page.dart` | `GET /api/growth-center/practice/questions`，`GET /api/growth-center/practice/questions/{questionId}`，`POST /api/growth-center/practice/submit` |
| 智能练习 | `lib/src/features/gradpath/gradpath_page.dart` | `GET /api/gradpath/config`，`GET /api/gradpath/questions`，`GET /api/gradpath/questions/{questionId}`，`POST /api/gradpath/questions/generate`，`POST /api/gradpath/judge/debug`，`POST /api/gradpath/judge/submit`，`POST /api/gradpath/judge/analyze` |
| 正式笔试 | `lib/src/features/written_exam/written_exam_page.dart` | `GET /api/written-exam/student/labs`，`GET /api/written-exam/student/exam/{labId}`，`GET /api/written-exam/student/submission/{labId}`，`POST /api/written-exam/student/submit`，`GET /api/written-exam/student/notifications`，`POST /api/written-exam/student/notifications/read/{notificationId}` |
| 交流论坛 | `lib/src/features/forum/forum_page.dart`，`lib/src/features/forum/forum_post_detail_page.dart` | `GET /api/forum/post/list`，`GET /api/forum/post/{id}`，`POST /api/forum/post/add`，`DELETE /api/forum/post/{id}`，`PUT /api/forum/post/{id}/pin`，`PUT /api/forum/post/{id}/essence`，`GET /api/forum/comment/list`，`POST /api/forum/comment/add`，`DELETE /api/forum/comment/{id}`，`POST /api/forum/post/{id}/like` |
| 公告浏览 | `lib/src/features/notices/notices_page.dart` | `GET /api/notices`，`GET /api/notices/latest` |
| 我的实验室 | `lib/src/features/workspace/workspace_page.dart` | `GET /api/lab-space/overview`，`GET /api/lab-members/active`，`GET /api/lab-space/attendance/summary`，`GET /api/lab-space/attendance/my`，`GET /api/lab-space/folders`，`GET /api/lab-space/files`，`POST /api/lab-space/attendance/sign-in`，`POST /api/lab-space/files/upload` |
| 资料空间补充能力 | `lib/src/features/workspace/workspace_page.dart` | `GET /api/lab-space/files/recent` |
| 学生考勤工作流 | `lib/src/features/attendance/attendance_page.dart` | `GET /api/attendance-workflow/student/session/current`，`POST /api/attendance-workflow/student/session/sign-in`，`POST /api/attendance-workflow/student/session/makeup`，`GET /api/attendance-workflow/student/history` |
| 退出实验室申请 | `lib/src/features/exit_application/exit_application_page.dart` | `POST /api/lab-space/exit-application`，`GET /api/lab-space/exit-application/my` |

### 教师端

| 模块 | Flutter 入口 | 后端接口 |
| --- | --- | --- |
| 教师工作台 | `lib/src/features/dashboard/dashboard_page.dart` | `GET /api/recruit-plans/active`，`GET /api/notices/latest`，`GET /api/labs/stats` |
| 实验室创建申请 | `lib/src/features/lab_create_apply/lab_create_apply_page.dart` | `POST /api/lab-create-applies`，`GET /api/colleges/options` |
| 教师实验室空间 | `lib/src/features/workspace/workspace_page.dart` | `GET /api/lab-space/overview`，`GET /api/lab-space/folders`，`GET /api/lab-space/files`，`GET /api/lab-space/files/recent`，`GET /api/lab-space/attendance/daily` |
| 教师考勤工作台 | `lib/src/features/attendance_management/attendance_management_page.dart` | `GET /api/attendance-workflow/lab/session/current` |
| 公告浏览 | `lib/src/features/notices/notices_page.dart` | `GET /api/notices`，`GET /api/notices/latest` |

### 管理端

| 模块 | Flutter 入口 | 后端接口 |
| --- | --- | --- |
| 管理工作台 | `lib/src/features/dashboard/dashboard_page.dart` | `GET /api/labs/stats`，`GET /api/notices/latest`，`GET /api/recruit-plans/active` |
| 统计工作台 | `lib/src/features/statistics/statistics_page.dart` | `GET /api/statistics/overview`，`GET /api/statistics/lab/{labId}` |
| 管理员账号 | `lib/src/features/admin_accounts/admin_accounts_page.dart` | `GET /api/admin/list`，`POST /api/user/admin/add`，`PUT /api/user/admin/{id}`，`DELETE /api/user/admin/{id}` |
| 管理员分配 | `lib/src/features/admin_management/admin_management_page.dart` | `GET /api/labs/list-with-admin`，`GET /api/user/student/list`，`POST /api/admin-management/assign`，`DELETE /api/admin-management/remove/{labId}` |
| 学生管理 | `lib/src/features/student_management/student_management_page.dart` | `GET /api/admin/users`，`DELETE /api/admin/users/{id}` |
| 投递管理 | `lib/src/features/delivery_management/delivery_management_page.dart` | `GET /api/delivery/list`，`POST /api/delivery/audit/{deliveryId}`，`POST /api/delivery/admit/{deliveryId}` |
| 最近申请动态 | `lib/src/features/statistics/statistics_page.dart` | `GET /api/lab-applies/latest` |
| 招新计划 | `lib/src/features/recruit_plan_management/recruit_plan_management_page.dart` | `GET /api/recruit-plans`，`POST /api/recruit-plans`，`PUT /api/recruit-plans/{id}`，`DELETE /api/recruit-plans/{id}` |
| 考勤工作台 | `lib/src/features/attendance_management/attendance_management_page.dart` | `GET /api/attendance-workflow/tasks`，`POST /api/attendance-workflow/tasks`，`POST /api/attendance-workflow/tasks/{taskId}/publish`，`GET /api/attendance-workflow/tasks/{taskId}/schedules`，`POST /api/attendance-workflow/tasks/{taskId}/schedules`，`GET /api/attendance-workflow/summary`，`GET /api/attendance-workflow/lab/session/current`，`POST /api/attendance-workflow/lab/records/review`，`POST /api/attendance-workflow/lab/session/current/photo`，`POST /api/attendance-workflow/duty/sessions/{sessionId}` |
| 空间工作台 | `lib/src/features/workspace/workspace_page.dart` | `GET /api/lab-space/overview`，`GET /api/lab-space/folders`，`GET /api/lab-space/files`，`GET /api/lab-space/files/recent`，`POST /api/lab-space/files/{id}/archive`，`GET /api/lab-space/attendance/daily`，`POST /api/lab-space/attendance/confirm` |
| 实验室信息维护 | `lib/src/features/lab_info_management/lab_info_management_page.dart` | `GET /api/labs/{id}`，`PUT /api/labs/update-info` |
| 设备管理与借用审核 | `lib/src/features/equipment_admin/equipment_admin_page.dart` | `GET /api/equipment/list`，`POST /api/equipment/add`，`PUT /api/equipment/update`，`DELETE /api/equipment/{id}`，`GET /api/equipment/borrow/list`，`POST /api/equipment/borrow/audit`，`POST /api/equipment/borrow/return` |
| 优秀毕业生维护 | `lib/src/features/graduate_management/graduate_management_page.dart` | `GET /api/graduate/list`，`POST /api/graduate/add`，`PUT /api/graduate/update`，`DELETE /api/graduate/{id}` |
| 共享题库维护 | `lib/src/features/growth_question_bank/growth_question_bank_page.dart` | `GET /api/growth-center/admin/question-bank`，`GET /api/growth-center/admin/question-bank/{questionId}`，`POST /api/growth-center/admin/question-bank`，`POST /api/growth-center/admin/question-bank/delete/{questionId}` |
| 正式笔试配置与审核 | `lib/src/features/written_exam_management/written_exam_management_page.dart` | `GET /api/written-exam/admin/config`，`POST /api/written-exam/admin/config`，`GET /api/written-exam/admin/submissions`，`POST /api/written-exam/admin/review` |
| 成员申请审核 | `lib/src/features/lab_apply_audit/lab_apply_audit_page.dart` | `GET /api/lab-applies`，`POST /api/lab-applies/{id}/audit` |
| 教师注册审核 | `lib/src/features/teacher_register_audit/teacher_register_audit_page.dart` | `GET /api/teacher-register-applies`，`POST /api/teacher-register-applies/{id}/audit` |
| 退出实验室审核 | `lib/src/features/exit_audit/exit_audit_page.dart` | `GET /api/lab-space/exit-application/list`，`POST /api/lab-space/exit-application/audit` |
| 公告浏览 | `lib/src/features/notices/notices_page.dart` | `GET /api/notices`，`GET /api/notices/latest` |

## 后端已存在但 Flutter 仍未完整接入

以下接口在后端仓库中已经存在，但当前 Flutter 客户端还没有完整页面、入口或交互闭环。

### 管理与审批

| 后端模块 | 接口 |
| --- | --- |
| 实验室管理员分配 | `POST /api/admin-management/assign`，`DELETE /api/admin-management/remove/{labId}`，`GET /api/admin-management/lab/{labId}`，`GET /api/admin-management/all`，`GET /api/admin-management/can-be-admin/{userId}` |

### 资源与设备

| 后端模块 | 接口 |
| --- | --- |

### 内容与社区

| 后端模块 | 接口 |
| --- | --- |

## 建议的下一步接入顺序

1. 管理员管理深层接口，补齐实验室管理员分配详情页和候选人视图。
2. 继续完善管理链路上的剩余细节入口和闭环。
3. 跟进后端数据库初始化，把成长中心、论坛、笔试相关缺表问题补齐。

## 说明

- 本文只记录后端仓库中已经确认存在的接口，不包含推测接口。
- 已接入模块不代表所有角色入口都已做完，部分能力仍需要在门户层补入口。
- 后续补功能时，优先沿用当前的 `repository -> controller -> page` 结构，不要把新接口直接散落到页面里。
- `GET /api/attendance-workflow/lab/session/current/records` 在当前服务上存在重复会话异常，客户端统一使用 `GET /api/attendance-workflow/lab/session/current` 返回的 `records` 字段展示成员签到。
- 截至 `2026-04-07`，公网服务上的成长中心、论坛与正式笔试相关库表仍存在缺失情况。客户端页面、路由和交互已全部接入，但在服务端缺表时会统一显示业务化提示，不直接暴露内部异常信息。
