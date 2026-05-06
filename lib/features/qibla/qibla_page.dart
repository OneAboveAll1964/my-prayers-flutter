import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/qibla.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/page_scaffold.dart';

class QiblaPage extends ConsumerStatefulWidget {
  const QiblaPage({super.key});
  @override
  ConsumerState<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends ConsumerState<QiblaPage> {
  StreamSubscription<CompassEvent>? _sub;
  double _heading = 0;
  bool _hasCompass = false;
  bool _streamMissing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _start() {
    final stream = FlutterCompass.events;
    if (stream == null) {
      setState(() => _streamMissing = true);
      return;
    }
    _sub = stream.listen((evt) {
      if (!mounted) return;
      if (evt.heading == null) return;
      setState(() {
        _heading = (evt.heading! + 360) % 360;
        _hasCompass = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final settings = ref.watch(settingsProvider);
    final palette = context.palette;
    final loc = settings.location;

    if (loc == null) {
      return Column(
        children: [
          PageHeader(title: l10n.t('qibla.title')),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.t('home.noLocation'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.textMuted),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: l10n.t('home.searchCity'),
                      onPressed: () => context.push('/settings/location'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final bearing = qiblaBearing(loc.latitude, loc.longitude);
    final distance = distanceToKaabaKm(loc.latitude, loc.longitude);
    final delta = (((bearing - _heading) + 540) % 360) - 180;
    final aligned = _hasCompass && delta.abs() < 4;

    return Column(
      children: [
        PageHeader(title: l10n.t('qibla.title')),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              children: [
                const SizedBox(height: 14),
                Center(
                  child: _Compass(
                    bearing: bearing,
                    heading: _heading,
                    hasCompass: _hasCompass,
                    aligned: aligned,
                  ),
                ),
                const SizedBox(height: 24),
                _StatList(
                  hasCompass: _hasCompass,
                  heading: _heading,
                  bearing: bearing,
                  distance: distance,
                ),
                const Spacer(),
                if (_streamMissing)
                  Text(
                    l10n.t('qibla.noCompass'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.textMuted, fontSize: 13),
                  )
                else
                  Text(
                    aligned ? l10n.t('common.done') : l10n.t('qibla.calibrate'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: aligned ? palette.accent : palette.textMuted,
                      fontSize: 13,
                      fontWeight:
                          aligned ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Compass extends StatelessWidget {
  const _Compass({
    required this.bearing,
    required this.heading,
    required this.hasCompass,
    required this.aligned,
  });

  final double bearing;
  final double heading;
  final bool hasCompass;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppL10n.of(context);

    return LayoutBuilder(builder: (ctx, constraints) {
      final size = math.min(constraints.maxWidth, 340.0);
      final headingShown = hasCompass ? heading : 0.0;
      final needleAngle = (bearing - headingShown);
      final showHeading = hasCompass;

      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: AppTokens.ease,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.surface,
                border: Border.all(
                  color: aligned ? palette.accent : palette.lineStrong,
                  width: aligned ? 2 : 1.4,
                ),
              ),
            ),
            AnimatedRotation(
              duration: const Duration(milliseconds: 220),
              curve: AppTokens.ease,
              turns: -headingShown / 360.0,
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _DialPainter(
                    accent: palette.accent,
                    text: palette.text,
                    textMuted: palette.textMuted,
                    textSubtle: palette.textSubtle,
                    line: palette.line,
                    qiblaBearing: bearing,
                    headingShown: headingShown,
                    kaabaFill: isDark
                        ? const Color(0xFF0A0A0A)
                        : const Color(0xFF111111),
                    kaabaBand: const Color(0xFFC9A14A),
                  ),
                ),
              ),
            ),
            AnimatedRotation(
              duration: const Duration(milliseconds: 220),
              curve: AppTokens.ease,
              turns: needleAngle / 360.0,
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _NeedlePainter(
                    accent: aligned ? palette.accentStrong : palette.accent,
                    tail: palette.surface3,
                    border: palette.lineStrong,
                  ),
                ),
              ),
            ),
            Container(
              width: size * 0.32,
              height: size * 0.32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.surface,
                border: Border.all(color: palette.lineStrong, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    showHeading
                        ? '${headingShown.round() % 360}°'
                        : '${bearing.round()}°',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: size * 0.085,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    showHeading
                        ? l10n.t('qibla.heading').toUpperCase()
                        : l10n.t('qibla.bearing').toUpperCase(),
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -4,
              child: CustomPaint(
                size: const Size(20, 14),
                painter: _TrianglePainter(color: palette.accent),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.accent,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.line,
    required this.qiblaBearing,
    required this.headingShown,
    required this.kaabaFill,
    required this.kaabaBand,
  });

  final Color accent;
  final Color text;
  final Color textMuted;
  final Color textSubtle;
  final Color line;
  final double qiblaBearing;
  final double headingShown;
  final Color kaabaFill;
  final Color kaabaBand;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final innerRing = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, r * 0.82, innerRing);

    for (var i = 0; i < 72; i++) {
      final angle = i * 5 * math.pi / 180 - math.pi / 2;
      final isCardinal = i % 18 == 0;
      final isMajor = i % 6 == 0;
      final tickLen = isCardinal ? 13.0 : (isMajor ? 9.0 : 5.0);
      final p1 = Offset(c.dx + (r - 4) * math.cos(angle),
          c.dy + (r - 4) * math.sin(angle));
      final p2 = Offset(c.dx + (r - 4 - tickLen) * math.cos(angle),
          c.dy + (r - 4 - tickLen) * math.sin(angle));
      final paint = Paint()
        ..strokeWidth = isCardinal ? 1.8 : (isMajor ? 1.3 : 1)
        ..color = isCardinal
            ? text
            : (isMajor
                ? textMuted
                : textSubtle.withValues(alpha: 0.55));
      canvas.drawLine(p1, p2, paint);
    }

    const labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final angle = i * 90 * math.pi / 180 - math.pi / 2;
      final p = Offset(c.dx + (r - 34) * math.cos(angle),
          c.dy + (r - 34) * math.sin(angle));
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: i == 0 ? accent : textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(headingShown * math.pi / 180);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    final qiblaAngle = (qiblaBearing - 90) * math.pi / 180;
    final kaabaCenter = Offset(
      c.dx + (r - 18) * math.cos(qiblaAngle),
      c.dy + (r - 18) * math.sin(qiblaAngle),
    );
    const kaabaW = 18.0;
    const kaabaH = 18.0;
    canvas.save();
    canvas.translate(kaabaCenter.dx, kaabaCenter.dy);
    canvas.rotate(qiblaBearing * math.pi / 180);
    final kaabaRect = Rect.fromCenter(
      center: Offset.zero,
      width: kaabaW,
      height: kaabaH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(kaabaRect, const Radius.circular(2)),
      Paint()..color = kaabaFill,
    );
    final bandRect = Rect.fromLTWH(
      kaabaRect.left + 2,
      -1.5,
      kaabaW - 4,
      3,
    );
    canvas.drawRect(bandRect, Paint()..color = kaabaBand);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.qiblaBearing != qiblaBearing ||
      old.headingShown != headingShown ||
      old.accent != accent;
}

class _NeedlePainter extends CustomPainter {
  _NeedlePainter({
    required this.accent,
    required this.tail,
    required this.border,
  });
  final Color accent;
  final Color tail;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final tipLen = r * 0.72;
    final tailLen = r * 0.72;
    final width = r * 0.09;

    final tip = Path()
      ..moveTo(c.dx, c.dy - tipLen)
      ..lineTo(c.dx + width, c.dy)
      ..lineTo(c.dx - width, c.dy)
      ..close();
    canvas.drawPath(tip, Paint()..color = accent);

    final tailPath = Path()
      ..moveTo(c.dx, c.dy + tailLen)
      ..lineTo(c.dx + width, c.dy)
      ..lineTo(c.dx - width, c.dy)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = tail);

    final outline = Paint()
      ..color = border.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawPath(tip, outline);
    canvas.drawPath(tailPath, outline);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) =>
      old.accent != accent || old.tail != tail;
}

class _StatList extends StatelessWidget {
  const _StatList({
    required this.hasCompass,
    required this.heading,
    required this.bearing,
    required this.distance,
  });

  final bool hasCompass;
  final double heading;
  final double bearing;
  final int distance;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (hasCompass) ...[
            _Row(
              label: l10n.t('qibla.heading'),
              value: '${heading.round() % 360}°',
            ),
            Container(height: 1, color: palette.line),
          ],
          _Row(
            label: l10n.t('qibla.bearing'),
            value: '${bearing.round()}°',
            accent: true,
          ),
          Container(height: 1, color: palette.line),
          _Row(
            label: l10n.t('qibla.distance'),
            value: '$distance km',
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.accent = false,
  });
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: palette.textMuted, fontSize: 13.5),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accent ? palette.accent : palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.17,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
