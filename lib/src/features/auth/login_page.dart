import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment.dart';
import '../../core/widgets/app_logo.dart';
import 'auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    final auth = context.read<AuthController>();
    final success = await auth.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录成功')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF2D78FF), Color(0xFFEFF5FF)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final isWide = constraints.maxWidth >= 980;
              final keyboardVisible = viewInsets.bottom > 0;

              final formCard = _buildFormCard(auth: auth, compact: !isWide);

              if (isWide) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: _buildWideHero()),
                          const SizedBox(width: 28),
                          Expanded(child: formCard),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutQuart,
                padding: EdgeInsets.fromLTRB(
                  18,
                  keyboardVisible ? 12 : 28,
                  18,
                  18 + viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          viewInsets.bottom -
                          (keyboardVisible ? 30 : 46),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: keyboardVisible
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: <Widget>[
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutQuart,
                          child: _buildMobileHeader(compact: keyboardVisible),
                        ),
                        const SizedBox(height: 16),
                        formCard,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const AppLogo(size: 64, tone: AppLogoTone.light, showText: false),
          const SizedBox(height: 24),
          Text(
            AppEnvironment.appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '实验室门户',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${AppEnvironment.schoolName}统一登录入口',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const <Widget>[
              _RolePill(label: '学生'),
              _RolePill(label: '教师'),
              _RolePill(label: '管理'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader({required bool compact}) {
    if (compact) {
      return Row(
        key: const ValueKey<String>('compact-header'),
        children: <Widget>[
          const AppLogo(size: 34, tone: AppLogoTone.light, showText: false),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppEnvironment.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey<String>('mobile-header'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const AppLogo(size: 50, tone: AppLogoTone.light, showText: false),
        const SizedBox(height: 14),
        Text(
          AppEnvironment.appName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({required AuthController auth, required bool compact}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(compact ? 20 : 24),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      '登录',
                      style: TextStyle(
                        fontSize: compact ? 22 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF12223A),
                      ),
                    ),
                    SizedBox(height: compact ? 18 : 20),
                    TextFormField(
                      focusNode: _usernameFocusNode,
                      controller: _usernameController,
                      scrollPadding: EdgeInsets.zero,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: '账号',
                        hintText: '学号 / 工号 / 账号',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      onFieldSubmitted: (_) =>
                          _passwordFocusNode.requestFocus(),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入账号';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      focusNode: _passwordFocusNode,
                      controller: _passwordController,
                      scrollPadding: EdgeInsets.zero,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: '密码',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        return null;
                      },
                    ),
                    if ((auth.errorMessage ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEECEC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: auth.busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: auth.busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Text('登录'),
                    ),
                    if (!compact) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        AppEnvironment.schoolName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF97A3B6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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
