import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/state/settings_provider.dart';
import 'widgets/snap_dissolve.dart';

class OnboardingLanguagePage extends ConsumerStatefulWidget {
  const OnboardingLanguagePage({super.key, required this.footerKey});
  final GlobalKey<SnapDissolveState> footerKey;

  @override
  ConsumerState<OnboardingLanguagePage> createState() =>
      _OnboardingLanguagePageState();
}

class _OnboardingLanguagePageState
    extends ConsumerState<OnboardingLanguagePage> {
  final _snapKey = GlobalKey<SnapDissolveState>();

  static const _codes = ['ckb', 'ckb_Badini', 'en', 'ar'];

  Future<void> _choose(String code, String current) async {
    if (code == current) return;
    await _snapKey.currentState?.prepare();
    await widget.footerKey.currentState?.prepare();
    if (!mounted) return;
    ref.read(settingsProvider.notifier).setLanguage(code);
    _snapKey.currentState?.play();
    widget.footerKey.currentState?.play();
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
                child: Icon(Icons.mosque, color: palette.accentOn, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 28),
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
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 16),
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
