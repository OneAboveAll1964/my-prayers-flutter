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
  Timer? _preloadTimer;
  StreamSubscription<AyahAudioState>? _audioSub;
  int? _lastQueueAyah;

  int get _surahNumber => widget.pageMap.meta.number;

  @override
  void initState() {
    super.initState();
    _firstPage = widget.pageMap.firstPage;
    _lastPage = widget.pageMap.lastPage;
    final initialAyahNum = widget.initialAyah ??
        widget.pageMap.firstAyahByPage[widget.pageMap.firstPage] ??
        1;
    final initialPage = widget.pageMap.ayahToPage[initialAyahNum] ??
        widget.pageMap.firstPage;
    final initialIdx =
        (initialPage - _firstPage).clamp(0, _lastPage - _firstPage);
    _pageController = PageController(initialPage: initialIdx);
    final pageCount = _lastPage - _firstPage + 1;
    _scheduleSettledPreload(initialIdx, pageCount,
        delay: const Duration(milliseconds: 400));
    final audioState = AyahAudioController.instance.state;
    if (audioState.surah == _surahNumber && audioState.ayah != null) {
      if (audioState.playing || audioState.loading) {
        _playingKey = '${audioState.surah}:${audioState.ayah}';
      }
      _lastQueueAyah = audioState.ayah;
    }
    _audioSub = AyahAudioController.instance.stream.listen(_onAudio);
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

  void _scheduleSettledPreload(
      int idx,
      int pageCount, {
        Duration delay = const Duration(milliseconds: 400),
      }) {
    _preloadTimer?.cancel();
    _preloadTimer = Timer(delay, () {
      if (!mounted) return;
      _preloadNeighbours(idx, pageCount);
    });
  }

  void _preloadNeighbours(int idx, int pageCount) {
    final service = MushafAssetService.instance;
    for (final delta in const [1, -1, 2, -2]) {
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
    _audioSub?.cancel();
    _preloadTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final pageCount = _lastPage - _firstPage + 1;
    final isLtr = Directionality.of(context) == TextDirection.ltr;
    return PageView.builder(
      controller: _pageController,
      itemCount: pageCount,
      allowImplicitScrolling: true,
      reverse: isLtr,
      onPageChanged: (idx) {
        final pageNumber = _firstPage + idx;
        final firstAyahNum = widget.pageMap.firstAyahByPage[pageNumber] ?? 1;
        widget.onPageAyahChanged?.call(firstAyahNum);
        _scheduleSettledPreload(idx, pageCount);
      },
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
  Future<_PageData>? _dataFuture;
  _PageData? _data;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAll(widget.pageNumber);
  }

  Future<_PageData> _loadAll(int pageNumber) async {
    final service = MushafAssetService.instance;
    final results = await Future.wait([
      service.getPageData(pageNumber),
      service.loadFontForPage(pageNumber),
      QuranRepository.instance
          .getAyahsByKeyForPage(pageNumber, widget.langCode),
    ]);
    final ayahByKey = (results[2] as Map<String, Ayah>);
    final filtered = _applyRangeFilter(ayahByKey);
    final data = _PageData(
      bundle: _PageBundle(
        data: results[0] as MushafPageData,
        fontFamily: results[1] as String,
      ),
      ayahByKey: filtered,
    );
    if (mounted) setState(() => _data = data);
    return data;
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
          Expanded(
            child: _data != null
                ? _MushafPageContent(
                    bundle: _data!.bundle,
                    ayahByKey: _data!.ayahByKey,
                    selectedKey: widget.selectedKey,
                    onTapWord: widget.onTapWord,
                    surahFilter: widget.surahNumber,
                    rangeFiltered: widget.rangeFiltered,
                  )
                : FutureBuilder<_PageData>(
                    future: _dataFuture,
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
                                    _dataFuture = _loadAll(widget.pageNumber);
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: palette.surface2,
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: palette.line),
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
                      final data = snap.data!;
                      return _MushafPageContent(
                        bundle: data.bundle,
                        ayahByKey: data.ayahByKey,
                        selectedKey: widget.selectedKey,
                        onTapWord: widget.onTapWord,
                        surahFilter: widget.surahNumber,
                        rangeFiltered: widget.rangeFiltered,
                      );
                    },
                  ),
          ),
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
  _PageData({required this.bundle, required this.ayahByKey});
  final _PageBundle bundle;
  final Map<String, Ayah> ayahByKey;
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
    required this.onTapWord,
    this.surahFilter,
    this.rangeFiltered = false,
  });

  final _PageBundle bundle;
  final Map<String, Ayah> ayahByKey;
  final String? selectedKey;
  final void Function(String verseKey, Ayah? ayah) onTapWord;
  final int? surahFilter;
  final bool rangeFiltered;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final lines = bundle.data.lines.where((line) {
      if (line.words.isEmpty) return false;
      if (rangeFiltered) {
        return line.words.any((w) => ayahByKey.containsKey(w.verseKey));
      }
      if (surahFilter == null) return true;
      final prefix = '$surahFilter:';
      return line.words.any((w) => w.verseKey.startsWith(prefix));
    }).toList();
    return LayoutBuilder(builder: (ctx, c) {
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
            for (final line in lines)
              SizedBox(
                height: lineHeight,
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
                      onTapWord: onTapWord,
                      palette: palette,
                      rangeFiltered: rangeFiltered,
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
    required this.onTapWord,
    required this.palette,
    this.rangeFiltered = false,
  });

  final MushafLine line;
  final String fontFamily;
  final double fontSize;
  final Map<String, Ayah> ayahByKey;
  final String? selectedKey;
  final void Function(String verseKey, Ayah? ayah) onTapWord;
  final AppPalette palette;
  final bool rangeFiltered;

  @override
  Widget build(BuildContext context) {
    final List<MushafLineWord> shownWords;
    if (rangeFiltered) {
      shownWords = [
        for (final w in line.words)
          if (ayahByKey.containsKey(w.verseKey)) w,
      ];
    } else {
      shownWords = line.words;
    }
    final gap = fontSize * 0.15;
    final highlightChildren = <Widget>[];
    final textChildren = <Widget>[];
    for (var i = 0; i < shownWords.length; i++) {
      final w = shownWords[i];
      final isSelected = selectedKey == w.verseKey;

      final invisibleText = Opacity(
        opacity: 0.0,
        child: Text(
          w.code,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            height: 1.4,
          ),
        ),
      );
      highlightChildren.add(IgnorePointer(
        child: isSelected
            ? ColoredBox(color: palette.accentSoft, child: invisibleText)
            : invisibleText,
      ));

      textChildren.add(_wordWidget(w));

      if (i < shownWords.length - 1) {
        final next = shownWords[i + 1];
        final bridge = selectedKey != null &&
            w.verseKey == selectedKey &&
            next.verseKey == selectedKey;
        highlightChildren.add(Container(
          width: gap,
          height: fontSize * 1.4,
          color: bridge ? palette.accentSoft : null,
        ));
        textChildren.add(SizedBox(width: gap));
      }
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: highlightChildren,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: textChildren,
          ),
        ],
      ),
    );
  }

  Widget _wordWidget(MushafLineWord w) {
    final ayah = ayahByKey[w.verseKey];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTapWord(w.verseKey, ayah),
      child: Text(
        w.code,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: w.isAyahEnd ? palette.accent : null,
          height: 1.4,
        ),
      ),
    );
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