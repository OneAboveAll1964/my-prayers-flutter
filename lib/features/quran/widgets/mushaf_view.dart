import 'dart:async';

import 'package:flutter/gestures.dart';
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
    required this.surah,
    this.initialAyah,
    this.onPageAyahChanged,
    this.onSwitchSurah,
  });

  final Surah surah;
  final int? initialAyah;
  final void Function(Ayah firstAyahOfPage)? onPageAyahChanged;
  final void Function(int newSurahNumber)? onSwitchSurah;

  @override
  ConsumerState<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends ConsumerState<MushafView> {
  late int _firstPage;
  late int _lastPage;
  late PageController _pageController;
  String? _selectedKey;
  String? _playingKey;
  late Map<String, Ayah> _ayahByKey;
  late Map<int, Ayah> _firstAyahByPage;
  Timer? _preloadTimer;
  StreamSubscription<AyahAudioState>? _audioSub;
  int? _lastQueueAyah;

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
    final initialIdx =
    (initialAyah.page - _firstPage).clamp(0, _lastPage - _firstPage);
    _pageController = PageController(initialPage: initialIdx);
    _ayahByKey = {
      for (final a in widget.surah.ayahs)
        '${widget.surah.number}:${a.numberInSurah}': a,
    };
    _firstAyahByPage = <int, Ayah>{};
    for (final a in widget.surah.ayahs) {
      _firstAyahByPage.putIfAbsent(a.page, () => a);
    }
    final pageCount = _lastPage - _firstPage + 1;
    _scheduleSettledPreload(initialIdx, pageCount,
        delay: const Duration(milliseconds: 400));
    final audioState = AyahAudioController.instance.state;
    if (audioState.surah == widget.surah.number && audioState.ayah != null) {
      if (audioState.playing || audioState.loading) {
        _playingKey = '${audioState.surah}:${audioState.ayah}';
      }
      _lastQueueAyah = audioState.ayah;
    }
    _audioSub = AyahAudioController.instance.stream.listen(_onAudio);
  }

  void _onAudio(AyahAudioState s) {
    if (!mounted) return;
    final isThisSurah = s.surah == widget.surah.number && s.ayah != null;
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
    final ayah = widget.surah.ayahs.firstWhere(
          (a) => a.numberInSurah == s.ayah,
      orElse: () => widget.surah.ayahs.first,
    );
    final targetIdx =
    (ayah.page - _firstPage).clamp(0, _lastPage - _firstPage);
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

    Surah surah = widget.surah;
    Ayah? resolved = ayah;

    if (tappedSurah != widget.surah.number) {
      final lang = AppL10n.of(context).locale;
      final loaded = await QuranRepository.instance
          .getSurah(tappedSurah, langKey(lang));
      if (!mounted || loaded == null) return;
      surah = loaded;
      resolved = _closestAyah(loaded.ayahs, tappedAyah);
    } else if (resolved == null) {
      resolved = _closestAyah(widget.surah.ayahs, tappedAyah);
    }
    if (resolved == null) return;

    final keyToSelect = '${surah.number}:${resolved.numberInSurah}';
    setState(() => _selectedKey = keyToSelect);
    final settings = ref.read(settingsProvider);
    final fontFamily =
        arabicFontFamilies[settings.arabicFont] ?? 'UthmanicHafs';
    if (!mounted) return;
    await showAyahActionsSheet(
      context: context,
      surah: surah,
      ayah: resolved,
      ref: ref,
      fontFamily: fontFamily,
      arScale: settings.arabicFontScale,
    );
    if (!mounted) return;
    setState(() => _selectedKey = null);
  }

  Ayah? _closestAyah(List<Ayah> ayahs, int target) {
    Ayah? best;
    var bestDiff = 1 << 30;
    for (final a in ayahs) {
      final diff = (a.numberInSurah - target).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = a;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = _lastPage - _firstPage + 1;
    return PageView.builder(
      controller: _pageController,
      itemCount: pageCount,
      allowImplicitScrolling: true,
      onPageChanged: (idx) {
        final pageNumber = _firstPage + idx;
        final firstAyah =
            _firstAyahByPage[pageNumber] ?? widget.surah.ayahs.first;
        widget.onPageAyahChanged?.call(firstAyah);
        _scheduleSettledPreload(idx, pageCount);
      },
      itemBuilder: (ctx, idx) {
        final pageNumber = _firstPage + idx;
        return RepaintBoundary(
          child: _MushafPageView(
            key: ValueKey<int>(pageNumber),
            pageNumber: pageNumber,
            surahNumber: widget.surah.number,
            ayahByKey: _ayahByKey,
            selectedKey: _selectedKey ?? _playingKey,
            onTapWord: _handleTapWord,
            pageIndex: idx,
            totalPages: pageCount,
            onSwitchSurah: widget.onSwitchSurah,
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
    required this.ayahByKey,
    required this.selectedKey,
    required this.onTapWord,
    required this.pageIndex,
    required this.totalPages,
    required this.onSwitchSurah,
  });

  final int pageNumber;
  final int surahNumber;
  final Map<String, Ayah> ayahByKey;
  final String? selectedKey;
  final void Function(String verseKey, Ayah? ayah) onTapWord;
  final int pageIndex;
  final int totalPages;
  final void Function(int newSurahNumber)? onSwitchSurah;

  @override
  State<_MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<_MushafPageView> {
  Future<_PageBundle>? _bundleFuture;
  _PageBundle? _bundle;

  @override
  void initState() {
    super.initState();
    final svc = MushafAssetService.instance;
    final cachedData = svc.cachedPageData(widget.pageNumber);
    final cachedFont = svc.cachedFontFamily(widget.pageNumber);
    if (cachedData != null && cachedFont != null) {
      _bundle = _PageBundle(data: cachedData, fontFamily: cachedFont);
    } else {
      _bundleFuture = _loadBundle(widget.pageNumber);
    }
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
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
            child: _bundle != null
                ? _MushafPageContent(
              bundle: _bundle!,
              ayahByKey: widget.ayahByKey,
              selectedKey: widget.selectedKey,
              onTapWord: widget.onTapWord,
              surahFilter: widget.surahNumber,
            )
                : FutureBuilder<_PageBundle>(
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
                  onTapWord: widget.onTapWord,
                  surahFilter: widget.surahNumber,
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
    required this.onTapWord,
    this.surahFilter,
  });

  final _PageBundle bundle;
  final Map<String, Ayah> ayahByKey;
  final String? selectedKey;
  final void Function(String verseKey, Ayah? ayah) onTapWord;
  final int? surahFilter;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final lines = surahFilter == null
        ? bundle.data.lines
        : bundle.data.lines.where((line) {
      if (line.words.isEmpty) return false;
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

class _LineWidget extends StatefulWidget {
  const _LineWidget({
    required this.line,
    required this.fontFamily,
    required this.fontSize,
    required this.ayahByKey,
    required this.selectedKey,
    required this.onTapWord,
    required this.palette,
  });

  final MushafLine line;
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
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final words = widget.line.words;
    final spans = <InlineSpan>[];
    final selectedKey = widget.selectedKey;
    final accent = widget.palette.accent;
    final accentSoftPaint = Paint()..color = widget.palette.accentSoft;

    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      final isSelected = selectedKey == w.verseKey;
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          final ayah = widget.ayahByKey[w.verseKey];
          widget.onTapWord(w.verseKey, ayah);
        };
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: w.code,
        recognizer: recognizer,
        style: w.isAyahEnd || isSelected
            ? TextStyle(
                color: w.isAyahEnd ? accent : null,
                background: isSelected ? accentSoftPaint : null,
              )
            : null,
      ));
      if (i < words.length - 1) {
        spans.add(TextSpan(
          text: ' ',
          style: TextStyle(fontSize: widget.fontSize * 0.5),
        ));
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: widget.fontFamily,
            fontSize: widget.fontSize,
            height: 1.4,
          ),
          children: spans,
        ),
        textAlign: TextAlign.center,
        softWrap: false,
        maxLines: 1,
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