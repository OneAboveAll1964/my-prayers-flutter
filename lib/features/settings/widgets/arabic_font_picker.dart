import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/state/settings_provider.dart';
import 'package:ionicons/ionicons.dart';

class ArabicFontPicker extends ConsumerWidget {
  const ArabicFontPicker({super.key});

  static const _previewText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final fonts = arabicFontFamilies.entries.toList();
    final scale = settings.arabicFontScale;
    final trScale = settings.translationFontScale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in fonts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref
                  .read(settingsProvider.notifier)
                  .setArabicFont(entry.key),
              child: AnimatedContainer(
                duration: AppTokens.durationFast,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border.all(
                    color: settings.arabicFont == entry.key
                        ? palette.accent
                        : palette.line,
                    width: settings.arabicFont == entry.key ? 1.4 : 1,
                  ),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            arabicFontLabels[entry.key] ?? entry.key,
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (settings.arabicFont == entry.key)
                          Icon(Ionicons.checkmark,
                              size: 18, color: palette.accent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          _previewText,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 22 * scale,
                            height: 1.7,
                            fontFamily: entry.value,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                l10n.t('settings.arabicFontSize'),
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(scale * 100).round()}%',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: palette.accent,
            inactiveTrackColor: palette.line,
            thumbColor: palette.accent,
            overlayColor: palette.accentSoft,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: scale.clamp(0.7, 1.6),
            min: 0.7,
            max: 1.6,
            divisions: 18,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setArabicFontScale(v),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                l10n.t('settings.translationFontSize'),
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(trScale * 100).round()}%',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: palette.accent,
            inactiveTrackColor: palette.line,
            thumbColor: palette.accent,
            overlayColor: palette.accentSoft,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: trScale.clamp(0.7, 1.6),
            min: 0.7,
            max: 1.6,
            divisions: 18,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .setTranslationFontScale(v),
          ),
        ),
      ],
    );
  }
}
