import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../state/settings_provider.dart';

const _phoneW = 78.0;
const _phoneH = 150.0;
const _phoneRadius = BorderRadius.vertical(top: Radius.circular(20));

class ThemePreviewPhone extends StatelessWidget {
  const ThemePreviewPhone({super.key, required this.mode});
  final AppThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final auto = mode == AppThemeMode.auto;
    final dark = switch (mode) {
      AppThemeMode.dark => true,
      AppThemeMode.light => false,
      AppThemeMode.auto =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

    return SizedBox(
      width: _phoneW,
      height: _phoneH,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _phoneRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          if (auto) ...[
            ClipPath(
              clipper: _DiagonalClipper(left: true),
              child: const _PhoneFace(dark: false),
            ),
            ClipPath(
              clipper: _DiagonalClipper(left: false),
              child: const _PhoneFace(dark: true),
            ),
          ] else
            _PhoneFace(dark: dark),
        ],
      ),
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  _DiagonalClipper({required this.left});
  final bool left;

  @override
  Path getClip(Size size) {
    final path = Path();
    final dx = size.width * 0.42;
    if (left) {
      path.moveTo(0, 0);
      path.lineTo(size.width * 0.5 + dx, 0);
      path.lineTo(size.width * 0.5 - dx, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width * 0.5 + dx, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width * 0.5 - dx, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_DiagonalClipper old) => old.left != left;
}

class _PhoneFace extends StatelessWidget {
  const _PhoneFace({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppTokens.bgDark : AppTokens.bgLight;
    final surface = dark ? AppTokens.surfaceDark : AppTokens.surfaceLight;
    final line = dark ? AppTokens.lineDark : AppTokens.lineLight;
    final accent = dark ? AppTokens.accentDark : AppTokens.accentLight;
    final accentSoft = dark
        ? AppTokens.accentDarkSoft
        : AppTokens.accentLightSoft;
    final textC = dark ? AppTokens.textDark : AppTokens.textLight;
    final muted = dark ? AppTokens.textSubtleDark : AppTokens.textSubtleLight;
    final frame = dark ? const Color(0xFF2A2F36) : const Color(0xFFCED2D8);

    Widget bar(double w, Color c, [double h = 5]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(99),
      ),
    );

    return Container(
      width: _phoneW,
      height: _phoneH,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: frame, borderRadius: _phoneRadius),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Container(
            width: _phoneW - 10,
            color: bg,
            padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: bar(20, frame, 3)),
                const SizedBox(height: 9),
                bar(34, textC, 6),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(20, accent, 4),
                      const SizedBox(height: 5),
                      bar(40, accent.withValues(alpha: 0.55), 7),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < 3; i++) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        bar(22, muted, 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimeFormatSelector extends StatelessWidget {
  const TimeFormatSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimeFormatCard(
            text: '12',
            unit: 'HR',
            ticks: 12,
            selected: value == '12h',
            onTap: () => onChanged('12h'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TimeFormatCard(
            text: '24',
            unit: 'HR',
            ticks: 24,
            selected: value == '24h',
            onTap: () => onChanged('24h'),
          ),
        ),
      ],
    );
  }
}

class _TimeFormatCard extends StatelessWidget {
  const _TimeFormatCard({
    required this.text,
    required this.unit,
    required this.ticks,
    required this.selected,
    required this.onTap,
  });
  final String text;
  final String unit;
  final int ticks;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final on = selected ? palette.accent : palette.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.duration,
        curve: AppTokens.ease,
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : palette.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(
            color: selected ? palette.accent : palette.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: SizedBox(
          width: 76,
          height: 76,
          child: CustomPaint(
            painter: _ClockPainter(
              ticks: ticks,
              ring: selected ? palette.accent : palette.lineStrong,
              tick: selected
                  ? palette.accent.withValues(alpha: 0.6)
                  : palette.line,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: selected ? palette.accentStrong : palette.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    unit,
                    style: TextStyle(
                      color: on,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({required this.ticks, required this.ring, required this.tick});
  final int ticks;
  final Color ring;
  final Color tick;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final tickPaint = Paint()
      ..color = tick
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final major = ticks ~/ 4;
    for (var i = 0; i < ticks; i++) {
      final a = (i / ticks) * 2 * math.pi;
      final outer = radius - 4;
      final inner = radius - (i % major == 0 ? 9 : 6);
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(center + dir * inner, center + dir * outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.ticks != ticks || old.ring != ring || old.tick != tick;
}

class ThemeOptionCard extends StatelessWidget {
  const ThemeOptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.mode,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final AppThemeMode mode;
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
        height: 84,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : palette.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(
            color: selected ? palette.accent : palette.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: 8,
              bottom: -86,
              child: Transform.rotate(
                angle: -0.10,
                alignment: Alignment.bottomCenter,
                child: ThemePreviewPhone(mode: mode),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: AppTokens.duration,
                      curve: AppTokens.ease,
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selected ? palette.accent : palette.surface2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 21,
                        color: selected ? palette.accentOn : palette.textMuted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 15, color: palette.accentOn),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
