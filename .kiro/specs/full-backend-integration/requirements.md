# Requirements Document

## Introduction

本需求文档以仓库内后端代码和原 Web 端实现为唯一事实来源，定义 Flutter 客户端“全量对接后端”的真实范围。

目标不是只补齐当前 5 个底部标签页，而是交付一个跨平台、多角色、无开发痕迹的正式客户端，覆盖后端已提供的全部核心业务能力，并与现有 Spring Boot API 保持同源对接。

事实基线：

- 后端控制器位于 `/tmp/LabLink/lab/src/main/java/com/lab/recruitment/controller`
- 原 Web 端 API 封装位于 `/tmp/LabLink/lab/frontend/src/api`
- 原 Web 端角色路由位于 `/tmp/LabLink/lab/frontend/src/router/index.js`
- 当前 Flutter 已接入的仅是认证、个人资料、实验室总览、招新计划、公告、申请和部分实验室空间模型，不构成“全量对接”

当前扫描结果表明，后端真实存在的业务范围至少包括：

- 公共访问与身份认证
- 学生端工作台、实验室浏览、招新申请、我的实验室、考勤、资料空间
- 学生端投递、设备借用、成长中心、毕业去向题库、笔试、论坛
- 教师端工作台、实验室创建申请、实验室工作台
- 管理端工作台、学院管理、实验室管理、管理员分配、成员管理、公告管理、统计分析、考勤任务、实验室创建审批、教师注册审批
- 文件上传与受保护资源访问

同时也确认，当前后端仓库中没有与截图中“生物信息采集”“我收藏的”“我反馈的”严格对应的业务控制器，因此这些入口不能伪装成已完成的后端对接功能。

## Backend Module Inventory

### Public And Shared Modules

- `AuthController`
  - 注册、登录、学生邮箱验证码、教师注册验证码、教师注册、密码重置
- `AccessProfileController`
  - 当前用户统一访问画像
- `UserController`
  - 个人信息、头像、密码、登出、管理员管理、学生列表
- `CollegeController`
  - 学院分页与学院选项
- `LabController`
  - 实验室列表、统计、详情、管理、管理员绑定辅助列表
- `NoticeController`
  - 公告分页、最新公告、公告管理
- `FileUploadController`
  - 通用文件上传、公共文件访问

### Student-Facing Modules

- `RecruitPlanController`
  - 活跃招新计划
- `LabApplyController`
  - 申请加入实验室、我的申请、管理员审核、最新申请
- `LabMemberController`
  - 成员分页、活跃成员、任命负责人、移除成员
- `LabSpaceController`
  - 我的实验室概览、日常考勤、考勤确认、我的考勤、考勤汇总、签到、文件夹、文件、最近文件、上传文件、归档、退出实验室申请
- `AttendanceWorkflowController`
  - 学生当前考勤会话、签到、补签、历史记录
- `DeliveryController`
  - 学生投递、撤回、我的投递、offer 汇总、确认 offer、拒绝 offer
- `EquipmentController`
  - 设备列表、借用、我的借用
- `GrowthCenterController`
  - 成长中心总览、测评、发展方向、练习题、学生答题
- `GradPathController`
  - 毕业去向编程题、代码调试、提交、分析、考试完成
- `WrittenExamController`
  - 学生笔试实验室列表、试卷详情、提交记录、提交答卷、通知已读
- `GuideController`
  - 新生指南选项
- `ForumController`
  - 帖子、评论、点赞

### Teacher-Facing Modules

- `LabCreateApplyController`
  - 实验室创建申请发起、分页查询
- `AttendanceWorkflowController`
  - 当前实验室考勤会话、当前会话记录
- `LabSpaceController`
  - 实验室概览、日常考勤、资料空间、最近文件、文件查询
- `NoticeController`
  - 公告阅读
- `AccessProfileController` / `UserController`
  - 个人资料维护

### Admin And Super Admin Modules

- `StatisticsController`
  - 总览统计、实验室维度统计
- `AdminController`
  - 学生分页、管理员分页、删除用户
- `AdminManagementController`
  - 为实验室分配管理员、移除管理员、实验室管理员查询、管理员与实验室关系查询
- `CollegeController`
  - 学院增删改查
- `LabController`
  - 实验室增删改查、更新本实验室信息、查询带管理员实验室
- `LabCreateApplyController`
  - 实验室创建审批
- `TeacherRegisterApplyController`
  - 教师注册审批
- `RecruitPlanController`
  - 招新计划增删改查
- `LabApplyController`
  - 成员申请审核、最新申请
- `LabMemberController`
  - 成员分页、任命负责人、移除成员
- `NoticeController`
  - 公告增删改查
- `AttendanceWorkflowController`
  - 考勤任务、班次、发布、汇总、审核、上传考勤照片、值日安排
- `AttendancePhotoAccessController`
  - 受保护考勤照片查看
- `LabSpaceController`
  - 日常考勤确认、资料文件夹维护、文件归档、退出申请审核
- `DeliveryController`
  - 投递列表、审核、录取、统计
- `EquipmentController`
  - 设备维护、借用审核、归还
- `GrowthCenterController`
  - 管理端成长题库
- `WrittenExamController`
  - 管理端笔试配置、答卷审核
- `OutstandingGraduateController`
  - 优秀毕业生管理

## Current Flutter Coverage Assessment

当前 Flutter 客户端已具备以下基础：

- 登录态恢复与统一 API Client
- 个人资料读取、头像上传、简历上传、资料修改、密码修改
- 实验室列表、实验室详情基础展示
- 招新计划列表
- 公告分页
- 学生申请列表与创建申请基础能力
- 部分 `lab-space` 相关模型与仓库

当前明显缺口：

- 没有真正的多角色门户，教师端与管理员端没有完整信息架构
- 学生端“我的实验室 / 考勤 / 资料空间 / 投递 / 设备 / 成长 / 毕业去向 / 笔试 / 论坛”未完整接通
- 管理端“学院 / 实验室 / 审批 / 成员 / 公告 / 统计 / 考勤任务 / 设备 / 题库 / 优秀毕业生”未落 Flutter 页面
- 文件与受保护资源访问、复杂分页筛选、管理动作弹窗、审核流还没有统一交互规范
- 当前 UI 仍存在测试期入口和占位行为，不符合“无开发痕迹”

## Requirements

### Requirement 1

**User Story:** 作为平台用户，我希望 Flutter 客户端根据我的真实身份进入对应门户，这样我在手机、平板、桌面和 Web 上都能直接使用与 Web 端一致的业务能力。

#### Acceptance Criteria

1. WHEN 用户登录成功 THEN 客户端 SHALL 以 `/api/access/profile` 为准解析用户身份、主角色、实验室归属和权限标签。
2. WHEN 用户是 `student` THEN 客户端 SHALL 进入学生门户并展示学生可访问的全部业务入口。
3. WHEN 用户是 `teacher` THEN 客户端 SHALL 进入教师门户并展示教师可访问的全部业务入口。
4. WHEN 用户是 `admin` 或 `super_admin` THEN 客户端 SHALL 进入管理门户并展示对应管理能力，且不得暴露越权操作入口。
5. IF 登录态失效或接口返回鉴权错误 THEN 客户端 SHALL 清理会话并回到登录页。

### Requirement 2

**User Story:** 作为访客或新用户，我希望客户端完整支持登录、注册、教师注册和密码找回，这样我不需要回到 Web 端完成基础身份流程。

#### Acceptance Criteria

1. WHEN 用户进入客户端 THEN 系统 SHALL 提供登录、学生注册、教师注册和密码重置入口。
2. WHEN 用户发起学生注册 THEN 系统 SHALL 对接 `/api/auth/register/send-code` 与 `/api/auth/register`。
3. WHEN 用户发起教师注册 THEN 系统 SHALL 对接 `/api/auth/teacher-register/send-code` 与 `/api/auth/teacher-register`。
4. WHEN 用户找回密码 THEN 系统 SHALL 对接 `/api/auth/password-reset/send-code` 与 `/api/auth/password-reset/confirm`。
5. WHERE 表单字段存在后端校验规则 系统 SHALL 在客户端做同步校验并展示可理解的错误文案。

### Requirement 3

**User Story:** 作为任何已登录用户，我希望个人资料、头像、简历和密码都能在客户端直接维护，这样我的账号主数据在移动端是完整可用的。

#### Acceptance Criteria

1. WHEN 用户进入个人中心 THEN 系统 SHALL 展示 `/api/access/profile` 返回的完整档案字段。
2. WHEN 用户修改头像 THEN 系统 SHALL 先对接文件上传接口，再调用个人资料更新接口完成头像保存。
3. WHEN 用户上传简历 THEN 系统 SHALL 通过后端文件接口上传并在个人资料中保存简历地址。
4. WHEN 用户修改姓名、邮箱、专业等字段 THEN 系统 SHALL 调用后端资料更新接口并刷新本地会话缓存。
5. WHEN 用户修改密码 THEN 系统 SHALL 调用后端密码更新接口并按结果反馈。

### Requirement 4

**User Story:** 作为学生，我希望实验室浏览、招新计划、投递申请和加入流程都能在客户端完整走通，这样我不需要在 Web 端和移动端之间来回切换。

#### Acceptance Criteria

1. WHEN 学生浏览实验室 THEN 系统 SHALL 对接实验室列表、实验室详情和实验室统计接口。
2. WHEN 学生查看可报名计划 THEN 系统 SHALL 对接活跃招新计划接口并按实验室维度展示。
3. WHEN 学生提交加入申请 THEN 系统 SHALL 对接实验室申请创建接口并支持申请前表单校验。
4. WHEN 学生查看我的申请 THEN 系统 SHALL 对接我的申请分页接口并展示审核状态和时间线。
5. WHEN 管理端审核申请后状态发生变化 THEN 系统 SHALL 在学生端刷新后呈现最新结果。

### Requirement 5

**User Story:** 作为实验室成员学生，我希望“我的实验室”“考勤记录”“资料空间”“退出实验室申请”都能完整可用，这样核心在组学习流程可以在客户端闭环。

#### Acceptance Criteria

1. WHEN 学生进入“我的实验室” THEN 系统 SHALL 对接 `/api/lab-space/overview`、`/api/lab-members/active`、`/api/lab-space/files/recent` 与考勤汇总接口。
2. WHEN 学生查看考勤 THEN 系统 SHALL 同时支持 `lab-space` 历史考勤与 `attendance-workflow` 当前会话/历史记录能力。
3. WHEN 学生满足签到条件 THEN 系统 SHALL 支持签到、补签申请及结果反馈。
4. WHEN 学生进入资料空间 THEN 系统 SHALL 展示文件夹树、文件分页、最近文件、文件预览和上传能力。
5. WHEN 学生提交退出实验室申请 THEN 系统 SHALL 对接退出申请创建与我的退出申请分页接口。

### Requirement 6

**User Story:** 作为学生，我希望成长、投递、设备、笔试、毕业去向和论坛等扩展模块也能完整使用，这样客户端才算真正覆盖后端学生业务。

#### Acceptance Criteria

1. WHEN 学生进入投递模块 THEN 系统 SHALL 对接投递、撤回、我的投递、offer 汇总、确认 offer 和拒绝 offer 接口。
2. WHEN 学生进入设备借用模块 THEN 系统 SHALL 对接设备列表、借用申请和我的借用记录接口。
3. WHEN 学生进入成长中心 THEN 系统 SHALL 对接成长测评、赛道、练习题和答题接口。
4. WHEN 学生进入毕业去向与笔试模块 THEN 系统 SHALL 对接 `gradpath` 与 `written-exam/student/*` 全部接口。
5. WHEN 学生进入论坛或新生指南 THEN 系统 SHALL 对接帖子、评论、点赞与指南选项接口。

### Requirement 7

**User Story:** 作为教师，我希望教师门户能覆盖工作台、实验室创建申请、实验室工作台和公告等功能，这样教师不需要再回 Web 端操作。

#### Acceptance Criteria

1. WHEN 教师登录 THEN 系统 SHALL 呈现教师专属门户，而不是复用学生门户伪装。
2. WHEN 教师进入实验室创建申请 THEN 系统 SHALL 对接创建申请提交与分页查询接口。
3. WHEN 教师进入实验室工作台 THEN 系统 SHALL 对接实验室概览、日考勤、资料空间、当前会话记录等教师可访问接口。
4. WHEN 教师查看公告和个人资料 THEN 系统 SHALL 使用与后端权限一致的共享能力。
5. WHERE 教师无权执行的管理动作存在 THEN 系统 SHALL 不展示对应交互。

### Requirement 8

**User Story:** 作为管理员或超级管理员，我希望 Flutter 客户端完整支持审批、成员管理、实验室管理和统计分析，这样移动端也能承担真实管理工作。

#### Acceptance Criteria

1. WHEN 管理员进入工作台 THEN 系统 SHALL 对接统计总览、最新申请、公告和待办数据。
2. WHEN 管理员进入学院、实验室和管理员管理模块 THEN 系统 SHALL 对接对应分页、创建、编辑、删除和分配接口。
3. WHEN 管理员进入审批模块 THEN 系统 SHALL 支持实验室创建审批、教师注册审批、成员申请审批和退出实验室审批。
4. WHEN 管理员进入成员管理、公告管理、招新计划、考勤任务、题库、设备、优秀毕业生模块 THEN 系统 SHALL 提供完整增删改查与审核动作。
5. WHEN 超级管理员登录 THEN 系统 SHALL 额外开放仅 `super_admin` 可访问的管理员、学院、实验室分配等入口。

### Requirement 9

**User Story:** 作为客户端用户，我希望所有文件、图片和受保护资源都能按权限正确访问，这样资料和考勤图片在跨平台上都能稳定打开。

#### Acceptance Criteria

1. WHEN 客户端上传头像、简历、资料空间文件或考勤图片 THEN 系统 SHALL 使用正确的 multipart 方式提交并处理平台差异。
2. WHEN 客户端展示公共文件 THEN 系统 SHALL 通过公共文件访问接口解析真实地址。
3. WHEN 客户端展示受保护考勤照片 THEN 系统 SHALL 携带鉴权信息按权限访问受保护资源。
4. IF 文件类型不可直接预览 THEN 系统 SHALL 提供下载或外部打开能力。
5. WHERE 服务端返回文件路径为相对路径 系统 SHALL 统一解析为可访问 URL。

### Requirement 10

**User Story:** 作为正式产品用户，我希望客户端界面没有调试入口、占位文案和“建议去 Web 端”的痕迹，这样我得到的是一个真正可交付的产品。

#### Acceptance Criteria

1. WHERE 后端已存在正式能力 系统 SHALL 直接接入真实接口，而不是保留“待开发”“去 Web 端处理”等提示。
2. WHERE 后端不存在对应能力 系统 SHALL 不伪装成已接入功能，且入口要么移除，要么降级为明确的产品说明页。
3. WHEN 用户使用任一角色门户 THEN 系统 SHALL 保持一致的设计语言、交互节奏和状态反馈。
4. WHEN 网络错误、空数据或权限不足发生 THEN 系统 SHALL 展示正式产品级空态和错误态，不出现开发术语。
5. WHERE 客户端存在环境配置能力 系统 SHALL 不以公开调试入口形式暴露给终端用户。

### Requirement 11

**User Story:** 作为项目负责人，我希望能清楚知道 Flutter 端与后端的覆盖率和剩余缺口，这样项目可以按模块稳定推进，而不是边做边猜。

#### Acceptance Criteria

1. WHEN 新增一个后端模块接入 THEN 项目 SHALL 更新覆盖清单、接口仓库和对应页面状态。
2. WHEN 一个角色门户达到可交付状态 THEN 项目 SHALL 具备该角色完整链路的验证记录。
3. WHEN 提交阶段性成果 THEN 项目 SHALL 明确说明已对接的控制器、未对接的控制器和原因。
4. WHERE 后端不存在移动端所需聚合接口 THEN 项目 SHALL 在设计阶段记录是否复用现有接口或增加客户端聚合层。
5. WHEN 最终交付客户端 THEN 项目 SHALL 可以按控制器清单证明已完成对接，而不是仅按页面截图说明。

## Delivery Boundary Notes

为避免后续理解偏差，本项目中的“全量对接后端”定义如下：

- 以仓库现有控制器与 Web 端角色路由为边界
- 默认覆盖学生、教师、管理员、超级管理员四类角色
- 默认覆盖所有已暴露的核心业务模块，而不是只做学生端
- 不把后端不存在的功能包装成“已完成对接”
- UI 与交互必须达到正式产品标准，不能保留测试痕迹、调试入口或占位文案

## Initial Gap Verdict

基于当前代码状态，可以明确下结论：

- 当前 Flutter 客户端还不是“全量对接”
- 当前最缺的是角色门户和后台管理模块，而不是单个页面美化
- 后续实施必须从“按控制器清单补齐模块”推进，而不是继续只围绕底部 5 个 tab 打补丁

