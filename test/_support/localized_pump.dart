import 'package:auto_env/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Convenience: pump a child wrapped in a MaterialApp with the
/// AppLocalizations delegate registered. Resolves to English by default
/// (first entry in supportedLocales).
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

/// Synchronously load an AppLocalizations for code that needs translated
/// strings outside the widget tree (e.g. tray menu builder).
Future<AppLocalizations> loadL10n([
  Locale locale = const Locale('en'),
]) {
  return AppLocalizations.delegate.load(locale);
}
