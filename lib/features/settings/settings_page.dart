import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_sheet.dart';
import '../../shared/widgets/page_scaffold.dart';
import 'widgets/language_picker.dart';
import 'widgets/settings_widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final settings = ref.watch(settingsProvider);
    final lang =
        settings.language ?? Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l10n.t('settings.title'), back: true),
            Expanded(
              child: PageBody(
                children: [
                  AppSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SettingsTile(
                          icon: Ionicons.color_palette_outline,
                          label: l10n.t('settings.appearance'),
                          value: '',
                          onTap: () => context.push('/settings/appearance'),
                        ),
                        const SettingsDivider(),
                        SettingsTile(
                          icon: Ionicons.language_outline,
                          label: l10n.t('settings.language'),
                          value: langDisplayNames[lang] ?? lang,
                          onTap: () => showAppSheet(
                            context: context,
                            title: l10n.t('settings.language'),
                            builder: (sheetCtx) => LanguagePicker(
                              onPick: () => Navigator.of(sheetCtx).pop(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SettingsTile(
                          icon: Ionicons.time_outline,
                          label: l10n.t('settings.prayerTimes'),
                          value: '',
                          onTap: () => context.push('/settings/prayer-times'),
                        ),
                        const SettingsDivider(),
                        SettingsTile(
                          icon: Ionicons.notifications_outline,
                          label: l10n.t('settings.notifications'),
                          value: settings.notificationsEnabled ? '✓' : '',
                          onTap: () => context.push('/settings/notifications'),
                        ),
                      ],
                    ),
                  ),
                  AppSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SettingsTile(
                          icon: Ionicons.cloud_download_outline,
                          label: l10n.t('settings.resources'),
                          value: '',
                          onTap: () => context.push('/settings/resources'),
                        ),
                      ],
                    ),
                  ),
                  if (kDebugMode)
                    AppSurface(
                      padding: EdgeInsets.zero,
                      child: SettingsTile(
                        icon: Ionicons.refresh_outline,
                        label: 'Reset onboarding (dev)',
                        value: '',
                        onTap: () {
                          context.go('/');
                          ref
                              .read(settingsProvider.notifier)
                              .setOnboardingComplete(false);
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.t('settings.version')} 1.0.0',
                          style: TextStyle(
                            color: palette.textSubtle,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            final uri = Uri.parse(
                              'https://github.com/OneAboveAll1964',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${l10n.t('settings.madeBy')} OneAboveAll1964',
                                style: TextStyle(
                                  color: palette.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Ionicons.open_outline,
                                size: 12,
                                color: palette.accent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
