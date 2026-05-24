import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_colors.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/app_settings_providers.dart';

/// User-facing preferences. M3 ships two sections:
///   - Window: what the close button does
///   - Language: explicit locale override (System / 中文 / English)
///
/// Appearance (dark mode) is intentionally deferred — M3 ships light-only.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncSettings = ref.watch(appSettingsNotifierProvider);
    final notifier = ref.read(appSettingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: asyncSettings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Failed to load settings:\n$err'),
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            _SectionLabel(l10n.settingsSectionWindow),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: RadioGroup<CloseAction>(
                groupValue: settings.closeAction,
                onChanged: (v) {
                  if (v != null) notifier.updateCloseAction(v);
                },
                child: Column(
                  children: [
                    _CloseActionTile(
                      label: l10n.closeActionHideToTrayLabel,
                      description: l10n.closeActionHideToTrayDesc,
                      value: CloseAction.hideToTray,
                    ),
                    const Divider(height: 1),
                    _CloseActionTile(
                      label: l10n.closeActionQuitLabel,
                      description: l10n.closeActionQuitDesc,
                      value: CloseAction.quit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(l10n.settingsSectionLanguage),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: ListTile(
                title: Text(l10n.languageLabel),
                subtitle: Text(
                  _localeLabel(l10n, settings.locale),
                  style: AppTypography.caption,
                ),
                trailing: DropdownButton<String?>(
                  value: settings.locale,
                  underline: const SizedBox.shrink(),
                  onChanged: notifier.updateLocale,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.localeSystem),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'zh',
                      child: Text(l10n.localeChinese),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'en',
                      child: Text(l10n.localeEnglish),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  static String _localeLabel(AppLocalizations l10n, String? locale) {
    switch (locale) {
      case 'zh':
        return l10n.localeChinese;
      case 'en':
        return l10n.localeEnglish;
      default:
        return l10n.localeFollowSystem;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CloseActionTile extends StatelessWidget {
  const _CloseActionTile({
    required this.label,
    required this.description,
    required this.value,
  });

  final String label;
  final String description;
  final CloseAction value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<CloseAction>(
      key: Key('close-action-${value.name}'),
      value: value,
      title: Text(label),
      subtitle: Text(
        description,
        style: AppTypography.caption,
      ),
      activeColor: AppColors.accent,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
