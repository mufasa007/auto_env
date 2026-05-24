import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'auto_env'**
  String get appTitle;

  /// No description provided for @listPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Environments'**
  String get listPageTitle;

  /// No description provided for @listEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profiles yet. Tap + to create one.'**
  String get listEmpty;

  /// No description provided for @listLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profiles:\n{error}'**
  String listLoadError(String error);

  /// No description provided for @listFab.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get listFab;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @deleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete profile?'**
  String get deleteDialogTitle;

  /// No description provided for @deleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String deleteDialogBody(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cardActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get cardActive;

  /// No description provided for @cardSummary.
  ///
  /// In en, this message translates to:
  /// **'{hosts} hosts · {envs} env vars · updated {updated}'**
  String cardSummary(int hosts, int envs, String updated);

  /// No description provided for @actionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get actionActive;

  /// No description provided for @actionActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get actionActivate;

  /// No description provided for @actionRollback.
  ///
  /// In en, this message translates to:
  /// **'Rollback'**
  String get actionRollback;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @editTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get editTitleNew;

  /// No description provided for @editTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editTitleEdit;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @errorNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get errorNameEmpty;

  /// No description provided for @sectionHosts.
  ///
  /// In en, this message translates to:
  /// **'Hosts entries'**
  String get sectionHosts;

  /// No description provided for @sectionEnvVars.
  ///
  /// In en, this message translates to:
  /// **'Environment variables'**
  String get sectionEnvVars;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @fieldIp.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get fieldIp;

  /// No description provided for @fieldHostname.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get fieldHostname;

  /// No description provided for @addHostEntry.
  ///
  /// In en, this message translates to:
  /// **'Add host entry'**
  String get addHostEntry;

  /// No description provided for @fieldKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get fieldKey;

  /// No description provided for @fieldValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get fieldValue;

  /// No description provided for @addVariable.
  ///
  /// In en, this message translates to:
  /// **'Add variable'**
  String get addVariable;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @modeRows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get modeRows;

  /// No description provided for @modeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get modeText;

  /// No description provided for @parseLineError.
  ///
  /// In en, this message translates to:
  /// **'Line {line}: {reason}'**
  String parseLineError(int line, String reason);

  /// No description provided for @switchTitleRunning.
  ///
  /// In en, this message translates to:
  /// **'Switching environment'**
  String get switchTitleRunning;

  /// No description provided for @switchTitleFailed.
  ///
  /// In en, this message translates to:
  /// **'Switch failed'**
  String get switchTitleFailed;

  /// No description provided for @stageRequestingPrivilege.
  ///
  /// In en, this message translates to:
  /// **'Requesting administrator privilege…'**
  String get stageRequestingPrivilege;

  /// No description provided for @stageWritingHosts.
  ///
  /// In en, this message translates to:
  /// **'Writing hosts file…'**
  String get stageWritingHosts;

  /// No description provided for @stageWritingEnvVars.
  ///
  /// In en, this message translates to:
  /// **'Updating environment variables…'**
  String get stageWritingEnvVars;

  /// No description provided for @stageFlushingDns.
  ///
  /// In en, this message translates to:
  /// **'Flushing DNS cache…'**
  String get stageFlushingDns;

  /// No description provided for @stageDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stageDone;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @switchedInBanner.
  ///
  /// In en, this message translates to:
  /// **'Switched in {seconds}s · running processes need a restart to see new environment variables.'**
  String switchedInBanner(String seconds);

  /// No description provided for @errorPrivilegePasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'The macOS administrator password was wrong. Tap Retry and enter the password of an admin user on this Mac (the one you use to log in).'**
  String get errorPrivilegePasswordWrong;

  /// No description provided for @errorPrivilegeNotAdmin.
  ///
  /// In en, this message translates to:
  /// **'This account is not a macOS administrator. Switch to an admin user or grant this account admin rights in System Settings → Users & Groups.'**
  String get errorPrivilegeNotAdmin;

  /// No description provided for @errorPrivilegeUserCanceled.
  ///
  /// In en, this message translates to:
  /// **'You canceled the administrator prompt. Tap Retry and approve it to continue.'**
  String get errorPrivilegeUserCanceled;

  /// No description provided for @errorPrivilegeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Administrator authorization failed. Tap Retry to see the prompt again.'**
  String get errorPrivilegeGeneric;

  /// No description provided for @errorHostsWrite.
  ///
  /// In en, this message translates to:
  /// **'Could not write to the hosts file.'**
  String get errorHostsWrite;

  /// No description provided for @errorEnvVarWrite.
  ///
  /// In en, this message translates to:
  /// **'Could not update environment variables.'**
  String get errorEnvVarWrite;

  /// No description provided for @errorDnsFlush.
  ///
  /// In en, this message translates to:
  /// **'DNS cache flush failed.'**
  String get errorDnsFlush;

  /// No description provided for @errorPartial.
  ///
  /// In en, this message translates to:
  /// **'The switch partially completed. Consider rolling back.'**
  String get errorPartial;

  /// No description provided for @errorSwitchGeneric.
  ///
  /// In en, this message translates to:
  /// **'The switch could not be completed.'**
  String get errorSwitchGeneric;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get settingsSectionWindow;

  /// No description provided for @closeActionHideToTrayLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide to tray'**
  String get closeActionHideToTrayLabel;

  /// No description provided for @closeActionHideToTrayDesc.
  ///
  /// In en, this message translates to:
  /// **'Closing the window keeps auto_env running in the menu bar / system tray. Quit from the tray menu.'**
  String get closeActionHideToTrayDesc;

  /// No description provided for @closeActionQuitLabel.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get closeActionQuitLabel;

  /// No description provided for @closeActionQuitDesc.
  ///
  /// In en, this message translates to:
  /// **'Closing the window quits auto_env (original macOS / Windows behavior).'**
  String get closeActionQuitDesc;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @localeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get localeSystem;

  /// No description provided for @localeFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get localeFollowSystem;

  /// No description provided for @localeChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get localeChinese;

  /// No description provided for @localeEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get localeEnglish;

  /// No description provided for @trayNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active profile'**
  String get trayNoActive;

  /// No description provided for @trayActive.
  ///
  /// In en, this message translates to:
  /// **'Active: {name}'**
  String trayActive(String name);

  /// No description provided for @trayNoProfilesHint.
  ///
  /// In en, this message translates to:
  /// **'No profiles — create one in the app'**
  String get trayNoProfilesHint;

  /// No description provided for @trayShowWindow.
  ///
  /// In en, this message translates to:
  /// **'Show window'**
  String get trayShowWindow;

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
