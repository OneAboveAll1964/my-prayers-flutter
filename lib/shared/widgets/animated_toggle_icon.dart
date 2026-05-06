import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// An icon that animates between an "off" and "on" state with a scale pop,
/// color tween, and a subtle accent-soft halo behind the glyph when active.
/// Works with stroke-only icon sets (Lucide) where there's no separate
/// filled glyph — the halo + color shift carry the "filled" feeling.
class AnimatedToggleIcon extends StatelessWidget {
  const AnimatedToggleIcon({
    super.key,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    this.size = 20,
    this.haloColor,
  });

  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final Color? haloColor;

  @override
  Widget build(BuildContext context) {
    final halo = haloColor ?? activeColor.withValues(alpha: 0.18);
    final boxSize = size * 1.85;
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: AppTokens.ease,
            width: active ? boxSize : 0,
            height: active ? boxSize : 0,
            decoration: BoxDecoration(
              color: halo,
              shape: BoxShape.circle,
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: active ? 1.0 : 0.92, end: active ? 1.0 : 0.92),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (ctx, t, child) =>
                Transform.scale(scale: t, child: child),
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: active ? activeColor : inactiveColor,
                end: active ? activeColor : inactiveColor,
              ),
              duration: const Duration(milliseconds: 220),
              builder: (ctx, c, _) => Icon(icon, size: size, color: c),
            ),
          ),
        ],
      ),
    );
  }
}
