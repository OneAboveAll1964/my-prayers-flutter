import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
