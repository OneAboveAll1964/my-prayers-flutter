import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/segmented_control.dart';

class TasbihPage extends ConsumerStatefulWidget {
  const TasbihPage({super.key});
  @override
  ConsumerState<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends ConsumerState<TasbihPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);
    final tasbih = fav.tasbih;
    final infinite = tasbih.target < 0;
    final progress = infinite
        ? 0.0
        : tasbih.target == 0
            ? 0.0
            : (tasbih.count / tasbih.target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l10n.t('tasbih.title'), back: true),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  children: [
                    SegmentedControl<int>(
                      value: tasbih.target,
                      options: const [
                        SegmentedOption(value: 33, label: '33'),
                        SegmentedOption(value: 99, label: '99'),
                        SegmentedOption(value: 100, label: '100'),
                        SegmentedOption(value: -1, label: '∞'),
                      ],
                      onChanged: (v) => ref
                          .read(favoritesProvider.notifier)
                          .setTasbih(tasbih.copyWith(target: v)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final next = tasbih.count + 1;
                        final reset = !infinite && next > tasbih.target;
                        ref.read(favoritesProvider.notifier).setTasbih(
                              tasbih.copyWith(
                                count: reset ? 1 : next,
                                total: tasbih.total + 1,
                              ),
                            );
                      },
                      child: SizedBox(
                        width: 250,
                        height: 250,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(250, 250),
                              painter: _BeadPainter(
                                ringColor: palette.line,
                                progressColor: palette.accent,
                                progress: progress,
                              ),
                            ),
                            Container(
                              width: 200,
                              height: 200,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.surface,
                                border: Border.all(color: palette.line),
                              ),
                              child: Text(
                                '${tasbih.count}',
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 56,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.t('tasbih.tap'),
                      style: TextStyle(color: palette.textMuted, fontSize: 13),
                    ),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radius),
                        border: Border.all(color: palette.line),
                      ),
                      child: Row(
                        children: [
                          Text(
                            l10n.t('tasbih.total'),
                            style: TextStyle(
                                color: palette.textMuted, fontSize: 13.5),
                          ),
                          const Spacer(),
                          Text(
                            '${tasbih.total}',
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: l10n.t('tasbih.reset'),
                            variant: AppButtonVariant.outline,
                            expand: true,
                            onPressed: () {
                              ref
                                  .read(favoritesProvider.notifier)
                                  .setTasbih(tasbih.copyWith(count: 0));
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            label: l10n.t('tasbih.resetAll'),
                            variant: AppButtonVariant.danger,
                            expand: true,
                            onPressed: () {
                              ref.read(favoritesProvider.notifier).setTasbih(
                                  tasbih.copyWith(count: 0, total: 0));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeadPainter extends CustomPainter {
  _BeadPainter({
    required this.ringColor,
    required this.progressColor,
    required this.progress,
  });

  final Color ringColor;
  final Color progressColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;

    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(c, r, ring);

    if (progress > 0) {
      final fill = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      const start = -1.5708;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        6.2832 * progress,
        false,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_BeadPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}
