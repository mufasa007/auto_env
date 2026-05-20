import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/env_profile/presentation/pages/env_profile_list_page.dart';

void main() {
  runApp(const ProviderScope(child: AutoEnvApp()));
}

class AutoEnvApp extends StatelessWidget {
  const AutoEnvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'auto_env',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const EnvProfileListPage(),
    );
  }
}
