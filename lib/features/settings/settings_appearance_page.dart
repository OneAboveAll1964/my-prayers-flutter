import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/segmented_control.dart';
import '../../shared/widgets/theme_preview_phone.dart';
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
                    child: Column(
                      children: [
                        for (final (m, label, icon) in [
                          (
                            AppThemeMode.auto,
                            l10n.t('settings.themeAuto'),
                            Ionicons.contrast_outline,
                          ),
                          (
                            AppThemeMode.light,
                            l10n.t('settings.themeLight'),
                            Ionicons.sunny_outline,
                          ),
                          (
                            AppThemeMode.dark,
                            l10n.t('settings.themeDark'),
                            Ionicons.moon_outline,
                          ),
                        ]) ...[
                          ThemeOptionCard(
                            icon: icon,
                            label: label,
                            mode: m,
                            selected: settings.themeMode == m,
                            onTap: () => notifier.setTheme(m),
                          ),
                          const SizedBox(height: 12),
                        ],
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
                          label: l10n.t('settings.time24h'),
                        ),
                        SegmentedOption(
                          value: '12h',
                          label: l10n.t('settings.time12h'),
                        ),
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
