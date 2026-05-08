import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/services/mushaf_asset_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/quran.dart';
import '../../../shared/state/settings_provider.dart';
import 'ayah_actions_sheet.dart';

const _linesPerPage = 15;

class MushafView extends ConsumerStatefulWidget {
  const MushafView({
    super.key,
    required this.surah,
    this.initialAyah,
  });

  final Surah surah;
  final int? initialAyah;

  @override
  ConsumerState<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends ConsumerState<MushafView> {
  late int _firstPage;
  late int _lastPage;
  late PageController _pageController;
  String? _selectedKey;
  late Map<String, Ayah> _ayahByKey;

  @override
  void initState() {
    super.initState();
    final pages = widget.surah.ayahs.map((a) => a.page).toList()..sort();
    _firstPage = pages.first;
    _lastPage = pages.last;
    final initialAyah = widget.initialAyah == null
        ? widget.surah.ayahs.first
        : widget.surah.ayahs.firstWhere(
            (a) => a.numberInSurah == widget.initialAyah,
            orElse: () => widget.surah.ayahs.first);
    final initialIdx = (initialAyah.page - _firstPage).clamp(0, _lastPage - _firstPage);
    _pageController = PageController(initialPage: initialIdx);
    _ayahByKey = {
      for (final a in widget.surah.ayahs)
        '${widget.surah.number}:${a.numberInSurah}': a,
    };
    final pageCount = _lastPage - _firstPage + 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAround(initialIdx, pageCount);
    });
  }

  void _preloadAround(int idx, int pageCount) {
    final service = MushafAssetService.instance;
    for (final delta in const [0, 1, -1]) {
      final i = idx + delta;
      if (i < 0 || i >= pageCount) continue;
      final pageNumber = _firstPage + i;
      service.loadFontForPage(pageNumber).catchError((_) => '');
      service.getPageData(pageNumber).catchError((_) =>
          MushafPageData(pageNumber: pageNumber, lines: const []));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleTapAyah(Ayah ayah) {
    setState(() => _selectedKey =
        '${widget.surah.number}:${ayah.numberInSurah}');
    final settings = ref.read(settingsProvider);
    final fontFamily =
        arabicFontFamilies[settings.arabicFont] ?? 'UthmanicHafs';
    showAyahActionsSheet(
      context: context,
      surah: widget.surah,
      ayah: ayah,
      ref: ref,
      fontFamily: fontFamily,
      arScale: settings.arabicFontScale,
    ).whenComplete(() {
      if (!mounted) return;
      setState(() => _selectedKey = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = _lastPage - _firstPage + 1;
    return PageView.builder(
      controller: _pageController,
      itemCount: pageCount,
      reverse: Directionality.of(context) == TextDirection.rtl,
      onPageChanged: (idx) => _preloadAround(idx, pageCount),
      itemBuilder: (ctx, idx) {
        final pageNumber = _firstPage + idx;
        return _MushafPageView(
          pageNumber: pageNumber,
          ayahByKey: _ayahByKey,
          selectedKey: _selectedKey,
          onTapAyah: _handleTapAyah,
          pageIndex: idx,
          totalPages: pageCount,
        );
      },
    );
  }
}

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String _arabicNumber(int n) =>
    n.toString().split('').map((c) => _arabicDigits[int.parse(c)]).join();

String _localeNumber(int n, BuildContext context) {
  final lang = AppL10n.of(context).locale.languageCode;
  if (lang == 'en') return n.toString();
  return _arabicNumber(n);
}

class _MushafPageView extends StatefulWidget {
  const _MushafPageView({
    required this.pageNumber,
    required this.ayahByKey,
    required this.selectedKey,
    required this.onTapAyah,
    required this.pageIndex,
    required this.totalPages,
  });

  final int pageNumber;
  final Map<String, Ayah> ayahByKey;
  final String? selectedKey;
  final void Function(Ayah ayah) onTapAyah;
  final int pageIndex;
  final int totalPages;

  @override
  State<_MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<_MushafPageView> {
  Future<_PageBundle>? _bundleFuture;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _loadBundle(widget.pageNumber);
  }

  Future<_PageBundle> _loadBundle(int pageNumber) async {
    final service = MushafAssetService.instance;
    final results = await Future.wait([
      service.getPageData(pageNumber),
      service.loadFontForPage(pageNumber),
    ]);
    return _PageBundle(
      data: results[0] as MushafPageData,
      fontFamily: results[1] as String,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
            child: Row(
              children: [
                Text(
                  '${l10n.t('quran.juz')} ${_localeNumber(_juzForPage(widget.pageNumber, widget.ayahByKey), context)}',
                  style: TextStyle(
                    color: palette.textSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${l10n.t('quran.page')} ${_localeNumber(widget.pageNumber, context)}',
                  style: TextStyle(
                    color: palette.textSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<_PageBundle>(
              future: _bundleFuture,
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Ionicons.alert_circle_outline,
                              size: 32, color: palette.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            l10n.t('common.error'),
                            style: TextStyle(
                                color: palette.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() {
                              _bundleFuture = _loadBundle(widget.pageNumber);
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: palette.surface2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: palette.line),
                              ),
                              child: Text(
                                l10n.t('common.retry'),
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: palette.accent,
                      ),
                    ),
                  );
                }
                final bundle = snap.data!;
                return _MushafPageContent(
                  bundle: bundle,
                  ayahByKey: widget.ayahByKey,
                  selectedKey: widget.selectedKey,
                  onTapAyah: widget.onTapAyah,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 6),
            child: Center(
              child: Text(
                '${_localeNumber(widget.pageIndex + 1, context)} / ${_localeNumber(widget.totalPages, context)}',
                style: TextStyle(
                  color: palette.textSubtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int _juzForPage(int page, Map<String, Ayah> map) {
  for (final a in map.values) {
    if (a.page == page) return a.juz;
  }
  return 1;
}

class _PageBundle {
  _PageBundle({required this.data, required this.fontFamily});
  final MushafPageData data;
  final String fontFamily;
}

class _MushafPageContent extends StatelessWidget {
  const _MushafPageContent({
    required this.bundle,
    required this.ayahByKey,
    required this.selectedKey,
    required this.onTapAyah,
  });

  final _PageBundle bundle;
  final Map<String, Ayah> ayahByKey;
  final String? selectedKey;
  final void Function(Ayah ayah) onTapAyah;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(builder: (ctx, c) {
      const padH = 12.0;
      final availableWidth = c.maxWidth - padH * 2;
      final lineHeight = c.maxHeight / _linesPerPage;

      const referenceFontSize = 100.0;
      var maxNaturalWidth = 0.0;
      for (final line in bundle.data.lines) {
        final tp = TextPainter(
          text: TextSpan(
            text: line.codes,
            style: TextStyle(
              fontFamily: bundle.fontFamily,
              fontSize: referenceFontSize,
              height: 1.0,
            ),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        if (tp.width > maxNaturalWidth) maxNaturalWidth = tp.width;
      }
      final widthScale =
          maxNaturalWidth == 0 ? 1.0 : availableWidth / maxNaturalWidth;
      final heightScale = lineHeight / referenceFontSize;
      final scale =
          (widthScale < heightScale ? widthScale : heightScale) * 0.95;
      final fontSize = referenceFontSize * scale;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: padH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in bundle.data.lines)
              SizedBox(
                height: lineHeight,
                width: availableWidth,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: _LineWidget(
                      line: line,
                      fontFamily: bundle.fontFamily,
                      fontSize: fontSize,
                      ayahByKey: ayahByKey,
                      selectedKey: selectedKey,
                      onTapAyah: onTapAyah,
                      palette: palette,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _LineWidget extends StatelessWidget {
  const _LineWidget({
    required this.line,
    required this.fontFamily,
    required this.fontSize,
    required this.ayahByKey,
    required this.selectedKey,
    required this.onTapAyah,
    required this.palette,
  });

  final MushafLine line;
  final String fontFamily;
  final double fontSize;
  final Map<String, Ayah> ayahByKey;
  final String? selectedKey;
  final void Function(Ayah ayah) onTapAyah;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < line.words.length; i++) {
      final w = line.words[i];
      final ayah = ayahByKey[w.verseKey];
      final tap = ayah == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onTapAyah(ayah));
      final isSelected = selectedKey == w.verseKey;
      final fillColor = isSelected ? palette.accentSoft : null;
      spans.add(TextSpan(
        text: w.code,
        recognizer: tap,
        style: TextStyle(
          color: ayah == null
              ? palette.textMuted.withValues(alpha: 0.65)
              : (w.isAyahEnd ? palette.accent : palette.text),
          fontFamily: fontFamily,
          fontSize: fontSize,
          height: 1.0,
          background:
              fillColor == null ? null : (Paint()..color = fillColor),
        ),
      ));
      if (i < line.words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(children: spans),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

