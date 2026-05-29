import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/state/settings_provider.dart';
import 'onboarding_features_page.dart';
import 'onboarding_language_page.dart';
import 'onboarding_setup_page.dart';

/// The first-launch onboarding: language → feature carousel → guided setup.
/// Shown by [MyPrayersApp] until `settings.onboardingComplete` is set.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _stage = 0; // 0 language, 1 features, 2 setup

  void _toStage(int s) {
    setState(() => _stage = s);
  }

  void _finish() {
    ref.read(settingsProvider.notifier).setOnboardingComplete(true);
  }

  @override
  Widget build(BuildContext context) {
    final Widget stage = switch (_stage) {
      0 => OnboardingLanguagePage(
          key: const ValueKey('ob-language'),
          onContinue: () => _toStage(1),
        ),
      1 => OnboardingFeaturesPage(
          key: const ValueKey('ob-features'),
          onGetStarted: () => _toStage(2),
          onBack: () => _toStage(0),
        ),
      _ => OnboardingSetupPage(
          key: const ValueKey('ob-setup'),
          onFinish: _finish,
          onBack: () => _toStage(1),
        ),
    };

    // Device/system back steps through onboarding stages rather than closing
    // the app. On the first stage there's nowhere to go, so the pop falls
    // through (default Android behaviour — leaves the app).
    return PopScope(
      canPop: _stage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _toStage(_stage - 1);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        // Soft cross-fade with a subtle settle-in — no directional slide.
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: stage,
      ),
    );
  }
}
