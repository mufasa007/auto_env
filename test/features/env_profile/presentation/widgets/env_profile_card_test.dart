import 'package:auto_env/features/env_profile/domain/entities/env_profile.dart';
import 'package:auto_env/features/env_profile/domain/entities/hosts_entry.dart';
import 'package:auto_env/features/env_profile/presentation/widgets/env_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EnvProfile _profile() => EnvProfile(
  id: 'p1',
  name: 'dev',
  hostsEntries: const [HostsEntry(ip: '127.0.0.1', hostname: 'api.local')],
  envVars: const {'KEY': 'value'},
  createdAt: DateTime(2026, 5, 21, 9, 0),
  updatedAt: DateTime(2026, 5, 21, 9, 30),
);

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: ListView(children: [child]),
    ),
  );
}

void main() {
  testWidgets('renders active-indicator rail when isActive is true', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        EnvProfileCard(
          profile: _profile(),
          isActive: true,
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('active-indicator')), findsOneWidget);
    expect(find.byKey(const Key('active-badge')), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
  });

  testWidgets('hides active-indicator and badge when isActive is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        EnvProfileCard(
          profile: _profile(),
          isActive: false,
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('active-indicator')), findsNothing);
    expect(find.byKey(const Key('active-badge')), findsNothing);
    expect(find.text('ACTIVE'), findsNothing);
  });

  testWidgets('Activate button is disabled while switching', (tester) async {
    await tester.pumpWidget(
      _wrap(
        EnvProfileCard(
          profile: _profile(),
          isActive: false,
          isSwitching: true,
          onEdit: () {},
          onDelete: () {},
          onActivate: () {},
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('activate-button')),
    );
    expect(button.onPressed, isNull);
  });
}
