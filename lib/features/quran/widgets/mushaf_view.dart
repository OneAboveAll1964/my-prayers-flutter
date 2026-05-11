import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/services/ayah_audio_controller.dart';
import '../../../core/services/mushaf_asset_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/data/quran_repository.dart';
import '../../../shared/models/quran.dart';
import '../../../shared/state/settings_provider.dart';
import 'ayah_actions_sheet.dart';

const _linesPerPage = 15;

class MushafView extends ConsumerStatefulWidget {
  const MushafView({
    super.key,
    required this.pageMap,
    required this.langCode,
    this.initialAyah,
    this.onPageAyahChanged,
    this.onSwitchSurah,
    this.rangeFiltered = false,
    this.startAyah,
    this.endAyah,
  });

  final SurahPageMap pageMap;
  final String langCode;
  final int? initialAyah;
  final void Function(int firstAyahNumberInSurah)? onPageAyahChanged;
  final void Function(int newSurahNumber)? onSwitchSurah;
  final bool rangeFiltered;
  final int? startAyah;
  final int? endAyah;

  @override
  ConsumerState<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends ConsumerState<MushafView> {
  late int _firstPage;
  late int _lastPage;
  late PageController _pageController;
  String? _selectedKey;
  String? _playingKey;
  StreamSubscription<AyahAudioState>? _audioSub;
  int? _lastQueueAyah;
  bool _surahReady = false;
  int _loadedCount = 0;
  int _totalToLoad = 0;

  int get _surahNumber => widget.pageMap.meta.number;

  @override
  void initState() {
    super.initState();
    _firstPage = widget.pageMap.firstPage;
    _lastPage = widget.pageMap.lastPage;
    if (widget.rangeFiltered) {
      final startA = widget.startAyah;
      final endA = widget.endAyah;
      if (startA != null) {
        final p = widget.pageMap.ayahToPage[startA];
        if (p != null) _firstPage = p;
      }
      if (endA != null) {
        final p = widget.pageMap.ayahToPage[endA];
        if (p != null) _lastPage = p;
      }
      if (_lastPage < _firstPage) _lastPage = _firstPage;
    }
    final initialAyahNum = widget.initialAyah ??
        widget.pageMap.firstAyahByPage[_firstPage] ??
        1;
    final initialPage = widget.pageMap.ayahToPage[initialAyahNum] ?? _firstPage;
    final initialIdx =
        (initialPage - _firstPage).clamp(0, _lastPage - _firstPage);
    _pageController = PageController(initialPage: initialIdx);
    _preloadSurah();
    final audioState = AyahAudioController.instance.state;
    if (audioState.surah == _surahNumber && audioState.ayah != null) {
      if (audioState.playing || audioState.loading) {
        _playingKey = '${audioState.surah}:${audioState.ayah}';
      }
      _lastQueueAyah = audioState.ayah;
    }
    _audioSub = AyahAudioController.instance.stream.listen(_onAudio);
  }

  Future<void> _preloadSurah() async {
    final service = MushafAssetService.instance;
    final repo = QuranRepository.instance;
    final pages = <int>[
      for (var p = _firstPage; p <= _lastPage; p++) p,
    ];
    _totalToLoad = pages.length;
    _loadedCount = 0;
    Future<void> loadOne(int p) async {
      try {
        await Future.wait([
          service.loadFontForPage(p),
          service.getPageData(p),
          repo.getAyahsByKeyForPage(p, widget.langCode),
        ]);
        _preShapePage(p);
      } catch (_) {}
      if (!mounted) return;
      setState(() => _loadedCount++);
    }

    const concurrency = 4;
    var next = 0;
    Future<void> worker() async {
      while (next < pages.length) {
        final i = next++;
        await loadOne(pages[i]);
      }
    }

    await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
    if (!mounted) return;
    setState(() => _surahReady = true);
  }

  void _preShapePage(int p) {
    final service = MushafAssetService.instance;
    final font = service.cachedFontFamily(p);
    final pageData = service.cachedPageData(p);
    if (font == null || pageData == null) return;
    final style = TextStyle(
      fontFamily: font,
      fontSize: 24,
      height: 1.4,
    );
    for (final line in pageData.lines) {
      if (line.words.isEmpty) continue;
      for (final w in line.words) {
        final tp = TextPainter(
          text: TextSpan(text: w.code, style: style),
          textDirection: TextDirection.rtl,
        );
        tp.layout();
        tp.dispose();
      }
    }
  }

  void _onAudio(AyahAudioState s) {
    if (!mounted) return;
    final isThisSurah = s.surah == _surahNumber && s.ayah != null;
    final newKey =
        isThisSurah && (s.playing || s.loading) ? '${s.surah}:${s.ayah}' : null;
    if (newKey != _playingKey) {
      setState(() => _playingKey = newKey);
    }
    final ctrl = AyahAudioController.instance;
    if (!ctrl.isQueueActive) return;
    if (!isThisSurah) return;
    if (s.ayah == _lastQueueAyah) return;
    _lastQueueAyah = s.ayah;
    final page = widget.pageMap.ayahToPage[s.ayah!] ?? widget.pageMap.firstPage;
    final targetIdx = (page - _firstPage).clamp(0, _lastPage - _firstPage);
    if (!_pageController.hasClients) return;
    final current = _pageController.page?.round() ?? 0;
    if (current == targetIdx) return;
    _pageController.animateToPage(
      targetIdx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleTapWord(String verseKey, Ayah? ayah) async {
    final parts = verseKey.split(':');
    if (parts.length != 2) return;
    final tappedSurah = int.tryParse(parts[0]);
    final tappedAyah = int.tryParse(parts[1]) ?? 1;
    if (tappedSurah == null) return;

    final repo = QuranRepository.instance;
    SurahMeta meta;
    if (tappedSurah == _surahNumber) {
      meta = widget.pageMap.meta;
    } else {
      final otherMap = await repo.getSurahPageMap(tappedSurah);
      if (!mounted || otherMap == null) return;
      meta = otherMap.meta;
    }
    final resolved =
        ayah ?? await repo.getAyah(tappedSurah, tappedAyah, widget.langCode);
    if (!mounted || resolved == null) return;

    final liteSurah = Surah(
      number: meta.number,
      name: meta.name,
      englishName: meta.englishName,
      englishNameTranslation: meta.englishNameTranslation,
      revelationType: meta.revelationType,
      ayahs: const [],
    );

    final keyToSelect = '${meta.number}:${resolved.numberInSurah}';
    setState(() => _selectedKey = keyToSelect);
    final settings = ref.read(settingsProvider);
    final fontFamily =
        arabicFontFamilies[settings.arabicFont] ?? 'UthmanicHafs';
    if (!mounted) return;
    await showAyahActionsSheet(
      context: context,
      surah: liteSurah,
      ayah: resolved,
      ref: ref,
      fontFamily: fontFamily,
      arScale: settings.arabicFontScale,
    );
    if (!mounted) return;
    setState(() => _selectedKey = null);
  }

  bool _onScrollNotification(Notification n) {
    if (n is ScrollEndNotification && n.depth == 0) {
      final idx = _pageController.page?.round();
      if (idx != null) {
        final pageNumber = _firstPage + idx;
        final firstAyahNum = widget.pageMap.firstAyahByPage[pageNumber] ?? 1;
        widget.onPageAyahChanged?.call(firstAyahNum);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (!_surahReady) {
      final progress = _totalToLoad == 0 ? 0.0 : _loadedCount / _totalToLoad;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: palette.accent,
                backgroundColor: palette.line,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$_loadedCount / $_totalToLoad',
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }
    final pageCount = _lastPage - _firstPage + 1;
    final isLtr = Directionality.of(context) == TextDirection.ltr;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: PageView.builder(
        controller: _pageController,
        itemCount: pageCount,
        allowImplicitScrolling: true,
        reverse: isLtr,
        itemBuilder: (ctx, idx) {
          final pageNumber = _firstPage + idx;
          return RepaintBoundary(
            child: _MushafPageView(
              key: ValueKey<int>(pageNumber),
              pageNumber: pageNumber,
              surahNumber: _surahNumber,
              langCode: widget.langCode,
              selectedKey: _selectedKey ?? _playingKey,
              onTapWord: _handleTapWord,
              pageIndex: idx,
              totalPages: pageCount,
              onSwitchSurah: widget.onSwitchSurah,
              rangeFiltered: widget.rangeFiltered,
              startAyah: widget.startAyah,
              endAyah: widget.endAyah,
            ),
          );
        },
      ),
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
    super.key,
    required this.pageNumber,
    required this.surahNumber,
    required this.langCode,
    required this.selectedKey,
    required this.onTapWord,
    required this.pageIndex,
    required this.totalPages,
    required this.onSwitchSurah,
    required this.rangeFiltered,
    this.startAyah,
    this.endAyah,
  });

  final int pageNumber;
  final int surahNumber;
  final String langCode;
  final String? selectedKey;
  final void Function(String verseKey, Ayah? ayah) onTapWord;
  final int pageIndex;
  final int totalPages;
  final void Function(int newSurahNumber)? onSwitchSurah;
  final bool rangeFiltered;
  final int? startAyah;
  final int? endAyah;

  @override
  State<_MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<_MushafPageView> {
  _PageData? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (!_loadFromCacheSync()) {
      _kickoffLoad();
    }
  }

  bool _loadFromCacheSync() {
    final service = MushafAssetService.instance;
    final cachedFont = service.cachedFontFamily(widget.pageNumber);
    final cachedPage = service.cachedPageData(widget.pageNumber);
    if (cachedFont == null || cachedPage == null) return false;
    final cachedAyahs = QuranRepository.instance
        .cachedAyahsByKeyForPage(widget.pageNumber, widget.langCode);
    if (cachedAyahs == null) return false;
    _data = _buildPageData(cachedPage, cachedFont, cachedAyahs);
    return true;
  }

  _PageData _buildPageData(
      MushafPageData pageData,
      String fontFamily,
      Map<String, Ayah> ayahByKey,
      ) {
    final filtered = _applyRangeFilter(ayahByKey);
    return _PageData(
      fontFamily: fontFamily,
      ayahByKey: filtered,
      lines: _buildVisibleLines(
        pageData: pageData,
        ayahByKey: filtered,
        surahFilter: widget.surahNumber,
        rangeFiltered: widget.rangeFiltered,
      ),
    );
  }

  void _kickoffLoad() {
    _loadAll(widget.pageNumber);
  }

  Future<void> _loadAll(int pageNumber) async {
    final service = MushafAssetService.instance;
    try {
      final results = await Future.wait([
        service.getPageData(pageNumber),
        service.loadFontForPage(pageNumber),
        QuranRepository.instance
            .getAyahsByKeyForPage(pageNumber, widget.langCode),
      ]);
      if (!mounted) return;
      final data = _buildPageData(
        results[0] as MushafPageData,
        results[1] as String,
        results[2] as Map<String, Ayah>,
      );
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Map<String, Ayah> _applyRangeFilter(Map<String, Ayah> source) {
    if (!widget.rangeFiltered) return source;
    final start = widget.startAyah ?? 1;
    final end = widget.endAyah ?? 1 << 30;
    final prefix = '${widget.surahNumber}:';
    return <String, Ayah>{
      for (final entry in source.entries)
        if (entry.key.startsWith(prefix) &&
            entry.value.numberInSurah >= start &&
            entry.value.numberInSurah <= end)
          entry.key: entry.value,
    };
  }

  int _juzForData(_PageData data) {
    for (final a in data.ayahByKey.values) {
      return a.juz;
    }
    return 1;
  }

  Widget _buildBody(AppPalette palette, AppL10n l10n) {
    if (_error != null) {
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
                style: TextStyle(color: palette.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _error = null);
                  _kickoffLoad();
                },
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
    if (_data == null) return const SizedBox.expand();
    return _MushafPageContent(
      fontFamily: _data!.fontFamily,
      lines: _data!.lines,
      ayahByKey: _data!.ayahByKey,
      selectedKey: widget.selectedKey,
      onTapWord: widget.onTapWord,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final juzText = _data == null
        ? ''
        : '${l10n.t('quran.juz')} ${_localeNumber(_juzForData(_data!), context)}';

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(
              children: [
                Text(
                  juzText,
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
          Expanded(child: _buildBody(palette, l10n)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              14 + MediaQuery.of(context).padding.bottom,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: widget.pageIndex == 0 &&
                            widget.surahNumber > 1 &&
                            widget.onSwitchSurah != null
                        ? _SurahNavButton(
                            icon: Ionicons.chevron_forward,
                            onTap: () => widget
                                .onSwitchSurah!(widget.surahNumber - 1),
                          )
                        : null,
                  ),
                  Expanded(
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
                  SizedBox(
                    width: 40,
                    child: widget.pageIndex == widget.totalPages - 1 &&
                            widget.surahNumber < 114 &&
                            widget.onSwitchSurah != null
                        ? _SurahNavButton(
                            icon: Ionicons.chevron_back,
                            onTap: () => widget
                                .onSwitchSurah!(widget.surahNumber + 1),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  _PageData({
    required this.fontFamily,
    required this.lines,
    required this.ayahByKey,
  });
  final String fontFamily;
  final List<List<MushafLineWord>> lines;
  final Map<String, Ayah> ayahByKey;
}

List<List<MushafLineWord>> _buildVisibleLines({
  required MushafPageData pageData,
  required Map<String, Ayah> ayahByKey,
  required int? surahFilter,
  required bool rangeFiltered,
}) {
  final out = <List<MushafLineWord>>[];
  for (final line in pageData.lines) {
    if (line.words.isEmpty) continue;
    if (rangeFiltered) {
      final filtered = <MushafLineWord>[
        for (final w in line.words)
          if (ayahByKey.containsKey(w.verseKey)) w,
      ];
      if (filtered.isEmpty) continue;
      out.add(filtered);
      continue;
    }
    if (surahFilter != null) {
      final prefix = '$surahFilter:';
      var matches = false;
      for (final w in line.words) {
        if (w.verseKey.startsWith(prefix)) {
          matches = true;
          break;
        }
      }
      if (!matches) continue;
    }
    out.add(line.words);
  }
  return out;
}

class _MushafPageContent extends StatelessWidget {
  const _MushafPageContent({
    required this.fontFamily,
    required this.lines,
    required this.ayahByKey,
    required this.selectedKey,
    required this.onTapWord,
  });

  final String fontFamily;
  final List<List<MushafLineWord>> lines;
  final Map<String, Ayah> ayahByKey;
  final String? selectedKey;
  final void Function(String verseKey, Ayah? ayah) onTapWord;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(builder: (ctx, c) {
        const padH = 24.0;
        const padV = 12.0;
        final usableHeight = c.maxHeight - padV * 2;
        final lineHeight = usableHeight / _linesPerPage;
        final fontSize = lineHeight * 0.55;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: padH,
            vertical: padV,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final words in lines)
                SizedBox(
                  height: lineHeight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: _LineWidget(
                      words: words,
                      fontFamily: fontFamily,
                      fontSize: fontSize,
                      ayahByKey: ayahByKey,
                      selectedKey: selectedKey,
                      onTapWord: onTapWord,
                      palette: palette,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _LineWidget extends StatefulWidget {
  const _LineWidget({
    required this.words,
    required this.fontFamily,
    required this.fontSize,
    required this.ayahByKey,
    required this.selectedKey,
    required this.onTapWord,
    required this.palette,
  });

  final List<MushafLineWord> words;
  final String fontFamily;
  final double fontSize;
  final Map<String, Ayah> ayahByKey;
  final String? selectedKey;
  final void Function(String verseKey, Ayah? ayah) onTapWord;
  final AppPalette palette;

  @override
  State<_LineWidget> createState() => _LineWidgetState();
}

class _LineWidgetState extends State<_LineWidget> {
  Widget? _cachedWidget;
  List<MushafLineWord>? _cachedWords;
  String? _cachedSelectedKey;
  AppPalette? _cachedPalette;
  double? _cachedFontSize;
  String? _cachedFontFamily;

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    final selKey = widget.selectedKey;
    final palette = widget.palette;
    final fontSize = widget.fontSize;
    final fontFamily = widget.fontFamily;

    String? effectiveSelKey;
    if (selKey != null) {
      for (final w in words) {
        if (w.verseKey == selKey) {
          effectiveSelKey = selKey;
          break;
        }
      }
    }

    final reuse = _cachedWidget != null &&
        identical(_cachedWords, words) &&
        identical(_cachedPalette, palette) &&
        _cachedSelectedKey == effectiveSelKey &&
        _cachedFontSize == fontSize &&
        _cachedFontFamily == fontFamily;

    if (!reuse) {
      _cachedWidget = _buildLine(
          words, effectiveSelKey, palette, fontSize, fontFamily);
      _cachedWords = words;
      _cachedSelectedKey = effectiveSelKey;
      _cachedPalette = palette;
      _cachedFontSize = fontSize;
      _cachedFontFamily = fontFamily;
    }
    return _cachedWidget!;
  }

  Widget _buildLine(
    List<MushafLineWord> words,
    String? selKey,
    AppPalette palette,
    double fontSize,
    String fontFamily,
  ) {
    final endColor = palette.accent;
    final textColor = palette.text;
    final highlightColor = palette.accentSoft;
    final gap = fontSize * 0.05;
    final extra = fontSize * 0.12;
    final lineH = fontSize * 1.4;

    final textRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < words.length; i++) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onTapWord(
                words[i].verseKey, widget.ayahByKey[words[i].verseKey]),
            child: Text(
              words[i].code,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize,
                height: 1.4,
                color: words[i].isAyahEnd ? endColor : textColor,
              ),
            ),
          ),
          if (i < words.length - 1) SizedBox(width: gap, height: lineH),
        ],
      ],
    );

    if (selKey == null) {
      return textRow;
    }

    final highlightRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < words.length; i++) ...[
          CustomPaint(
            painter: words[i].verseKey == selKey
                ? _LineHighlightPainter(
                    color: highlightColor, extra: extra)
                : null,
            child: Text(
              words[i].code,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize,
                height: 1.4,
                color: const Color(0x00000000),
              ),
            ),
          ),
          if (i < words.length - 1) SizedBox(width: gap, height: lineH),
        ],
      ],
    );

    return Stack(
      alignment: Alignment.center,
      children: [highlightRow, textRow],
    );
  }
}

class _LineHighlightPainter extends CustomPainter {
  _LineHighlightPainter({required this.color, required this.extra});

  final Color color;
  final double extra;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTRB(-extra, 0, size.width + extra, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _LineHighlightPainter old) {
    return color != old.color || extra != old.extra;
  }
}

class _SurahNavButton extends StatelessWidget {
  const _SurahNavButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.line),
        ),
        child: Icon(icon,
            size: 18, color: palette.text, textDirection: TextDirection.ltr),
      ),
    );
  }
}