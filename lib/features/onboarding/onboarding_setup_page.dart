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
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Directionality(
            textDirection: TextDirection.ltr,
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

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dim = compact ? 64.0 : 88.0;
    return Column(
      children: [
        Container(
          width: dim,
          height: dim,
          decoration: BoxDecoration(
            color: palette.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: compact ? 30 : 40, color: palette.accent),
        ),
        SizedBox(height: compact ? 14 : 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.text,
            fontSize: compact ? 21 : 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.sublabel,
    this.trailing,
    this.preview,
  });
  final IconData icon;
  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasPreview = preview != null;

    final row = Row(
      children: [
        AnimatedContainer(
          duration: AppTokens.duration,
          curve: AppTokens.ease,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: selected ? palette.accent : palette.surface2,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 21,
            color: selected ? palette.accentOn : palette.textMuted,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (sublabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  sublabel!,
                  style: TextStyle(color: palette.textMuted, fontSize: 12.5),
                ),
              ],
            ],
          ),
        ),
        if (hasPreview)
          const SizedBox(width: 84)
        else
          trailing ?? _AnimatedCheck(selected: selected),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.duration,
        curve: AppTokens.ease,
        clipBehavior: hasPreview ? Clip.antiAlias : Clip.none,
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : palette.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(
            color: selected ? palette.accent : palette.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: hasPreview ? StackFit.expand : StackFit.loose,
          children: [
            if (hasPreview)
              Positioned(
                right: 8,
                bottom: -86,
                child: Transform.rotate(
                  angle: -0.10,
                  alignment: Alignment.bottomCenter,
                  child: preview!,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Align(alignment: Alignment.centerLeft, child: row),
            ),
            if (hasPreview && selected)
              Positioned(
                top: 12,
                right: 12,
                child: _AnimatedCheck(selected: selected),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedScale(
      scale: selected ? 1.0 : 0.5,
      duration: AppTokens.duration,
      curve: AppTokens.ease,
      child: AnimatedOpacity(
        opacity: selected ? 1.0 : 0.0,
        duration: AppTokens.duration,
        curve: AppTokens.ease,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: palette.accent,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, size: 15, color: palette.accentOn),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: palette.line, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(
              color: palette.textSubtle,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: palette.line, thickness: 1)),
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
  final _searchFocus = FocusNode();
  String _query = '';
  List<AppLocation> _results = [];
  bool _searching = false;
  bool _detecting = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
  }

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
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final selected = ref.watch(settingsProvider).location;
    final collapsed = _searchFocus.hasFocus;
    final searching = _query.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        AnimatedSize(
          duration: AppTokens.duration,
          curve: AppTokens.ease,
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            duration: AppTokens.duration,
            curve: AppTokens.ease,
            opacity: collapsed ? 0 : 1,
            child: collapsed
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      _SetupHeader(
                        icon: Ionicons.location_outline,
                        title: l10n.t('onboarding.setup.location.title'),
                        subtitle: l10n.t('onboarding.setup.location.subtitle'),
                        compact: true,
                      ),
                      const SizedBox(height: 24),
                      if (selected != null) ...[
                        _SelectCard(
                          icon: Ionicons.location,
                          label: selected.name,
                          sublabel: selected.countryName.isNotEmpty
                              ? selected.countryName
                              : null,
                          selected: true,
                          onTap: () {},
                          trailing: Icon(
                            Ionicons.checkmark_circle,
                            color: palette.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _SelectCard(
                        icon: Ionicons.navigate,
                        label: l10n.t('onboarding.setup.location.detect'),
                        sublabel: _detecting
                            ? l10n.t('onboarding.setup.location.detecting')
                            : l10n.t('onboarding.setup.location.detectHint'),
                        selected: false,
                        onTap: _detecting ? () {} : _detect,
                        trailing: _detecting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: AppSpinner(size: 22),
                              )
                            : Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Ionicons.chevron_back
                                    : Ionicons.chevron_forward,
                                size: 18,
                                color: palette.textMuted,
                              ),
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(
                        l10n.t('onboarding.setup.location.searchManually'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ),
        AppTextField(
          focusNode: _searchFocus,
          hintText: l10n.t('home.searchCity'),
          onTapOutside: (_) => _searchFocus.unfocus(),
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
        if (searching && _searching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: AppSpinner(size: 22)),
          ),
        if (searching && !_searching && _results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                l10n.t('common.noResults'),
                style: TextStyle(color: palette.textMuted),
              ),
            ),
          ),
        if (searching && !_searching && _results.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
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
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 56,
                      color: palette.line,
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Ionicons.chevron_back
                  : Ionicons.chevron_forward,
              size: 18,
              color: palette.textMuted,
            ),
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
        _SetupHeader(
          icon: Ionicons.notifications_outline,
          title: l10n.t('onboarding.setup.notifications.title'),
          subtitle: l10n.t('onboarding.setup.notifications.subtitle'),
        ),
        const SizedBox(height: 28),
        _SelectCard(
          icon: Ionicons.notifications,
          label: l10n.t('onboarding.setup.notifications.enable'),
          selected: enabled,
          onTap: () => toggle(!enabled),
          trailing: IgnorePointer(
            child: AppToggle(value: enabled, onChanged: toggle),
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
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      border: Border.all(color: palette.line),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < prayerKeys.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: palette.line),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
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

const _phoneW = 78.0;
const _phoneH = 150.0;
const _phoneRadius = BorderRadius.vertical(top: Radius.circular(20));

class ThemePreviewPhone extends StatelessWidget {
  const ThemePreviewPhone({super.key, required this.mode});
  final AppThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final auto = mode == AppThemeMode.auto;
    final dark = switch (mode) {
      AppThemeMode.dark => true,
      AppThemeMode.light => false,
      AppThemeMode.auto =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

    return SizedBox(
      width: _phoneW,
      height: _phoneH,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _phoneRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          if (auto) ...[
            ClipPath(
              clipper: _DiagonalClipper(left: true),
              child: const _PhoneFace(dark: false),
            ),
            ClipPath(
              clipper: _DiagonalClipper(left: false),
              child: const _PhoneFace(dark: true),
            ),
          ] else
            _PhoneFace(dark: dark),
        ],
      ),
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  _DiagonalClipper({required this.left});
  final bool left;

  @override
  Path getClip(Size size) {
    final path = Path();
    final dx = size.width * 0.42;
    if (left) {
      path.moveTo(0, 0);
      path.lineTo(size.width * 0.5 + dx, 0);
      path.lineTo(size.width * 0.5 - dx, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width * 0.5 + dx, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width * 0.5 - dx, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_DiagonalClipper old) => old.left != left;
}

class _PhoneFace extends StatelessWidget {
  const _PhoneFace({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppTokens.bgDark : AppTokens.bgLight;
    final surface = dark ? AppTokens.surfaceDark : AppTokens.surfaceLight;
    final line = dark ? AppTokens.lineDark : AppTokens.lineLight;
    final accent = dark ? AppTokens.accentDark : AppTokens.accentLight;
    final accentSoft = dark
        ? AppTokens.accentDarkSoft
        : AppTokens.accentLightSoft;
    final textC = dark ? AppTokens.textDark : AppTokens.textLight;
    final muted = dark ? AppTokens.textSubtleDark : AppTokens.textSubtleLight;
    final frame = dark ? const Color(0xFF2A2F36) : const Color(0xFFCED2D8);

    Widget bar(double w, Color c, [double h = 5]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(99),
      ),
    );

    return Container(
      width: _phoneW,
      height: _phoneH,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: frame, borderRadius: _phoneRadius),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Container(
            width: _phoneW - 10,
            color: bg,
            padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: bar(20, frame, 3)),
                const SizedBox(height: 9),
                bar(34, textC, 6),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(20, accent, 4),
                      const SizedBox(height: 5),
                      bar(40, accent.withValues(alpha: 0.55), 7),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < 3; i++) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        bar(22, muted, 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearanceStep extends ConsumerWidget {
  const _AppearanceStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
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
        _SetupHeader(
          icon: Ionicons.color_palette_outline,
          title: l10n.t('onboarding.setup.appearance.title'),
          subtitle: l10n.t('onboarding.setup.appearance.subtitle'),
        ),
        const SizedBox(height: 24),
        for (final (m, label, icon) in options) ...[
          SizedBox(
            height: 84,
            child: _SelectCard(
              icon: icon,
              label: label,
              selected: mode == m,
              onTap: () => ref.read(settingsProvider.notifier).setTheme(m),
              preview: ThemePreviewPhone(mode: m),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
