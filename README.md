# LabLink Flutter Client

面向实验室日常管理与成员协作的 Flutter 跨平台客户端。

## 当前已完成

- 统一登录与登录态恢复
- 多角色主导航：`首页 / 实验室 / 空间 / 申请 / 我的`
- 学生工作台数据聚合：开放计划、最新公告、我的申请
- 实验室浏览、详情查看、学生入组申请
- 在组空间、资料浏览、考勤流程
- 教师实验室创建申请
- 管理端统计工作台
- 公告分页查询
- 个人中心移动端样式页
- 个人资料编辑、头像上传、简历上传、密码修改

## 架构

项目按职责拆分，保持页面、状态与数据访问解耦：

```text
lib/
  src/
    app/          # 启动、路由、门户壳层
    core/         # 配置、网络、存储、主题、通用组件
    models/       # 数据模型
    repositories/ # 数据访问封装
    features/     # 业务页面与控制器
    portals/      # 学生、教师、管理门户
```

关键约束：

- 页面不直接操作 `dio`
- 登录态和资料缓存统一由 `AuthController + SessionStorage` 管理
- 统一通过 `ApiClient` 处理服务响应
- 业务模块按 feature 拆 controller，避免出现单文件屎山

## 品牌资源

应用标识资源位于 `assets/branding/app_mark.svg`。

## 运行

```bash
flutter pub get
flutter run -d chrome
```

也可以运行桌面或移动端：

```bash
flutter run -d linux
flutter run -d android
```

## 验证

已完成的验证：

- `flutter analyze`
- `flutter test`
- `flutter build web`
