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
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);
    final tasbih = fav.tasbih;
    final infinite = tasbih.target < 0;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l10n.t('tasbih.title'), back: true),
            Expanded(
              child: LayoutBuilder(builder: (ctx, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: SegmentedControl<int>(
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
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => setState(() => _down = true),
                      onTapCancel: () => setState(() => _down = false),
                      onTapUp: (_) => setState(() => _down = false),
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
                      child: AnimatedScale(
                        scale: _down ? 0.96 : 1,
                        duration: AppTokens.durationFast,
                        curve: AppTokens.ease,
                        child: AnimatedContainer(
                          duration: AppTokens.durationFast,
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _down
                                ? palette.accentStrong
                                : palette.accent,
                            border: Border.all(
                              color: palette.accentStrong,
                              width: 6,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${tasbih.count}',
                                style: TextStyle(
                                  color: palette.accentOn,
                                  fontSize: 88,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  letterSpacing: -2,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                infinite ? '∞' : '${tasbih.target}',
                                style: TextStyle(
                                  color: palette.accentOn
                                      .withValues(alpha: 0.85),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.t('tasbih.tap'),
                      style: TextStyle(color: palette.textMuted, fontSize: 13),
                    ),
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.t('tasbih.total'),
                              style: TextStyle(
                                  color: palette.textMuted, fontSize: 13.5),
                            ),
                          ),
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
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Row(
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
                    ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
