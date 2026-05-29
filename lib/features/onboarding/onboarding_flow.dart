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
  bool _forward = true;

  void _toStage(int s) {
    setState(() {
      _forward = s >= _stage;
      _stage = s;
    });
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
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final incoming = child.key == stage.key;
        final dir = _forward ? 1.0 : -1.0;
        final begin = incoming ? Offset(0.14 * dir, 0) : Offset(-0.14 * dir, 0);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        );
      },
      child: stage,
    );
  }
}
