// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'auto_env';

  @override
  String get listPageTitle => 'Environments';

  @override
  String get listEmpty => 'No profiles yet. Tap + to create one.';

  @override
  String listLoadError(String error) {
    return 'Failed to load profiles:\n$error';
  }

  @override
  String get listFab => 'New profile';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get deleteDialogTitle => 'Delete profile?';

  @override
  String deleteDialogBody(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get cardActive => 'ACTIVE';

  @override
  String cardSummary(int hosts, int envs, String updated) {
    return '$hosts hosts · $envs env vars · updated $updated';
  }

  @override
  String get actionActive => 'Active';

  @override
  String get actionActivate => 'Activate';

  @override
  String get actionRollback => 'Rollback';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get editTitleNew => 'New profile';

  @override
  String get editTitleEdit => 'Edit profile';

  @override
  String get fieldName => 'Name';

  @override
  String get errorNameEmpty => 'Name cannot be empty';

  @override
  String get sectionHosts => 'Hosts entries';

  @override
  String get sectionEnvVars => 'Environment variables';

  @override
  String get save => 'Save';

  @override
  String get fieldIp => 'IP';

  @override
  String get fieldHostname => 'Hostname';

  @override
  String get addHostEntry => 'Add host entry';

  @override
  String get fieldKey => 'Key';

  @override
  String get fieldValue => 'Value';

  @override
  String get addVariable => 'Add variable';

  @override
  String get remove => 'Remove';

  @override
  String get modeRows => 'Rows';

  @override
  String get modeText => 'Text';

  @override
  String parseLineError(int line, String reason) {
    return 'Line $line: $reason';
  }

  @override
  String get switchTitleRunning => 'Switching environment';

  @override
  String get switchTitleFailed => 'Switch failed';

  @override
  String get stageRequestingPrivilege => 'Requesting administrator privilege…';

  @override
  String get stageWritingHosts => 'Writing hosts file…';

  @override
  String get stageWritingEnvVars => 'Updating environment variables…';

  @override
  String get stageFlushingDns => 'Flushing DNS cache…';

  @override
  String get stageDone => 'Done';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get retry => 'Retry';

  @override
  String switchedInBanner(String seconds) {
    return 'Switched in ${seconds}s · running processes need a restart to see new environment variables.';
  }

  @override
  String get errorPrivilegePasswordWrong =>
      'The macOS administrator password was wrong. Tap Retry and enter the password of an admin user on this Mac (the one you use to log in).';

  @override
  String get errorPrivilegeNotAdmin =>
      'This account is not a macOS administrator. Switch to an admin user or grant this account admin rights in System Settings → Users & Groups.';

  @override
  String get errorPrivilegeUserCanceled =>
      'You canceled the administrator prompt. Tap Retry and approve it to continue.';

  @override
  String get errorPrivilegeGeneric =>
      'Administrator authorization failed. Tap Retry to see the prompt again.';

  @override
  String get errorHostsWrite => 'Could not write to the hosts file.';

  @override
  String get errorEnvVarWrite => 'Could not update environment variables.';

  @override
  String get errorDnsFlush => 'DNS cache flush failed.';

  @override
  String get errorPartial =>
      'The switch partially completed. Consider rolling back.';

  @override
  String get errorSwitchGeneric => 'The switch could not be completed.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionWindow => 'Window';

  @override
  String get closeActionHideToTrayLabel => 'Hide to tray';

  @override
  String get closeActionHideToTrayDesc =>
      'Closing the window keeps auto_env running in the menu bar / system tray. Quit from the tray menu.';

  @override
  String get closeActionQuitLabel => 'Quit';

  @override
  String get closeActionQuitDesc =>
      'Closing the window quits auto_env (original macOS / Windows behavior).';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get languageLabel => 'Language';

  @override
  String get localeSystem => 'System';

  @override
  String get localeFollowSystem => 'Follow system';

  @override
  String get localeChinese => '中文';

  @override
  String get localeEnglish => 'English';

  @override
  String get trayNoActive => 'No active profile';

  @override
  String trayActive(String name) {
    return 'Active: $name';
  }

  @override
  String get trayNoProfilesHint => 'No profiles — create one in the app';

  @override
  String get trayShowWindow => 'Show window';

  @override
  String get trayQuit => 'Quit';
}
