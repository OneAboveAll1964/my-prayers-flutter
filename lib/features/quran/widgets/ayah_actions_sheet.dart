import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/services/ayah_audio_controller.dart';
import '../../../core/services/surah_name_font_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/data/reciter_catalog.dart';
import '../../../shared/models/quran.dart';
import '../../../shared/state/favorites_provider.dart';
import '../../../shared/state/settings_provider.dart';
import '../../../shared/widgets/app_sheet.dart';
import 'tafsir_sheet.dart';

Future<void> showAyahActionsSheet({
  required BuildContext context,
  required Surah surah,
  required Ayah ayah,
  required WidgetRef ref,
  required String fontFamily,
  required double arScale,
}) async {
  final l10n = AppL10n.of(context);
  final isEn = l10n.locale.languageCode == 'en';
  final title = isEn
      ? '${surah.englishName} · ${ayah.numberInSurah}'
      : '${surah.name} · ${ayah.numberInSurah}';
  final titleWidget = isEn
      ? null
      : SurahNameFont.buildTitle(
          surahNumber: surah.number,
          ayahNumber: ayah.numberInSurah,
          color: context.palette.text,
        );
  while (true) {
    final result = await showAppSheet<String>(
      context: context,
      title: title,
      titleWidget: titleWidget,
      builder: (sheetCtx) => _AyahActionsBody(
        surah: surah,
        ayah: ayah,
        ref: ref,
        l10n: l10n,
        fontFamily: fontFamily,
        arScale: arScale,
      ),
    );
    if (result != 'tafsir') return;
    if (!context.mounted) return;
    await showTafsirSheet(context: context, surah: surah, ayah: ayah);
    if (!context.mounted) return;
  }
}

class _AyahActionsBody extends ConsumerStatefulWidget {
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
  ConsumerState<_AyahActionsBody> createState() => _AyahActionsBodyState();
}

class _AyahActionsBodyState extends ConsumerState<_AyahActionsBody> {
  StreamSubscription<AyahAudioState>? _audioSub;
  AyahAudioState _audio = AyahAudioController.instance.state;

  @override
  void initState() {
    super.initState();
    _audioSub = AyahAudioController.instance.stream.listen((s) {
      if (!mounted) return;
      setState(() => _audio = s);
    });
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    super.dispose();
  }

  bool _isChapterReciterSelected(int reciterId) {
    final cached = ReciterCatalog.cachedAll();
    if (cached == null) return false;
    for (final r in cached) {
      if (r.id == reciterId) return r.isChapterBased;
    }
    return false;
  }

  Future<void> _playOrPick() async {
    final settings = ref.read(settingsProvider);
    final reciterId = settings.selectedReciterId;
    if (reciterId == null) {
      Navigator.of(context).pop();
      context.push('/settings/resources/reciters');
      return;
    }
    if (_isChapterReciterSelected(reciterId)) {
      final l10n = AppL10n.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.t('reciters.chapterOnly')),
          duration: const Duration(seconds: 2),
        ));
      return;
    }
    await AyahAudioController.instance.playAyah(
      reciterId: reciterId,
      surah: widget.surah.number,
      ayah: widget.ayah.numberInSurah,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final surah = widget.surah;
    final ayah = widget.ayah;
    final fontFamily = widget.fontFamily;
    final arScale = widget.arScale;
    final l10n = widget.l10n;
    final ref = widget.ref;
    final fav = ref.watch(favoritesProvider);
    final bookmarked = fav.ayahs
        .any((e) => e.surah == surah.number && e.ayah == ayah.numberInSurah);
    final selectedReciterId =
        ref.watch(settingsProvider.select((s) => s.selectedReciterId));
    final isAudioForThis =
        _audio.isFor(surah.number, ayah.numberInSurah);
    final isPlaying = isAudioForThis && _audio.playing;
    final isLoading = isAudioForThis && _audio.loading;

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
                    fontWeight: ref.watch(settingsProvider
                            .select((s) => s.quranBold))
                        ? FontWeight.w700
                        : FontWeight.normal,
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
                    fontSize: 14 * ref.watch(settingsProvider
                        .select((s) => s.translationFontScale)),
                    height: 1.55,
                    fontWeight: ref.watch(settingsProvider
                            .select((s) => s.translationBold))
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ActionRow(
          icon: isLoading
              ? Ionicons.hourglass_outline
              : (isPlaying
                  ? Ionicons.stop_circle_outline
                  : Ionicons.play_circle_outline),
          activeColor:
              (isPlaying || isLoading) ? palette.accent : palette.textMuted,
          label: selectedReciterId == null
              ? l10n.t('quran.installReciterToPlay')
              : (isLoading
                  ? l10n.t('quran.preparingAudio')
                  : l10n.t('quran.playRecitation')),
          onTap: isLoading ? () {} : _playOrPick,
        ),
        _ActionRow(
          icon: Ionicons.book_outline,
          activeColor: palette.textMuted,
          label: l10n.t('quran.showTafsir'),
          onTap: () => Navigator.of(context).pop('tafsir'),
        ),
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
