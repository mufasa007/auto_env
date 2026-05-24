import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_settings/domain/entities/app_settings.dart';
import '../../app_settings/presentation/providers/app_settings_providers.dart';
import '../../env_profile/presentation/providers/env_profile_providers.dart';
import '../../env_switch/presentation/providers/env_switch_providers.dart';
import '../domain/tray_menu_builder.dart';

/// Owns the platform tray icon + window close interception. Lives outside
/// the widget tree (created in `main`) so it can react to `closeAction`
/// before any widget has a chance to render.
///
/// Listens to:
///   - [envProfileListProvider]      — to rebuild the menu's profile list
///   - [activeProfileSnapshotProvider] — to flip the checked marker
///   - [appSettingsNotifierProvider]   — to read `closeAction` on close
class TrayController with TrayListener, WindowListener {
  TrayController(this._container);

  final ProviderContainer _container;
  ProviderSubscription<dynamic>? _profilesSub;
  ProviderSubscription<dynamic>? _activeSub;
  ProviderSubscription<dynamic>? _settingsSub;
  bool _disposed = false;

  static const String _iconPath = 'assets/tray/icon.png';
  static const String _iconPathWindows = 'assets/tray/icon.ico';

  Future<void> init() async {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);

    await trayManager.setIcon(
      Platform.isWindows ? _iconPathWindows : _iconPath,
    );
    await trayManager.setToolTip('auto_env');
    trayManager.addListener(this);

    _profilesSub = _container.listen<dynamic>(
      envProfileListProvider,
      (_, _) => _rebuildMenu(),
    );
    _activeSub = _container.listen<dynamic>(
      activeProfileSnapshotProvider,
      (_, _) => _rebuildMenu(),
    );
    _settingsSub = _container.listen<dynamic>(
      appSettingsNotifierProvider,
      (_, _) => _rebuildMenu(),
    );

    await _rebuildMenu();
  }

  Future<void> _rebuildMenu() async {
    if (_disposed) return;
    final profiles =
        _container.read(envProfileListProvider).value ?? const [];
    final activeId =
        _container.read(activeProfileSnapshotProvider).value?.activeProfileId;
    final l10n = await _loadLocalizations();
    final items = buildTrayMenu(
      profiles: profiles,
      activeProfileId: activeId,
      l10n: l10n,
    );
    await trayManager.setContextMenu(Menu(items: items));
  }

  /// Resolves an [AppLocalizations] for the user's current locale choice
  /// (explicit override in settings, or platform default when null).
  Future<AppLocalizations> _loadLocalizations() async {
    final settings =
        _container.read(appSettingsNotifierProvider).value ??
            const AppSettings();
    final explicit = settings.locale;
    Locale target;
    if (explicit != null && explicit.isNotEmpty) {
      target = Locale(explicit);
    } else {
      final system = PlatformDispatcher.instance.locale;
      target = AppLocalizations.supportedLocales.firstWhere(
        (l) => l.languageCode == system.languageCode,
        orElse: () => const Locale('en'),
      );
    }
    return AppLocalizations.delegate.load(target);
  }

  @override
  void onTrayIconMouseDown() {
    // On Windows clicking the icon should pop the menu. On macOS the OS
    // pops the menu automatically on right-click; left-click does nothing
    // by default which is the standard menu-bar app convention.
    if (Platform.isWindows) {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final action = parseTrayMenuKey(menuItem.key);
    if (action == null) return;
    _handle(action);
  }

  Future<void> _handle(TrayAction action) async {
    switch (action) {
      case TrayActivate(:final profileId):
        await _container
            .read(envSwitchNotifierProvider.notifier)
            .activate(profileId);
        // If the switch errored, surface the app so the user can see
        // SwitchProgressDialog instead of failing silently in the tray.
        final state = _container.read(envSwitchNotifierProvider);
        if (state.hasError) {
          await windowManager.show();
          await windowManager.focus();
        }
      case TrayRollback():
        await _container.read(envSwitchNotifierProvider.notifier).rollback();
      case TrayShowWindow():
        await windowManager.show();
        await windowManager.focus();
      case TrayQuit():
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
    }
  }

  @override
  void onWindowClose() async {
    final settings =
        _container.read(appSettingsNotifierProvider).requireValue;
    switch (settings.closeAction) {
      case CloseAction.hideToTray:
        await windowManager.hide();
      case CloseAction.quit:
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _profilesSub?.close();
    _activeSub?.close();
    _settingsSub?.close();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (_) {
      // ignore: destroy at app shutdown is best-effort
    }
  }
}
