import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/location_repository.dart';
import '../../shared/models/location.dart';
import '../../shared/models/prayer_time.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_field.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/app_toggle.dart';

class OnboardingSetupPage extends StatelessWidget {
  const OnboardingSetupPage({super.key, required this.step});
  final int step;

  static const _steps = 3;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
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
        Expanded(child: _StepSwitcher(step: step)),
      ],
    );
  }
}

class _StepSwitcher extends StatefulWidget {
  const _StepSwitcher({required this.step});
  final int step;

  @override
  State<_StepSwitcher> createState() => _StepSwitcherState();
}

class _StepSwitcherState extends State<_StepSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _outAnim = ReverseAnimation(
    CurvedAnimation(
      parent: _fade,
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    ),
  );
  late final Animation<double> _inAnim = CurvedAnimation(
    parent: _fade,
    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
  );

  int? _outgoing;

  @override
  void didUpdateWidget(_StepSwitcher old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) {
      _outgoing = old.step;
      _fade.forward(from: 0).whenComplete(() {
        if (mounted && _fade.value == 1) setState(() => _outgoing = null);
      });
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Widget _stepFor(int step) => switch (step) {
    0 => const _LocationStep(),
    1 => const _NotificationsStep(),
    _ => const _AppearanceStep(),
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_outgoing != null)
          FadeTransition(
            opacity: _outAnim,
            child: KeyedSubtree(
              key: ValueKey(_outgoing),
              child: _stepFor(_outgoing!),
            ),
          ),
        FadeTransition(
          opacity: _inAnim,
          child: KeyedSubtree(
            key: ValueKey(widget.step),
            child: _stepFor(widget.step),
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
  String _query = '';
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
    setState(() {
      _results = [];
      _query = '';
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _detect() async {
    if (_detecting) return;
    setState(() => _detecting = true);
    final result = await LocationRepository.instance.detectCurrentLocation();
    if (!mounted) return;
    setState(() => _detecting = false);
    if (result.ok) {
      _select(result.location!);
    } else {
      showLocationDetectError(context, result.error!);
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

    final searching = _query.trim().isNotEmpty;

    return Column(
      children: [
        AnimatedSize(
          duration: AppTokens.duration,
          curve: AppTokens.ease,
          alignment: Alignment.topCenter,
          child: searching
              ? const SizedBox(width: double.infinity, height: 16)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 2, 24, 0),
                  child: Column(
                    children: [
                      Text(
                        l10n.t('onboarding.setup.location.title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.t('onboarding.setup.location.subtitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  hintText: l10n.t('home.searchCity'),
                  prefix: Icon(
                    Ionicons.search_outline,
                    size: 18,
                    color: palette.textMuted,
                  ),
                  onChanged: (v) {
                    setState(() => _query = v);
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 220),
                      () => _search(v),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              _DetectButton(
                detecting: _detecting,
                onTap: _detecting ? null : _detect,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (!searching && selected != null)
                _SelectedLocationCard(name: selected.name),
              if (searching && _searching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(child: AppSpinner(size: 22)),
                ),
              if (searching && !_searching && _results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Center(
                    child: Text(
                      l10n.t('common.noResults'),
                      style: TextStyle(color: palette.textMuted),
                    ),
                  ),
                ),
              if (searching && !_searching && _results.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radius),
                    border: Border.all(color: palette.line),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _results.length; i++) ...[
                        _LocationRow(
                          location: _results[i],
                          onTap: () => _select(_results[i]),
                        ),
                        if (i < _results.length - 1)
                          Container(height: 1, color: palette.line),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetectButton extends StatelessWidget {
  const _DetectButton({required this.detecting, required this.onTap});
  final bool detecting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: palette.accentSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.accent.withValues(alpha: 0.45)),
        ),
        alignment: Alignment.center,
        child: detecting
            ? const AppSpinner(size: 20)
            : Icon(Ionicons.locate_outline, size: 22, color: palette.accent),
      ),
    );
  }
}

class _SelectedLocationCard extends StatelessWidget {
  const _SelectedLocationCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Ionicons.checkmark_circle, color: palette.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: palette.text,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location, required this.onTap});
  final AppLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Icon(
                Ionicons.location_outline,
                size: 14,
                color: palette.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (location.countryName.isNotEmpty)
                    Text(
                      location.countryName,
                      style: TextStyle(color: palette.textSubtle, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(Ionicons.chevron_forward, size: 18, color: palette.textMuted),
          ],
        ),
      ),
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
