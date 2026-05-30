import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ionicons/ionicons.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/location_repository.dart';
import '../../shared/models/location.dart';
import '../../shared/models/prayer_time.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_field.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/app_toggle.dart';

class OnboardingSetupPage extends StatelessWidget {
  const OnboardingSetupPage({
    super.key,
    required this.step,
    required this.onBack,
  });
  final int step;
  final VoidCallback onBack;

  static const _steps = 3;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
          child: Row(
            children: [
              AppIconButton(
                icon: Ionicons.arrow_back,
                onPressed: onBack,
                color: palette.text,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _steps; i++)
                      AnimatedContainer(
                        duration: AppTokens.duration,
                        curve: AppTokens.ease,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 5,
                        width: i == step ? 26 : 16,
                        decoration: BoxDecoration(
                          color: i <= step ? palette.accent : palette.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: KeyedSubtree(
              key: ValueKey(step),
              child: switch (step) {
                0 => const _LocationStep(),
                1 => const _NotificationsStep(),
                _ => const _AppearanceStep(),
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: palette.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 38, color: palette.accent),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _LocationStep extends ConsumerStatefulWidget {
  const _LocationStep();
  @override
  ConsumerState<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<_LocationStep> {
  Timer? _debounce;
  List<AppLocation> _results = [];
  bool _searching = false;
  bool _detecting = false;

  void _select(AppLocation loc) {
    ref.read(settingsProvider.notifier).setLocation(loc);
    ref.read(favoritesProvider.notifier).pushRecentLocation(loc);
    final s = ref.read(settingsProvider);
    NotificationService.instance.reschedule(
      location: loc,
      attribute: s.toAttribute(),
      useFixed: s.useFixedTimes,
      enabled: s.notificationsEnabled,
      perPrayer: s.perPrayerNotifications,
    );
    setState(() => _results = []);
    FocusScope.of(context).unfocus();
  }

  Future<void> _detect() async {
    setState(() => _detecting = true);
    try {
      final perm = await Geolocator.checkPermission();
      var allowed =
          perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      if (!allowed) {
        final req = await Geolocator.requestPermission();
        allowed =
            req == LocationPermission.always ||
            req == LocationPermission.whileInUse;
      }
      if (!allowed) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final found = await LocationRepository.instance.reverseGeocode(
        pos.latitude,
        pos.longitude,
      );
      if (mounted && found != null) _select(found);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final list = await LocationRepository.instance.search(q, limit: 20);
    if (!mounted) return;
    setState(() {
      _results = list;
      _searching = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final selected = ref.watch(settingsProvider).location;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        _StepHeader(
          icon: Ionicons.location_outline,
          title: l10n.t('onboarding.setup.location.title'),
          subtitle: l10n.t('onboarding.setup.location.subtitle'),
        ),
        const SizedBox(height: 26),
        if (selected != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  Ionicons.checkmark_circle,
                  color: palette.accent,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selected.name,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        AppButton(
          label: _detecting
              ? l10n.t('common.loading')
              : l10n.t('home.useMyLocation'),
          icon: _detecting ? null : Ionicons.locate_outline,
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: _detecting ? null : _detect,
        ),
        const SizedBox(height: 14),
        AppTextField(
          hintText: l10n.t('home.searchCity'),
          prefix: Icon(
            Ionicons.search_outline,
            size: 18,
            color: palette.textMuted,
          ),
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 220),
              () => _search(v),
            );
          },
        ),
        if (_searching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: AppSpinner(size: 22)),
          )
        else if (_results.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final loc in _results)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _select(loc),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(color: palette.line),
                ),
                child: Row(
                  children: [
                    Icon(
                      Ionicons.location_outline,
                      size: 18,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.name,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _NotificationsStep extends ConsumerWidget {
  const _NotificationsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final settings = ref.watch(settingsProvider);
    final enabled = settings.notificationsEnabled;

    void reschedule() {
      final s = ref.read(settingsProvider);
      NotificationService.instance.reschedule(
        location: s.location,
        attribute: s.toAttribute(),
        useFixed: s.useFixedTimes,
        enabled: s.notificationsEnabled,
        perPrayer: s.perPrayerNotifications,
      );
    }

    Future<void> toggle(bool v) async {
      if (v) {
        final granted = await NotificationService.instance.requestPermissions();
        if (!granted) return;
      }
      ref.read(settingsProvider.notifier).setNotificationsEnabled(v);
      reschedule();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        _StepHeader(
          icon: Ionicons.notifications_outline,
          title: l10n.t('onboarding.setup.notifications.title'),
          subtitle: l10n.t('onboarding.setup.notifications.subtitle'),
        ),
        const SizedBox(height: 26),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => toggle(!enabled),
          child: AnimatedContainer(
            duration: AppTokens.duration,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: enabled ? palette.accentSoft : palette.surface,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(
                color: enabled ? palette.accent : palette.line,
                width: enabled ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.t('onboarding.setup.notifications.enable'),
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AppToggle(value: enabled, onChanged: toggle),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: AppTokens.duration,
          curve: AppTokens.ease,
          alignment: Alignment.topCenter,
          child: enabled
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      border: Border.all(color: palette.line),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < prayerKeys.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.t('prayers.${prayerKeys[i]}'),
                                    style: TextStyle(
                                      color: palette.text,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                AppToggle(
                                  value: settings.perPrayerNotifications[i],
                                  onChanged: (v) {
                                    final list = [
                                      ...settings.perPrayerNotifications,
                                    ];
                                    list[i] = v;
                                    ref
                                        .read(settingsProvider.notifier)
                                        .setPerPrayerNotifications(list);
                                    reschedule();
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _AppearanceStep extends ConsumerWidget {
  const _AppearanceStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final mode = ref.watch(settingsProvider).themeMode;

    final options = [
      (
        AppThemeMode.auto,
        l10n.t('onboarding.theme.auto'),
        Ionicons.contrast_outline,
      ),
      (
        AppThemeMode.light,
        l10n.t('onboarding.theme.light'),
        Ionicons.sunny_outline,
      ),
      (
        AppThemeMode.dark,
        l10n.t('onboarding.theme.dark'),
        Ionicons.moon_outline,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        _StepHeader(
          icon: Ionicons.color_palette_outline,
          title: l10n.t('onboarding.setup.appearance.title'),
          subtitle: l10n.t('onboarding.setup.appearance.subtitle'),
        ),
        const SizedBox(height: 26),
        for (final (m, label, icon) in options) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref.read(settingsProvider.notifier).setTheme(m),
            child: AnimatedContainer(
              duration: AppTokens.duration,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: mode == m ? palette.accentSoft : palette.surface,
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(
                  color: mode == m ? palette.accent : palette.line,
                  width: mode == m ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: mode == m ? palette.accent : palette.textMuted,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (mode == m)
                    Icon(
                      Ionicons.checkmark_circle,
                      color: palette.accent,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
