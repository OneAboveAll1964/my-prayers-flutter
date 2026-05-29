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

class _OnboardingFlowState extends ConsumerState<OnboardingFlow>
    with WidgetsBindingObserver {
  int _stage = 0; // 0 language, 1 features, 2 setup

  @override
  void initState() {
    super.initState();
    // Onboarding renders outside the router's navigator (see MyPrayersApp's
    // builder), so there's no ModalRoute and PopScope can't hook the back
    // button. Intercept the Android back button / swipe via the binding's
    // pop-route callback instead.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    if (_stage > 0) {
      _toStage(_stage - 1);
      return true; // handled — step back a stage, keep the app open
    }
    return false; // first stage: let the system close the app as usual
  }

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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      // The incoming page dissolves in (with a subtle settle-in scale) on top
      // of the outgoing one, which stays fully opaque underneath. Because the
      // screen is always covered, it never dips to the dark background — it
      // reads as one page transitioning into the next rather than a blackout.
      transitionBuilder: (child, anim) {
        final incoming = child.key == stage.key;
        if (!incoming) return child; // outgoing stays solid beneath
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(anim),
            child: child,
          ),
        );
      },
      child: stage,
    );
  }
}
