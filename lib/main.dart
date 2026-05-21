import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ui/app_theme.dart';
import 'features/env_profile/presentation/pages/env_profile_list_page.dart';

void main() {
  runApp(const ProviderScope(child: AutoEnvApp()));
}

class AutoEnvApp extends StatelessWidget {
  const AutoEnvApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.dark();
    return MaterialApp(
      title: 'auto_env',
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      home: const EnvProfileListPage(),
    );
  }
}
