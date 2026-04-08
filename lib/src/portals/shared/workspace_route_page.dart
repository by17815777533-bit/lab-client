import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../features/workspace/workspace_page.dart';

class WorkspaceRoutePage extends ConsumerWidget {
  const WorkspaceRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile!;
    final repository = ref.watch(labSpaceRepositoryProvider);
    final settings = ref.watch(appSettingsControllerProvider);

    return WorkspacePage(
      repository: repository,
      profile: profile,
      baseUrl: settings.baseUrl,
    );
  }
}
