import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/file_url_resolver.dart';
import '../../core/utils/url_launcher_helper.dart';
import '../../core/widgets/panel_card.dart';
import '../../core/widgets/responsive_list_view.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';
import '../auth/auth_controller.dart';
import '../settings/app_settings_controller.dart';
import '../settings/settings_page.dart';
import 'auxiliary_pages.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _uploadingAvatar = false;
  bool _uploadingResume = false;

  Future<void> _openPage(Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _pickAndUploadAvatar() async {
    final repository = context.read<ProfileRepository>();
    final auth = context.read<AuthController>();

    setState(() {
      _uploadingAvatar = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['jpg', 'jpeg', 'png'],
        withData: kIsWeb,
      );

      final file = result != null && result.files.isNotEmpty
          ? result.files.first
          : null;
      if (file == null) {
        return;
      }

      final path = await repository.uploadFile(file: file, scene: 'avatar');
      final updated = await repository.updateAvatar(path);
      await auth.applyProfile(updated);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('头像已更新')));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadResume() async {
    final repository = context.read<ProfileRepository>();
    final auth = context.read<AuthController>();

    setState(() {
      _uploadingResume = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['pdf', 'doc', 'docx'],
        withData: kIsWeb,
      );

      final file = result != null && result.files.isNotEmpty
          ? result.files.first
          : null;
      if (file == null) {
        return;
      }

      final current = auth.profile!;
      final path = await repository.uploadFile(file: file, scene: 'resume');
      final updated = await repository.updateProfile(
        realName: current.realName,
        email: current.email ?? '',
        major: current.major,
        resume: path,
      );
      await auth.applyProfile(updated);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('简历已上传')));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _uploadingResume = false;
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final auth = context.read<AuthController>();
    final repository = context.read<ProfileRepository>();
    final profile = auth.profile!;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _EditProfileSheet(
          profile: profile,
          onSubmit:
              ({
                required String realName,
                required String email,
                String? major,
              }) async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(this.context);
                final updated = await repository.updateProfile(
                  realName: realName,
                  email: email,
                  major: major,
                  resume: profile.resume,
                );
                await auth.applyProfile(updated);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('个人资料已更新')),
                );
              },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final settings = context.watch<AppSettingsController>();
    final profile = auth.profile!;
    final resumeUrl = FileUrlResolver.resolve(
      baseUrl: settings.baseUrl,
      rawUrl: profile.resume,
    );

    return ResponsiveListView(
      onRefresh: auth.refreshProfile,
      children: <Widget>[
        _ProfileHeader(profile: profile),
        const SizedBox(height: 16),
        const _ProfileSectionTitle(title: '常用服务'),
        const SizedBox(height: 10),
        PanelCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            children: <Widget>[
              _MenuTile(
                icon: Icons.badge_outlined,
                title: '生物信息采集',
                trailingLabel: '人脸、指纹、声纹',
                onTap: () => _openPage(const BiometricCollectionPage()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _ProfileSectionTitle(title: '我的资料'),
        const SizedBox(height: 10),
        PanelCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            children: <Widget>[
              _MenuTile(
                icon: Icons.star_border_rounded,
                title: '我收藏的',
                onTap: () => _openPage(const FavoritesPage()),
              ),
              _MenuTile(
                icon: Icons.note_alt_outlined,
                title: '我反馈的',
                onTap: () => _openPage(const FeedbackRecordsPage()),
              ),
              _MenuTile(
                icon: Icons.description_outlined,
                title: '我的简历',
                subtitle: profile.hasResume ? '已上传，可查看或重新上传' : '未上传',
                trailingLabel: _uploadingResume ? '上传中' : '上传',
                onTap: () async {
                  if (profile.hasResume) {
                    await openExternalLink(context, resumeUrl);
                  } else {
                    await _pickAndUploadResume();
                  }
                },
                onTrailingTap: _uploadingResume ? null : _pickAndUploadResume,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _ProfileSectionTitle(title: '支持与设置'),
        const SizedBox(height: 10),
        PanelCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            children: <Widget>[
              _MenuTile(
                icon: Icons.help_outline_rounded,
                title: '帮助与反馈',
                onTap: () => _openPage(const HelpCenterPage()),
              ),
              _MenuTile(
                icon: Icons.settings_outlined,
                title: '设置',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _ProfileSectionTitle(
                title: '账号信息',
                subtitle: '把当前身份、联系信息和资料入口收在一起。',
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final compact = constraints.maxWidth < 720;
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _editProfile,
                            child: const Text('编辑资料'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: _uploadingAvatar
                                ? null
                                : _pickAndUploadAvatar,
                            child: Text(_uploadingAvatar ? '上传中' : '更换头像'),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: <Widget>[
                      const Spacer(),
                      OutlinedButton(
                        onPressed: _editProfile,
                        child: const Text('编辑资料'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: _uploadingAvatar
                            ? null
                            : _pickAndUploadAvatar,
                        child: Text(_uploadingAvatar ? '上传中' : '更换头像'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _InfoLine(label: '角色', value: profile.roleLabel),
              _InfoLine(label: '账号', value: profile.accountValue),
              _InfoLine(label: '学院', value: profile.college ?? '-'),
              _InfoLine(label: '专业', value: profile.major ?? '-'),
              _InfoLine(label: '年级', value: profile.grade ?? '-'),
              _InfoLine(label: '邮箱', value: profile.email ?? '-'),
              _InfoLine(label: '手机号', value: profile.phone ?? '-'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF12223A),
          ),
        ),
        if ((subtitle ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(color: Color(0xFF8792A6), height: 1.55),
          ),
        ],
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final maskedPhone = _maskedPhone(profile.phone ?? profile.accountValue);
    final identityLabel = profile.primaryIdentity ?? profile.roleLabel;
    final labLabel = profile.labId == null ? '未加入实验室' : '实验室 #${profile.labId}';

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF2D78FF), Color(0xFF5CCBFF)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: -28,
            top: -18,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: 18,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                profile.realName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                maskedPhone,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile.roleLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _ProfileHeaderPill(label: identityLabel),
                  _ProfileHeaderPill(label: labLabel),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _maskedPhone(String value) {
    final source = value.trim();
    if (source.length < 7) {
      return source;
    }
    return '${source.substring(0, 3)}****${source.substring(source.length - 4)}';
  }
}

class _ProfileHeaderPill extends StatelessWidget {
  const _ProfileHeaderPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.onTap,
    this.onTrailingTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x142F76FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF2F76FF)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF12223A),
                    ),
                  ),
                  if ((subtitle ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(color: Color(0xFF8792A6)),
                    ),
                  ],
                ],
              ),
            ),
            if ((trailingLabel ?? '').isNotEmpty) ...<Widget>[
              if (onTrailingTap == null)
                Text(
                  trailingLabel!,
                  style: const TextStyle(
                    color: Color(0xFF9AA4B2),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                TextButton(
                  onPressed: onTrailingTap,
                  child: Text(trailingLabel!),
                ),
              const SizedBox(width: 2),
            ],
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA4B2)),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF8792A6)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF12223A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile, required this.onSubmit});

  final UserProfile profile;
  final Future<void> Function({
    required String realName,
    required String email,
    String? major,
  })
  onSubmit;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _realNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _majorController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _realNameController = TextEditingController(text: widget.profile.realName);
    _emailController = TextEditingController(text: widget.profile.email ?? '');
    _majorController = TextEditingController(text: widget.profile.major ?? '');
  }

  @override
  void dispose() {
    _realNameController.dispose();
    _emailController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.onSubmit(
        realName: _realNameController.text.trim(),
        email: _emailController.text.trim(),
        major: _majorController.text.trim().isEmpty
            ? null
            : _majorController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              '编辑资料',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12223A),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _realNameController,
              decoration: const InputDecoration(labelText: '姓名'),
              validator: (String? value) {
                if ((value ?? '').trim().isEmpty) {
                  return '请输入姓名';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '邮箱'),
              validator: (String? value) {
                if ((value ?? '').trim().isEmpty) {
                  return '请输入邮箱';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _majorController,
              decoration: const InputDecoration(labelText: '专业'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
