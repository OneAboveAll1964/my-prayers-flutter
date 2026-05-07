import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/quran.dart';
import '../../../shared/state/favorites_provider.dart';
import '../../../shared/widgets/app_sheet.dart';

Future<void> showAyahActionsSheet({
  required BuildContext context,
  required Surah surah,
  required Ayah ayah,
  required WidgetRef ref,
  required String fontFamily,
  required double arScale,
}) {
  final l10n = AppL10n.of(context);
  final isEn = l10n.locale.languageCode == 'en';
  final title = isEn
      ? '${surah.englishName} · ${ayah.numberInSurah}'
      : '${surah.name} · ${ayah.numberInSurah}';
  return showAppSheet(
    context: context,
    title: title,
    builder: (sheetCtx) => _AyahActionsBody(
      surah: surah,
      ayah: ayah,
      ref: ref,
      l10n: l10n,
      fontFamily: fontFamily,
      arScale: arScale,
    ),
  );
}

class _AyahActionsBody extends StatelessWidget {
  const _AyahActionsBody({
    required this.surah,
    required this.ayah,
    required this.ref,
    required this.l10n,
    required this.fontFamily,
    required this.arScale,
  });

  final Surah surah;
  final Ayah ayah;
  final WidgetRef ref;
  final AppL10n l10n;
  final String fontFamily;
  final double arScale;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);
    final bookmarked = fav.ayahs
        .any((e) => e.surah == surah.number && e.ayah == ayah.numberInSurah);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(color: palette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  ayah.arabic,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 20 * arScale,
                    height: 2.0,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              if (ayah.translation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ayah.translation,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ActionRow(
          icon: bookmarked ? Ionicons.bookmark : Ionicons.bookmark_outline,
          activeColor: bookmarked ? palette.accent : palette.textMuted,
          label: bookmarked
              ? l10n.t('quran.removeBookmark')
              : l10n.t('quran.bookmark'),
          onTap: () {
            ref.read(favoritesProvider.notifier).toggleBookmarkAyah(
                  surah.number,
                  ayah.numberInSurah,
                  surahName: surah.englishName,
                  arabicName: surah.name,
                  preview: ayah.arabic,
                );
            Navigator.of(context).pop();
          },
        ),
        _ActionRow(
          icon: Ionicons.copy_outline,
          activeColor: palette.textMuted,
          label: l10n.t('quran.copyArabic'),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: ayah.arabic));
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
        ),
        if (ayah.translation.isNotEmpty)
          _ActionRow(
            icon: Ionicons.text_outline,
            activeColor: palette.textMuted,
            label: l10n.t('quran.copyTranslation'),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: ayah.translation));
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        _ActionRow(
          icon: Ionicons.share_outline,
          activeColor: palette.textMuted,
          label: l10n.t('quran.copyBoth'),
          onTap: () async {
            final text = ayah.translation.isEmpty
                ? '${ayah.arabic}\n— ${surah.englishName} ${ayah.numberInSurah}'
                : '${ayah.arabic}\n${ayah.translation}\n— ${surah.englishName} ${ayah.numberInSurah}';
            await Clipboard.setData(ClipboardData(text: text));
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _ActionRow extends StatefulWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _down ? palette.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 20, color: widget.activeColor),
            const SizedBox(width: 14),
            Text(
              widget.label,
              style: TextStyle(
                color: palette.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
