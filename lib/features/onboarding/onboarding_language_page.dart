import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/splash_overlay.dart';
import 'widgets/snap_dissolve.dart';

const _iconSize = 104.0;

class OnboardingLanguagePage extends ConsumerStatefulWidget {
  const OnboardingLanguagePage({super.key, required this.footerKey});
  final GlobalKey<SnapDissolveState> footerKey;

  @override
  ConsumerState<OnboardingLanguagePage> createState() =>
      _OnboardingLanguagePageState();
}

class _OnboardingLanguagePageState extends ConsumerState<OnboardingLanguagePage>
    with SingleTickerProviderStateMixin {
  final _snapKey = GlobalKey<SnapDissolveState>();
  final _circleKey = GlobalKey();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  Offset? _restOffset;

  static const _codes = ['ckb', 'ckb_Badini', 'en', 'ar'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    if (splashFinished.value) {
      _intro.value = 1;
    } else {
      splashFinished.addListener(_onSplash);
    }
  }

  @override
  void dispose() {
    splashFinished.removeListener(_onSplash);
    _intro.dispose();
    super.dispose();
  }

  void _onSplash() {
    if (!splashFinished.value) return;
    splashFinished.removeListener(_onSplash);
    if (mounted) _intro.forward();
  }

  void _measure() {
    final box = _circleKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final restCenter = box.localToGlobal(box.size.center(Offset.zero));
    setState(() => _restOffset = splashIconCenter(context) - restCenter);
  }

  Future<void> _choose(String code, String current) async {
    if (code == current) return;
    await _snapKey.currentState?.prepare();
    await widget.footerKey.currentState?.prepare();
    if (!mounted) return;
    ref.read(settingsProvider.notifier).setLanguage(code);
    _snapKey.currentState?.play();
    widget.footerKey.currentState?.play();
  }

  Widget _circle({double glow = 0}) {
    final palette = context.palette;
    return Container(
      key: _circleKey,
      width: _iconSize,
      height: _iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.28 * glow),
            blurRadius: 36,
            spreadRadius: 2 * glow,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/widget/launch_icon.png',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: palette.accent,
          alignment: Alignment.center,
          child: Icon(Icons.mosque, color: palette.accentOn, size: 48),
        ),
      ),
    );
  }

  Widget _animatedCircle() {
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, _) {
        final glow = Curves.easeIn.transform(
          ((_intro.value - 0.55) / 0.45).clamp(0.0, 1.0),
        );
        final circle = _circle(glow: glow);
        if (_restOffset == null) return circle;
        final c = Curves.easeOutCubic.transform(
          (_intro.value / 0.62).clamp(0.0, 1.0),
        );
        final scale = 1.0 + (splashHandoffSize / _iconSize - 1.0) * (1 - c);
        return Transform.translate(
          offset: Offset(_restOffset!.dx * (1 - c), _restOffset!.dy * (1 - c)),
          child: Transform.scale(scale: scale, child: circle),
        );
      },
    );
  }

  Widget _introContent(Widget child, {double delay = 0}) {
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, c) {
        final start = 0.45 + delay;
        final e = Curves.easeOut.transform(
          ((_intro.value - start) / (1.0 - start)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: e,
          child: Transform.translate(offset: Offset(0, (1 - e) * 18), child: c),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final current =
        ref.watch(settingsProvider).language ??
        langKey(Localizations.localeOf(context));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _animatedCircle(),
          const SizedBox(height: 28),
          _introContent(
            SizedBox(
              width: double.infinity,
              height: 142,
              child: SnapDissolve(
                key: _snapKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.t('onboarding.language.title'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.t('onboarding.language.subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(flex: 1),
          _introContent(
            delay: 0.12,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final code in _codes) ...[
                  _LangPill(
                    label: langDisplayNames[code] ?? code,
                    selected: code == current,
                    onTap: () => _choose(code, current),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.duration,
        curve: AppTokens.ease,
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.accent : palette.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? palette.accentStrong : palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AnimatedScale(
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
                          child: Icon(
                            Icons.check,
                            size: 15,
                            color: palette.accentOn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
