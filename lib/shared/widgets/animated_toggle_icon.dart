import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// Cross-fades + scale-pops between an outline glyph (off) and a filled
/// glyph (on). Use with paired Ionicons like `star_outline` + `star` for
/// a real fill animation on toggle.
class AnimatedToggleIcon extends StatelessWidget {
  const AnimatedToggleIcon({
    super.key,
    required this.outlineIcon,
    required this.filledIcon,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    this.size = 22,
  });

  final IconData outlineIcon;
  final IconData filledIcon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      child: Icon(
        active ? filledIcon : outlineIcon,
        key: ValueKey(active),
        size: size,
        color: active ? activeColor : inactiveColor,
      ),
    );
  }
}

/// Compatibility helper used by older call-sites that only know one icon.
/// Falls back to using the same icon for both states with a color fade.
class AnimatedColorIcon extends StatelessWidget {
  const AnimatedColorIcon({
    super.key,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    this.size = 22,
  });

  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: active ? activeColor : inactiveColor,
        end: active ? activeColor : inactiveColor,
      ),
      duration: const Duration(milliseconds: 200),
      curve: AppTokens.ease,
      builder: (ctx, c, _) => Icon(icon, size: size, color: c),
    );
  }
}
