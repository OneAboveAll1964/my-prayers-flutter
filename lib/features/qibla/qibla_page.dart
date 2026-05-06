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
  double? _heading;
  bool _hasCompass = true;

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
      setState(() => _hasCompass = false);
      return;
    }
    _sub = stream.listen((evt) {
      if (!mounted) return;
      if (evt.heading == null) {
        setState(() => _hasCompass = false);
      } else {
        setState(() => _heading = evt.heading);
      }
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
                    const SizedBox(height: 14),
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
    final delta = ((bearing - (_heading ?? 0)) + 360) % 360;
    final aligned = delta < 4 || delta > 356;

    return Column(
      children: [
        PageHeader(title: l10n.t('qibla.title')),
        Expanded(
          child: PageBody(
            children: [
              Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: _CompassView(
                    bearing: bearing,
                    heading: _heading,
                    aligned: aligned,
                  ),
                ),
              ),
              _StatLine(
                label: l10n.t('qibla.bearing'),
                value: '${bearing.toStringAsFixed(1)}°',
              ),
              _StatLine(
                label: l10n.t('qibla.heading'),
                value: _heading == null
                    ? '—'
                    : '${_heading!.toStringAsFixed(1)}°',
              ),
              _StatLine(
                label: l10n.t('qibla.distance'),
                value: '$distance km',
              ),
              if (!_hasCompass)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.t('qibla.noCompass'),
                    style: TextStyle(color: palette.textMuted, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompassView extends StatelessWidget {
  const _CompassView({
    required this.bearing,
    required this.heading,
    required this.aligned,
  });

  final double bearing;
  final double? heading;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final h = heading ?? 0;
    final qiblaAngle = (bearing - h);
    return AnimatedRotation(
      turns: -h / 360.0,
      duration: const Duration(milliseconds: 200),
      curve: AppTokens.ease,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.surface,
          border: Border.all(color: palette.line, width: 1.4),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(280, 280),
              painter: _CompassPainter(
                ringColor: palette.line,
                tickColor: palette.lineStrong,
                northColor: palette.danger,
                textColor: palette.textMuted,
              ),
            ),
            Transform.rotate(
              angle: qiblaAngle * math.pi / 180,
              child: SizedBox(
                width: 280,
                height: 280,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: aligned ? palette.accent : palette.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.ringColor,
    required this.tickColor,
    required this.northColor,
    required this.textColor,
  });

  final Color ringColor;
  final Color tickColor;
  final Color northColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    for (var i = 0; i < 36; i++) {
      final angle = i * 10 * math.pi / 180 - math.pi / 2;
      final p1 = Offset(c.dx + (r - 2) * math.cos(angle),
          c.dy + (r - 2) * math.sin(angle));
      final tickLen = i % 9 == 0 ? 12.0 : 5.0;
      final p2 = Offset(c.dx + (r - 2 - tickLen) * math.cos(angle),
          c.dy + (r - 2 - tickLen) * math.sin(angle));
      final paint = Paint()
        ..color = i == 0 ? northColor : tickColor
        ..strokeWidth = i == 0 ? 2.4 : 1.2;
      canvas.drawLine(p1, p2, paint);
    }

    final labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final angle = i * 90 * math.pi / 180 - math.pi / 2;
      final p = Offset(c.dx + (r - 28) * math.cos(angle),
          c.dy + (r - 28) * math.sin(angle));
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: i == 0 ? northColor : textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.ringColor != ringColor || old.northColor != northColor;
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
      ),
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
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
