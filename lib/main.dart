import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ui/app_theme.dart';
import 'features/app_settings/presentation/providers/app_settings_providers.dart';
import 'features/env_profile/presentation/pages/env_profile_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-load AppSettings so MaterialApp boots with the user's choices in
  // hand — avoids a flash of defaults followed by re-themeing.
  final container = ProviderContainer();
  await container.read(appSettingsNotifierProvider.future);
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
