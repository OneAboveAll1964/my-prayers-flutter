import 'dart:async';
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
import 'widgets/arabic_font_picker.dart';
import 'widgets/language_picker.dart';
import 'widgets/method_picker.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final lang = settings.language ??
        Localizations.localeOf(context).languageCode;

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
                  _Section(
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
                  _Section(
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
                  _Section(
                    label: l10n.t('settings.arabicFont'),
                    child: const ArabicFontPicker(),
                  ),
                  AppSurface(
                    child: Column(
                      children: [
                        _Tile(
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
                        _Divider(),
                        _Tile(
                          label: l10n.t('settings.location'),
                          value: settings.location?.name ?? '—',
                          onTap: () => context.push('/settings/location'),
                        ),
                        _Divider(),
                        _Tile(
                          label: l10n.t('settings.calculationMethod'),
                          value: l10n.t('calc.${settings.calculationMethod.name}'),
                          onTap: () => showAppSheet(
                            context: context,
                            title: l10n.t('settings.calculationMethod'),
                            builder: (sheetCtx) => MethodPicker(
                              onPick: () {
                                Navigator.of(sheetCtx).pop();
                                _rescheduleNotifications(ref);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    label: l10n.t('settings.asrMethod'),
                    child: SegmentedControl<AsrMethod>(
                      value: settings.asrMethod,
                      onChanged: (v) {
                        notifier.setAsrMethod(v);
                        _rescheduleNotifications(ref);
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
                  _Section(
                    label: l10n.t('settings.higherLatitude'),
                    child: SegmentedControl<HigherLatitudeMethod>(
                      layout: SegmentedLayout.grid,
                      value: settings.higherLatitudeMethod,
                      onChanged: (v) {
                        notifier.setHigherLatitudeMethod(v);
                        _rescheduleNotifications(ref);
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
                  _Section(
                    label: l10n.t('settings.offsets'),
                    child: _OffsetEditor(
                      offsets: settings.offsets,
                      onChange: (i, v) {
                        final list = [...settings.offsets];
                        list[i] = v;
                        notifier.setOffsets(list);
                        _rescheduleNotifications(ref);
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
                            style: TextStyle(color: palette.text, fontSize: 14),
                          ),
                        ),
                        AppToggle(
                          value: settings.useFixedTimes,
                          onChanged: (v) {
                            notifier.setUseFixedTimes(v);
                            _rescheduleNotifications(ref);
                          },
                        ),
                      ],
                    ),
                  ),
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
                                _rescheduleNotifications(ref);
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
                                    value: settings.perPrayerNotifications[i],
                                    onChanged: (v) {
                                      final list = [
                                        ...settings.perPrayerNotifications
                                      ];
                                      list[i] = v;
                                      notifier.setPerPrayerNotifications(list);
                                      _rescheduleNotifications(ref);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              await NotificationService.instance
                                  .requestPermissions();
                              await NotificationService.instance.showTest();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: palette.surface2,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radius),
                                border: Border.all(color: palette.line),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.notifications_active_outlined,
                                      size: 18, color: palette.accent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.t('settings.sendTestNotification'),
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
                                  _rescheduleNotifications(ref);
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
                                  _rescheduleNotifications(ref);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.t('settings.version')} 1.0.0',
                          style: TextStyle(
                              color: palette.textSubtle, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.t('settings.madeBy')} OneAboveAll1964',
                          style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
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

  void _rescheduleNotifications(WidgetRef ref) {
    final s = ref.read(settingsProvider);
    NotificationService.instance.reschedule(
      location: s.location,
      attribute: s.toAttribute(),
      useFixed: s.useFixedTimes,
      enabled: s.notificationsEnabled,
      perPrayer: s.perPrayerNotifications,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: palette.textSubtle,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        color: _down ? palette.surface2 : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: palette.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: palette.textSubtle,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: palette.textSubtle),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: context.palette.line);
}

class _OffsetEditor extends StatelessWidget {
  const _OffsetEditor({required this.offsets, required this.onChange});
  final List<int> offsets;
  final void Function(int, int) onChange;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < prayerKeys.length; i++) ...[
            _OffsetRow(
              label: l10n.t('prayers.${prayerKeys[i]}'),
              value: offsets[i],
              minutesLabel: l10n.t('settings.minutes'),
              onChange: (delta) {
                final next = (offsets[i] + delta).clamp(-30, 30);
                onChange(i, next);
              },
            ),
            if (i < prayerKeys.length - 1)
              Container(height: 1, color: palette.line),
          ],
        ],
      ),
    );
  }
}

class _OffsetRow extends StatelessWidget {
  const _OffsetRow({
    required this.label,
    required this.value,
    required this.minutesLabel,
    required this.onChange,
  });

  final String label;
  final int value;
  final String minutesLabel;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final canMinus = value > -30;
    final canPlus = value < 30;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: palette.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: canMinus,
            onTap: canMinus ? () => onChange(-1) : null,
          ),
          SizedBox(
            width: 76,
            child: Text(
              '${value > 0 ? '+' : ''}$value $minutesLabel',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: value == 0 ? palette.textMuted : palette.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: canPlus,
            onTap: canPlus ? () => onChange(1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  bool _down = false;
  Timer? _repeat;

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  void _startRepeat() {
    if (widget.onTap == null) return;
    _repeat?.cancel();
    _repeat = Timer(const Duration(milliseconds: 380), () {
      _repeat = Timer.periodic(const Duration(milliseconds: 70), (_) {
        widget.onTap?.call();
      });
    });
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disabled = !widget.enabled;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (!disabled) {
          setState(() => _down = true);
          _startRepeat();
        }
      },
      onTapCancel: () {
        setState(() => _down = false);
        _stopRepeat();
      },
      onTapUp: (_) {
        setState(() => _down = false);
        _stopRepeat();
      },
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled
              ? palette.surface2
              : (_down ? palette.surface3 : palette.surface2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.line),
        ),
        child: Icon(
          widget.icon,
          size: 16,
          color: disabled ? palette.textSubtle : palette.text,
        ),
      ),
    );
  }
}
