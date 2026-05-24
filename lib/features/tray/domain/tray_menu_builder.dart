import 'package:tray_manager/tray_manager.dart';

import '../../env_profile/domain/entities/env_profile.dart';

/// Pure-function tray menu builder. Extracted so it can be unit-tested
/// without touching the platform [TrayManager] singleton.
///
/// Menu layout (top-down):
///   1. App name header (disabled)
///   2. Status line ("Active: [name]" or "No active profile") (disabled)
///   3. separator
///   4. One checkbox row per profile (checked = currently active)
///      Each row's `key` is `activate:[profileId]` so the click handler can
///      route without re-resolving by label.
///   5. separator
///   6. "Show window" (key=`show`)
///   7. "Rollback" — only when something is active (key=`rollback`)
///   8. "Quit" (key=`quit`)
List<MenuItem> buildTrayMenu({
  required List<EnvProfile> profiles,
  required String? activeProfileId,
}) {
  final activeProfile = activeProfileId == null
      ? null
      : profiles.cast<EnvProfile?>().firstWhere(
            (p) => p?.id == activeProfileId,
            orElse: () => null,
          );

  return <MenuItem>[
    MenuItem(label: 'auto_env', disabled: true),
    MenuItem(
      label: activeProfile == null
          ? 'No active profile'
          : 'Active: ${activeProfile.name}',
      disabled: true,
    ),
    MenuItem.separator(),
    for (final p in profiles)
      MenuItem.checkbox(
        key: 'activate:${p.id}',
        label: p.name,
        checked: p.id == activeProfileId,
      ),
    if (profiles.isEmpty)
      MenuItem(
        label: 'No profiles — create one in the app',
        disabled: true,
      ),
    MenuItem.separator(),
    MenuItem(key: 'show', label: 'Show window'),
    if (activeProfileId != null)
      MenuItem(key: 'rollback', label: 'Rollback'),
    MenuItem(key: 'quit', label: 'Quit'),
  ];
}

/// Parsed intent for a clicked menu item. `null` means the key was unknown
/// (separator / disabled item / unrecognized).
sealed class TrayAction {
  const TrayAction();
}

class TrayActivate extends TrayAction {
  const TrayActivate(this.profileId);
  final String profileId;
}

class TrayRollback extends TrayAction {
  const TrayRollback();
}

class TrayShowWindow extends TrayAction {
  const TrayShowWindow();
}

class TrayQuit extends TrayAction {
  const TrayQuit();
}

/// Maps a `MenuItem.key` to a [TrayAction] without touching any platform
/// state. Returns `null` for unrecognized keys.
TrayAction? parseTrayMenuKey(String? key) {
  if (key == null) return null;
  if (key.startsWith('activate:')) {
    return TrayActivate(key.substring('activate:'.length));
  }
  switch (key) {
    case 'rollback':
      return const TrayRollback();
    case 'show':
      return const TrayShowWindow();
    case 'quit':
      return const TrayQuit();
    default:
      return null;
  }
}
