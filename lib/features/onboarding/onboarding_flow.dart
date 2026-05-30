import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/state/settings_provider.dart';
import 'onboarding_features_page.dart';
import 'onboarding_language_page.dart';
import 'onboarding_setup_page.dart';
import 'widgets/snap_dissolve.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _setupSteps = 3;

  int _stage = 0;
  int _setupStep = 0;
  int? _outgoing;

  final _languageKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _setupKey = GlobalKey();
  final _footerKey = GlobalKey<SnapDissolveState>();

  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _fade,
    curve: Curves.easeOut,
  );
  late final Animation<double> _scaleIn = Tween<double>(
    begin: 0.98,
    end: 1.0,
  ).animate(_fadeIn);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fade.dispose();
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async => _back();

  bool _back() {
    if (_stage == 2 && _setupStep > 0) {
      _change(2, _setupStep - 1);
      return true;
    }
    if (_stage > 0) {
      _change(_stage - 1, 0);
      return true;
    }
    return false;
  }

  void _forward() {
    if (_stage < 2) {
      _change(_stage + 1, 0);
    } else if (_setupStep < _setupSteps - 1) {
      _change(2, _setupStep + 1);
    } else {
      ref.read(settingsProvider.notifier).setOnboardingComplete(true);
    }
  }

  Future<void> _change(int stage, int step) async {
    if (stage == _stage && step == _setupStep) return;
    await _footerKey.currentState?.prepare();
    if (!mounted) return;
    final stageChanged = stage != _stage;
    setState(() {
      if (stageChanged) _outgoing = _stage;
      _stage = stage;
      _setupStep = step;
    });
    _footerKey.currentState?.play();
    if (stageChanged) {
      _fade.forward(from: 0).whenComplete(() {
        if (mounted && _fade.value == 1) setState(() => _outgoing = null);
      });
    }
  }

  Widget _pageFor(int stage) => switch (stage) {
    0 => OnboardingLanguagePage(key: _languageKey, footerKey: _footerKey),
    1 => OnboardingFeaturesPage(key: _featuresKey, onBack: _back),
    _ => OnboardingSetupPage(key: _setupKey, step: _setupStep, onBack: _back),
  };

  String _footerLabel(AppL10n l10n) {
    if (_stage == 0) return l10n.t('onboarding.continue');
    if (_stage == 1) return l10n.t('onboarding.getStarted');
    return _setupStep < _setupSteps - 1
        ? l10n.t('onboarding.next')
        : l10n.t('onboarding.finish');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_outgoing != null) _pageFor(_outgoing!),
                  FadeTransition(
                    opacity: _fadeIn,
                    child: ScaleTransition(
                      scale: _scaleIn,
                      child: _pageFor(_stage),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: _FooterButton(
                snapKey: _footerKey,
                label: _footerLabel(l10n),
                onPressed: _forward,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatefulWidget {
  const _FooterButton({
    required this.snapKey,
    required this.label,
    required this.onPressed,
  });
  final GlobalKey<SnapDissolveState> snapKey;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_FooterButton> createState() => _FooterButtonState();
}

class _FooterButtonState extends State<_FooterButton> {
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
