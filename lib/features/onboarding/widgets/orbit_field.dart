import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';

/// A single orbiting feature orb.
class OrbSpec {
  const OrbSpec({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

/// A morphing phone mockup with [orbs] orbiting around it on a clean tilted 3D
/// ring. The orb nearest the (continuous, wrapping) [focus] sits at the phone's
/// centre and scales up. A top/bottom-cut "( )" bracket frames it and spins via
/// [bracketTurn] (0→1 = one full turn). The phone morphs between an Android and
/// an iPhone (corner radius + camera cutout) as the focus moves between orbs.
class OrbitField extends StatelessWidget {
  const OrbitField({
    super.key,
    required this.orbs,
    required this.focus,
    this.bracketTurn = 0,
  });

  final List<OrbSpec> orbs;
  final double focus;
  final double bracketTurn;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // 0 = Android, 1 = iPhone, alternating per orb.
  static double _styleOf(int i, int n) =>
      (((i % n) + n) % n).isEven ? 0.0 : 1.0;

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

        final lo = focus.floor();
        final style = _lerp(_styleOf(lo, n), _styleOf(lo + 1, n), focus - lo);
        // Fixed brand-accent bracket — does not change with the focused orb.
        final bracketColor = context.palette.accent;

        final placed = <_Placed>[];
        for (var i = 0; i < n; i++) {
          final angle = (i - focus) * (2 * math.pi / n);
          final depth = math.cos(angle); // 1 = front (centre), -1 = back (top)
          final t = (depth + 1) / 2;

          // Clean tilted ring: orbs stay on the ring and just rotate. The front
          // orb naturally sits at the phone's centre and scales up in place.
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

        // Force the field to fill the width so the Stack's centre matches `cx`.
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              for (final p in placed.where((p) => p.depth < 0)) _orb(p),
              _PhoneMockup(width: phoneW, height: phoneH, style: style),
              // "( )" bracket framing the focused orb; spins on selection change.
              // Drawn under the front orbs so they pass over the arcs while moving.
              Positioned(
                left: cx - base * 0.60,
                top: cy - base * 0.60,
                width: base * 1.20,
                height: base * 1.20,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _BracketPainter(
                        color: bracketColor, turn: bracketTurn),
                  ),
                ),
              ),
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
                Color.lerp(p.orb.color, Colors.white, 0.18)!,
                p.orb.color,
              ],
            ),
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

class _BracketPainter extends CustomPainter {
  _BracketPainter({required this.color, required this.turn});
  final Color color;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 * 0.92;
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const sweep = 1.25; // short arcs (~72° each) → clear "( )", big top/bottom gaps
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(turn * 2 * math.pi);
    canvas.drawArc(rect, -sweep / 2, sweep, false, paint); // right ")"
    canvas.drawArc(rect, math.pi - sweep / 2, sweep, false, paint); // left "("
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.turn != turn || old.color != color;
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({
    required this.width,
    required this.height,
    required this.style, // 0 = Android, 1 = iPhone
  });
  final double width;
  final double height;
  final double style;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final frame = dark ? const Color(0xFF2A2F36) : const Color(0xFFD9DCE1);
    final screenTop = dark ? const Color(0xFF181C21) : const Color(0xFFFFFFFF);
    final screenBottom =
        dark ? const Color(0xFF0E1116) : const Color(0xFFEEF0F3);
    final btn = dark ? const Color(0xFF4A515B) : const Color(0xFFAEB3BA);
    const cutout = Color(0xFF0B0D10);

    final radius = _lerp(width * 0.12, width * 0.2, style); // Android→iPhone
    // Camera: Android punch-hole (small circle) → iPhone Dynamic Island (pill).
    final camW = _lerp(width * 0.05, width * 0.36, style);
    final camH = _lerp(width * 0.05, width * 0.082, style);

    final phone = Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(width * 0.045),
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
        borderRadius: BorderRadius.circular(radius - width * 0.04),
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
              SizedBox(height: height * 0.035),
              Container(
                width: camW,
                height: camH,
                decoration: BoxDecoration(
                  color: cutout,
                  borderRadius: BorderRadius.circular(camH / 2),
                ),
              ),
              const Spacer(),
              Container(
                width: width * 0.32,
                height: 4,
                margin: EdgeInsets.only(bottom: height * 0.03),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget sideButton(double h) => Container(
          width: width * 0.014,
          height: h,
          decoration: BoxDecoration(
            color: btn,
            borderRadius: BorderRadius.circular(4),
          ),
        );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        phone,
        // Volume buttons (left)
        Positioned(
            left: -width * 0.008,
            top: height * 0.22,
            child: sideButton(height * 0.07)),
        Positioned(
            left: -width * 0.008,
            top: height * 0.31,
            child: sideButton(height * 0.07)),
        // Power button (right)
        Positioned(
            right: -width * 0.008,
            top: height * 0.26,
            child: sideButton(height * 0.12)),
      ],
    );
  }
}
