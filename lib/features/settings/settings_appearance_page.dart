import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/segmented_control.dart';
import 'widgets/arabic_font_picker.dart';
import 'widgets/settings_widgets.dart';

class SettingsAppearancePage extends ConsumerWidget {
  const SettingsAppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l10n.t('settings.appearance'), back: true),
            Expanded(
              child: PageBody(
                children: [
                  SettingsSection(
                    label: l10n.t('settings.theme'),
                    child: SegmentedControl<AppThemeMode>(
                      value: settings.themeMode,
                      onChanged: notifier.setTheme,
                      options: [
                        SegmentedOption(
                            value: AppThemeMode.auto,
                            label: l10n.t('settings.themeAuto')),
                        SegmentedOption(
                            value: AppThemeMode.light,
                            label: l10n.t('settings.themeLight')),
                        SegmentedOption(
                            value: AppThemeMode.dark,
                            label: l10n.t('settings.themeDark')),
                      ],
                    ),
                  ),
                  SettingsSection(
                    label: l10n.t('settings.timeFormat'),
                    child: SegmentedControl<String>(
                      value: settings.timeFormat,
                      onChanged: notifier.setTimeFormat,
                      options: [
                        SegmentedOption(
                            value: '24h',
                            label: l10n.t('settings.time24h')),
                        SegmentedOption(
                            value: '12h',
                            label: l10n.t('settings.time12h')),
                      ],
                    ),
                  ),
                  SettingsSection(
                    label: l10n.t('settings.arabicFont'),
                    child: const ArabicFontPicker(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
