import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/tokens.dart';
import '../../shared/models/prayer_time.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_field.dart';
import '../../shared/widgets/app_sheet.dart';
import '../../shared/widgets/app_toggle.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/segmented_control.dart';
import 'widgets/method_picker.dart';
import 'widgets/settings_widgets.dart';

class SettingsPrayerTimesPage extends ConsumerWidget {
  const SettingsPrayerTimesPage({super.key});

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
            PageHeader(title: l10n.t('settings.prayerTimes'), back: true),
            Expanded(
              child: PageBody(
                children: [
                  AppSurface(
                    child: Column(
                      children: [
                        SettingsTile(
                          label: l10n.t('settings.location'),
                          value: settings.location?.name ?? '—',
                          onTap: () => context.push('/settings/location'),
                        ),
                        const SettingsDivider(),
                        SettingsTile(
                          label: l10n.t('settings.calculationMethod'),
                          value: l10n
                              .t('calc.${settings.calculationMethod.name}'),
                          onTap: () => showAppSheet(
                            context: context,
                            title: l10n.t('settings.calculationMethod'),
                            builder: (sheetCtx) => MethodPicker(
                              onPick: () {
                                Navigator.of(sheetCtx).pop();
                                _reschedule(ref);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SettingsSection(
                    label: l10n.t('settings.asrMethod'),
                    child: SegmentedControl<AsrMethod>(
                      value: settings.asrMethod,
                      onChanged: (v) {
                        notifier.setAsrMethod(v);
                        _reschedule(ref);
                      },
                      options: [
                        SegmentedOption(
                            value: AsrMethod.shafii,
                            label: l10n.t('settings.asrShafii')),
                        SegmentedOption(
                            value: AsrMethod.hanafi,
                            label: l10n.t('settings.asrHanafi')),
                      ],
                    ),
                  ),
                  SettingsSection(
                    label: l10n.t('settings.higherLatitude'),
                    child: SegmentedControl<HigherLatitudeMethod>(
                      layout: SegmentedLayout.grid,
                      value: settings.higherLatitudeMethod,
                      onChanged: (v) {
                        notifier.setHigherLatitudeMethod(v);
                        _reschedule(ref);
                      },
                      options: [
                        SegmentedOption(
                            value: HigherLatitudeMethod.angleBased,
                            label: l10n.t('settings.highLatAngleBased')),
                        SegmentedOption(
                            value: HigherLatitudeMethod.midNight,
                            label: l10n.t('settings.highLatMidNight')),
                        SegmentedOption(
                            value: HigherLatitudeMethod.oneSeven,
                            label: l10n.t('settings.highLatOneSeven')),
                        SegmentedOption(
                            value: HigherLatitudeMethod.none,
                            label: l10n.t('settings.highLatNone')),
                      ],
                    ),
                  ),
                  SettingsSection(
                    label: l10n.t('settings.offsets'),
                    child: OffsetEditor(
                      offsets: settings.offsets,
                      onChange: (i, v) {
                        final list = [...settings.offsets];
                        list[i] = v;
                        notifier.setOffsets(list);
                        _reschedule(ref);
                      },
                    ),
                  ),
                  AppSurface(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.t('settings.useFixedTimes'),
                            style:
                                TextStyle(color: palette.text, fontSize: 14),
                          ),
                        ),
                        AppToggle(
                          value: settings.useFixedTimes,
                          onChanged: (v) {
                            notifier.setUseFixedTimes(v);
                            _reschedule(ref);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (settings.calculationMethod ==
                      CalculationMethod.custom) ...[
                    AppSurface(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('settings.customAngles'),
                            style: TextStyle(
                                color: palette.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(l10n.t('settings.fajrAngle'),
                                    style: TextStyle(
                                        color: palette.text, fontSize: 14)),
                              ),
                              AppNumberField(
                                value: settings.fajrAngle,
                                allowDecimal: true,
                                onChanged: (v) {
                                  notifier.setFajrAngle(v.toDouble());
                                  _reschedule(ref);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(l10n.t('settings.ishaAngle'),
                                    style: TextStyle(
                                        color: palette.text, fontSize: 14)),
                              ),
                              AppNumberField(
                                value: settings.ishaAngle,
                                allowDecimal: true,
                                onChanged: (v) {
                                  notifier.setIshaAngle(v.toDouble());
                                  _reschedule(ref);
                                },
                              ),
                            ],
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
    );
  }
}
