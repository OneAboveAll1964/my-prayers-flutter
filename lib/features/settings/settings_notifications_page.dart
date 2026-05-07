import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/tokens.dart';
import '../../shared/models/prayer_time.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_toggle.dart';
import '../../shared/widgets/page_scaffold.dart';

class SettingsNotificationsPage extends ConsumerWidget {
  const SettingsNotificationsPage({super.key});

  void _reschedule(WidgetRef ref) {
    final s = ref.read(settingsProvider);
    NotificationService.instance.reschedule(
      location: s.location,
      attribute: s.toAttribute(),
      useFixed: s.useFixedTimes,
      enabled: s.notificationsEnabled,
      perPrayer: s.perPrayerNotifications,
    );
  }

  void _promptOpenSettings(BuildContext context, AppL10n l10n) {
    final palette = context.palette;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(
          l10n.t('settings.notificationsBlockedTitle'),
          style: TextStyle(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.t('settings.notificationsBlockedBody'),
          style: TextStyle(
              color: palette.textMuted, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.t('common.cancel'),
                style: TextStyle(color: palette.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: Text(
              l10n.t('settings.openSystemSettings'),
              style: TextStyle(
                  color: palette.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

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
            PageHeader(title: l10n.t('settings.notifications'), back: true),
            Expanded(
              child: PageBody(
                children: [
                  AppSurface(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('settings.notifications'),
                                    style: TextStyle(
                                        color: palette.text,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.t('settings.notificationsHint'),
                                    style: TextStyle(
                                        color: palette.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            AppToggle(
                              value: settings.notificationsEnabled,
                              onChanged: (v) async {
                                if (v) {
                                  final granted = await NotificationService
                                      .instance
                                      .requestPermissions();
                                  if (!granted) return;
                                }
                                notifier.setNotificationsEnabled(v);
                                _reschedule(ref);
                              },
                            ),
                          ],
                        ),
                        if (settings.notificationsEnabled) ...[
                          const SizedBox(height: 12),
                          for (var i = 0; i < prayerKeys.length; i++)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.t('prayers.${prayerKeys[i]}'),
                                      style: TextStyle(
                                          color: palette.text, fontSize: 13.5),
                                    ),
                                  ),
                                  AppToggle(
                                    value:
                                        settings.perPrayerNotifications[i],
                                    onChanged: (v) {
                                      final list = [
                                        ...settings.perPrayerNotifications
                                      ];
                                      list[i] = v;
                                      notifier
                                          .setPerPrayerNotifications(list);
                                      _reschedule(ref);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final granted = await NotificationService
                                  .instance
                                  .requestPermissions();
                              if (!granted) {
                                if (context.mounted) {
                                  _promptOpenSettings(context, l10n);
                                }
                                return;
                              }
                              final s = ref.read(settingsProvider);
                              if (s.location != null &&
                                  s.notificationsEnabled) {
                                await NotificationService.instance
                                    .reschedule(
                                  location: s.location,
                                  attribute: s.toAttribute(),
                                  useFixed: s.useFixedTimes,
                                  enabled: s.notificationsEnabled,
                                  perPrayer: s.perPrayerNotifications,
                                );
                              }
                              await NotificationService.instance.showTest();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: palette.surface2,
                                borderRadius: BorderRadius.circular(
                                    AppTokens.radius),
                                border: Border.all(color: palette.line),
                              ),
                              child: Row(
                                children: [
                                  Icon(Ionicons.notifications_outline,
                                      size: 18, color: palette.accent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.t(
                                          'settings.sendTestNotification'),
                                      style: TextStyle(
                                          color: palette.text,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
