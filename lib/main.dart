import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ui/app_theme.dart';
import 'features/app_settings/presentation/providers/app_settings_providers.dart';
import 'features/env_profile/presentation/pages/env_profile_list_page.dart';
import 'features/env_profile/presentation/providers/env_profile_providers.dart';
import 'features/env_switch/presentation/providers/env_switch_providers.dart';
import 'features/tray/presentation/tray_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-load AppSettings + profile list + active snapshot so MaterialApp
  // boots fully populated (avoids a flash of defaults) and so the tray
  // menu can be built before the first frame is drawn.
  final container = ProviderContainer();
  await container.read(appSettingsNotifierProvider.future);
  await container.read(envProfileListProvider.future);
  await container.read(activeProfileSnapshotProvider.future);

  final tray = TrayController(container);
  await tray.init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AutoEnvApp(),
    ),
  );
}

class AutoEnvApp extends ConsumerWidget {
  const AutoEnvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appSettingsNotifierProvider).requireValue;
    return MaterialApp(
      title: 'auto_env',
      theme: AppTheme.light(),
      themeMode: toFlutterThemeMode(settings.themeMode),
      locale: toFlutterLocale(settings.locale),
      home: const EnvProfileListPage(),
    );
  }
}
