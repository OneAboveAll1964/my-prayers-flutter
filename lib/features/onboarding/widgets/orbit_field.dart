import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';

/// A single orbiting feature orb.
class OrbSpec {
  const OrbSpec({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

/// A phone mockup with [orbs] orbiting around its centre on a tilted 3D ring.
/// The orb nearest the (continuous, wrapping) [focus] index is pulled into the
/// phone's centre, enlarged and in front; the rest sit symmetrically around the
/// phone — some behind (smaller/dimmer), some in front. Rendered with
/// [Clip.none] so nothing is clipped.
class OrbitField extends StatelessWidget {
  const OrbitField({
    super.key,
    required this.orbs,
    required this.focus,
    this.wordmark = 'سَكِينَة',
  });

  final List<OrbSpec> orbs;
  final double focus;
  final String wordmark;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final phoneW = math.min(w * 0.44, h * 0.40);
        final phoneH = phoneW * 2.0;
        final cx = w / 2;
        final cy = h / 2;
        final rx = phoneW * 0.75; // horizontal ring radius
        final ry = phoneH * 0.12; // vertical (perspective) radius
        final base = phoneW * 0.54; // focused-orb diameter
        final n = orbs.length;

        final placed = <_Placed>[];
        for (var i = 0; i < n; i++) {
          final angle = (i - focus) * (2 * math.pi / n);
          final depth = math.cos(angle); // 1 = front (centre), -1 = back (top)
          final t = (depth + 1) / 2;

          // Clean tilted ring: orbs stay on the ring and just rotate. The front
          // orb naturally sits at the phone's centre and scales up in place;
          // the rest arc up and around behind it. No pulling/collapsing.
          placed.add(_Placed(
            orb: orbs[i],
            x: cx + rx * math.sin(angle),
            y: cy - ry * (1 - math.cos(angle)),
            size: base * _lerp(0.3, 1.0, t),
            opacity: _lerp(0.75, 1.0, t).clamp(0.0, 1.0),
            depth: depth,
          ));
        }
        placed.sort((a, b) => a.depth.compareTo(b.depth));

        // Force the field to fill the width so the Stack's centre matches `cx`
        // (otherwise loose constraints shrink it to the phone and the orbs, laid
        // out from the full-width centre, end up shoved to one side).
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              for (final p in placed.where((p) => p.depth < 0)) _orb(p),
              _PhoneMockup(width: phoneW, height: phoneH, wordmark: wordmark),
              for (final p in placed.where((p) => p.depth >= 0)) _orb(p),
            ],
          ),
        );
      },
    );
  }

  Widget _orb(_Placed p) {
    return Positioned(
      left: p.x - p.size / 2,
      top: p.y - p.size / 2,
      width: p.size,
      height: p.size,
      child: Opacity(
        opacity: p.opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(p.orb.color, Colors.white, 0.20)!,
                p.orb.color,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: p.orb.color.withValues(alpha: 0.40 * p.opacity),
                blurRadius: p.size * 0.30,
                offset: Offset(0, p.size * 0.10),
              ),
            ],
          ),
          child: Center(
            child: Icon(p.orb.icon, size: p.size * 0.46, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Placed {
  _Placed({
    required this.orb,
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.depth,
  });
  final OrbSpec orb;
  final double x, y, size, opacity, depth;
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({
    required this.width,
    required this.height,
    required this.wordmark,
  });
  final double width;
  final double height;
  final String wordmark;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware device: dark phone in dark mode, light phone in light mode.
    final frame = dark ? const Color(0xFF2A2F36) : const Color(0xFFD9DCE1);
    final screenTop = dark ? const Color(0xFF181C21) : const Color(0xFFFFFFFF);
    final screenBottom =
        dark ? const Color(0xFF0E1116) : const Color(0xFFEEF0F3);
    final chrome = dark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.18);
    final radius = width * 0.15; // sharp-ish corners

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: frame,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.18),
            blurRadius: 34,
            spreadRadius: 1,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - width * 0.035),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [screenTop, screenBottom],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: height * 0.05),
              Container(
                width: width * 0.05,
                height: width * 0.05,
                decoration: BoxDecoration(
                  color: chrome,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(height: height * 0.045),
              Text(
                wordmark,
                style: TextStyle(
                  color: palette.accent.withValues(alpha: 0.9),
                  fontSize: width * 0.13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                width: width * 0.32,
                height: 4,
                margin: EdgeInsets.only(bottom: height * 0.03),
                decoration: BoxDecoration(
                  color: chrome,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
