import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_button.dart';
import 'widgets/orbit_field.dart';
import 'widgets/snap_dissolve.dart';

class _Feature {
  const _Feature(this.spec, this.titleKey, this.subKey);
  final OrbSpec spec;
  final String titleKey;
  final String subKey;
}

const _features = <_Feature>[
  _Feature(OrbSpec(icon: Ionicons.time_outline, color: Color(0xFF2E7C4F)),
      'onboarding.feature.prayer.title', 'onboarding.feature.prayer.subtitle'),
  _Feature(OrbSpec(icon: Ionicons.compass_outline, color: Color(0xFF1C9E8E)),
      'onboarding.feature.qibla.title', 'onboarding.feature.qibla.subtitle'),
  _Feature(OrbSpec(icon: Ionicons.book_outline, color: Color(0xFFC68B38)),
      'onboarding.feature.quran.title', 'onboarding.feature.quran.subtitle'),
  _Feature(OrbSpec(icon: Ionicons.apps_outline, color: Color(0xFF7A6CC4)),
      'onboarding.feature.more.title', 'onboarding.feature.more.subtitle'),
];

class OnboardingFeaturesPage extends StatefulWidget {
  const OnboardingFeaturesPage({
    super.key,
    required this.onGetStarted,
    required this.onBack,
  });
  final VoidCallback onGetStarted;
  final VoidCallback onBack;

  @override
  State<OnboardingFeaturesPage> createState() => _OnboardingFeaturesPageState();
}

class _OnboardingFeaturesPageState extends State<OnboardingFeaturesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snap =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Animation<double> _focusAnim = const AlwaysStoppedAnimation(0);

  // Continuous, unbounded orbit index. Orb angles are periodic so it wraps
  // naturally (circular). The displayed feature is `_focus` rounded, mod N.
  double _focus = 0;
  int _displayIndex = 0;
  final _textSnapKey = GlobalKey<SnapDissolveState>();

  static const _pxPerStep = 350.0; // drag distance for one orb step

  @override
  void initState() {
    super.initState();
    _snap.addListener(() {
      setState(() => _focus = _focusAnim.value);
      _syncText();
    });
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  int get _index {
    final n = _features.length;
    return ((_focus.round() % n) + n) % n;
  }

  /// Dissolves the title/subtitle to the focused feature when it changes —
  /// the same stretch-blur transition as the language page.
  Future<void> _syncText() async {
    if (_index == _displayIndex) return;
    await _textSnapKey.currentState?.prepare();
    if (!mounted) return;
    setState(() => _displayIndex = _index);
    _textSnapKey.currentState?.play();
  }

  void _settleTo(double target) {
    _focusAnim = Tween<double>(begin: _focus, end: target)
        .animate(CurvedAnimation(parent: _snap, curve: Curves.easeOutCubic));
    _snap.forward(from: 0);
  }

  void _onDragStart(DragStartDetails _) => _snap.stop();

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _focus -= (d.primaryDelta ?? 0) / _pxPerStep);
    _syncText();
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    // Carry a little momentum, then snap to the nearest orb.
    _settleTo((_focus - v / 1600).roundToDouble());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final orbs = [for (final f in _features) f.spec];

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        // Swipe anywhere to circulate the orbs.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppIconButton(
                        icon: Ionicons.arrow_back,
                        onPressed: widget.onBack,
                        color: palette.text,
                      ),
                    ),
                    Text('Sakina',
                        style: TextStyle(
                            color: palette.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: OrbitField(orbs: orbs, focus: _focus),
              ),
              // Title + subtitle — dissolves between features (fixed height so
              // nothing below shifts).
              SizedBox(
                width: double.infinity,
                height: 150,
                child: SnapDissolve(
                  key: _textSnapKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.t(_features[_displayIndex].titleKey),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.t(_features[_displayIndex].subKey),
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _features.length; i++)
                    AnimatedContainer(
                      duration: AppTokens.duration,
                      curve: AppTokens.ease,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _displayIndex ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _displayIndex ? palette.accent : palette.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: AppButton(
                  label: l10n.t('onboarding.getStarted'),
                  size: AppButtonSize.lg,
                  expand: true,
                  onPressed: widget.onGetStarted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
