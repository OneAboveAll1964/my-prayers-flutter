import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/state/settings_provider.dart';
import 'widgets/snap_dissolve.dart';

class OnboardingLanguagePage extends ConsumerStatefulWidget {
  const OnboardingLanguagePage({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  ConsumerState<OnboardingLanguagePage> createState() =>
      _OnboardingLanguagePageState();
}

class _OnboardingLanguagePageState
    extends ConsumerState<OnboardingLanguagePage> {
  final _snapKey = GlobalKey<SnapDissolveState>();
  final _btnSnapKey = GlobalKey<SnapDissolveState>();

  static const _codes = ['ckb', 'ckb_Badini', 'en', 'ar'];

  Future<void> _choose(String code, String current) async {
    if (code == current) return;
    // Snapshot the current texts, switch the locale, then dissolve into the new
    // language. Re-triggerable mid-animation — it just snapshots and restarts.
    await _snapKey.currentState?.prepare();
    await _btnSnapKey.currentState?.prepare();
    if (!mounted) return;
    ref.read(settingsProvider.notifier).setLanguage(code);
    _snapKey.currentState?.play();
    _btnSnapKey.currentState?.play();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final current =
        ref.watch(settingsProvider).language ?? langKey(Localizations.localeOf(context));

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                'Sakina',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(flex: 2),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.28),
                      blurRadius: 36,
                      spreadRadius: 2,
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
                    child: Icon(Icons.mosque,
                        color: palette.accentOn, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // The dissolving texts — fixed height so the pills never shift.
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
              const Spacer(flex: 1),
              for (final code in _codes) ...[
                _LangPill(
                  label: langDisplayNames[code] ?? code,
                  selected: code == current,
                  onTap: () => _choose(code, current),
                ),
                const SizedBox(height: 12),
              ],
              const Spacer(flex: 3),
              _ContinueButton(
                snapKey: _btnSnapKey,
                label: l10n.t('onboarding.continue'),
                onPressed: widget.onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Solid accent button (matches AppButton's solid/lg style) whose label text
/// dissolves on change while the pill itself stays put.
class _ContinueButton extends StatefulWidget {
  const _ContinueButton({
    required this.snapKey,
    required this.label,
    required this.onPressed,
  });
  final GlobalKey<SnapDissolveState> snapKey;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: AppTokens.durationFast,
        curve: AppTokens.ease,
        child: AnimatedContainer(
          duration: AppTokens.durationFast,
          curve: AppTokens.ease,
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _down ? palette.accentStrong : palette.accent,
            borderRadius: BorderRadius.circular(999),
          ),
          // Only the label dissolves; the pill stays static.
          child: SnapDissolve(
            key: widget.snapKey,
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.accentOn,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.05,
              ),
            ),
          ),
        ),
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
            if (selected)
              Positioned.fill(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 16),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: AppTokens.duration,
                      curve: AppTokens.ease,
                      builder: (context, t, child) => Opacity(
                        opacity: t,
                        child: Transform.scale(scale: 0.5 + 0.5 * t, child: child),
                      ),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.check, size: 15, color: palette.accentOn),
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
