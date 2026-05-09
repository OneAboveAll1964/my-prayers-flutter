import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/services/ayah_audio_controller.dart';
import '../../core/services/recitation_service.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/quran_repository.dart';
import '../../shared/models/quran.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/animated_toggle_icon.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_sheet.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../core/services/mushaf_asset_service.dart';
import '../../core/services/surah_name_font_service.dart';
import '../settings/widgets/arabic_font_picker.dart';
import 'widgets/mushaf_install_sheet.dart';
import 'widgets/mushaf_view.dart';
import 'widgets/surah_info_sheet.dart';
import 'widgets/tafsir_sheet.dart';
import 'package:ionicons/ionicons.dart';

class SurahPage extends ConsumerStatefulWidget {
  const SurahPage({
    super.key,
    required this.number,
    this.initialAyah,
    this.endAyah,
    this.englishName,
    this.arabicName,
    this.ayahCount,
    this.lockSurah = false,
  });

  final int number;
  final int? initialAyah;
  final int? endAyah;
  final String? englishName;
  final String? arabicName;
  final int? ayahCount;
  final bool lockSurah;

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  Surah? _surah;
  SurahPageMap? _pageMap;
  bool _loading = true;
  bool _surahLoading = false;
  late final ScrollController _controller;
  final Map<int, GlobalKey> _ayahKeys = {};
  int _visibleAyah = 1;
  int _currentAyah = 1;
  bool _initialScrollScheduled = false;
  Timer? _scrollDebounce;
  bool _switchingToMushaf = false;
  bool _startingSurahPlay = false;
  DateTime? _suppressScrollSaveUntil;
  StreamSubscription<AyahAudioState>? _audioSub;
  AyahAudioState _audio = AyahAudioController.instance.state;
  bool _lastQueueActiveHere = false;

  Widget? _cachedMushaf;
  SurahPageMap? _cachedMushafFor;
  String? _cachedMushafLang;
  int? _cachedMushafInitialAyah;

  SurahMeta? get _meta => _pageMap?.meta;
  int get _surahNumber => _pageMap?.meta.number ?? widget.number;

  void _invalidateMushafCache() {
    _cachedMushaf = null;
    _cachedMushafFor = null;
    _cachedMushafLang = null;
    _cachedMushafInitialAyah = null;
  }

  Widget _buildMushaf(SurahPageMap pageMap, String langCode) {
    if (!identical(_cachedMushafFor, pageMap) ||
        _cachedMushafLang != langCode ||
        _cachedMushafInitialAyah != _currentAyah) {
      _cachedMushafFor = pageMap;
      _cachedMushafLang = langCode;
      _cachedMushafInitialAyah = _currentAyah;
      _cachedMushaf = RepaintBoundary(
        child: MushafView(
          pageMap: pageMap,
          langCode: langCode,
          initialAyah: _currentAyah,
          startAyah: widget.endAyah != null ? widget.initialAyah : null,
          endAyah: widget.endAyah,
          onPageAyahChanged: _onMushafPageAyah,
          onSwitchSurah: widget.lockSurah ? null : _switchToSurah,
          rangeFiltered: widget.endAyah != null,
        ),
      );
    }
    return _cachedMushaf!;
  }

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
    _currentAyah = widget.initialAyah ?? 1;
    _audioSub = AyahAudioController.instance.stream.listen(_onAudioState);
  }

  void _onAudioState(AyahAudioState s) {
    if (!mounted) return;
    final wasFor = _audio.surah;
    final wasAyah = _audio.ayah;
    _audio = s;
    // Only rebuild SurahPage when something the visible header cares about
    // actually flipped (queue active for *this* surah). Audio progress
    // ticks during playback don't need to repaint the page.
    final ctrl = AyahAudioController.instance;
    final queueActiveHere =
        ctrl.isQueueActive && ctrl.queueSurah == _surahNumber;
    if (queueActiveHere != _lastQueueActiveHere) {
      _lastQueueActiveHere = queueActiveHere;
      setState(() {});
    }
    if (!ctrl.isQueueActive) return;
    if (s.surah != _surahNumber) return;
    if (s.ayah == null) return;
    if (wasFor == s.surah && wasAyah == s.ayah) return;
    final settings = ref.read(settingsProvider);
    if (settings.quranReadMode != 'mushaf') {
      _suppressScrollSaveUntil =
          DateTime.now().add(const Duration(seconds: 2));
      _scrollToAyah(s.ayah!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pageMap == null) _load();
  }

  bool get _scrollMode =>
      ref.read(settingsProvider).quranReadMode != 'mushaf';

  Future<void> _load() async {
    final pageMap =
        await QuranRepository.instance.getSurahPageMap(widget.number);
    if (!mounted) return;
    setState(() {
      _pageMap = pageMap;
      _loading = false;
    });
    if (pageMap != null) {
      _saveLastRead(widget.initialAyah ?? 1);
      if (_scrollMode) {
        await _ensureFullSurah();
      }
    }
  }

  Future<void> _ensureFullSurah() async {
    if (_surah != null || _surahLoading) return;
    _surahLoading = true;
    final l10n = AppL10n.of(context);
    var surah = await QuranRepository.instance
        .getSurah(widget.number, langKey(l10n.locale));
    if (!mounted) {
      _surahLoading = false;
      return;
    }
    if (surah != null && widget.endAyah != null) {
      final start = widget.initialAyah ?? 1;
      final end = widget.endAyah!;
      final filtered = surah.ayahs
          .where((a) => a.numberInSurah >= start && a.numberInSurah <= end)
          .toList();
      if (filtered.isNotEmpty) {
        surah = Surah(
          number: surah.number,
          name: surah.name,
          englishName: surah.englishName,
          englishNameTranslation: surah.englishNameTranslation,
          revelationType: surah.revelationType,
          ayahs: filtered,
        );
      }
    }
    setState(() {
      _surah = surah;
      _surahLoading = false;
      if (surah != null) {
        for (final a in surah.ayahs) {
          _ayahKeys[a.numberInSurah] = GlobalKey();
        }
      }
    });

    if (surah != null &&
        !_initialScrollScheduled &&
        widget.initialAyah != null &&
        widget.initialAyah! > 1) {
      _initialScrollScheduled = true;
      _suppressScrollSaveUntil =
          DateTime.now().add(const Duration(seconds: 3));
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _scrollToAyah(widget.initialAyah!);
        _suppressScrollSaveUntil =
            DateTime.now().add(const Duration(milliseconds: 250));
      });
    }
  }

  Future<void> _scrollToAyah(int ayahNum) async {
    if (!mounted || _surah == null) return;
    if (!_controller.hasClients) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || !_controller.hasClients) return;
    }

    final totalAyahs = _surah!.ayahs.length;

    for (var pass = 0; pass < 18; pass++) {
      if (!mounted || !_controller.hasClients) return;
      final maxScroll = _controller.position.maxScrollExtent;

      final ctx = _ayahKeys[ayahNum]?.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null && box.attached) {
          final globalY = box.localToGlobal(Offset.zero).dy;
          final scrollableBox = Scrollable.maybeOf(ctx)
              ?.context
              .findRenderObject() as RenderBox?;
          final viewportTop =
              scrollableBox?.localToGlobal(Offset.zero).dy ?? 0;
          final relY = globalY - viewportTop;
          final delta = relY - 4;
          final newOffset = (_controller.offset + delta)
              .clamp(0.0, _controller.position.maxScrollExtent);
          await _controller.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 240),
            curve: AppTokens.ease,
          );
          return;
        }
      }

      double targetOffset;
      final rendered = <int, double>{};
      _ayahKeys.forEach((n, k) {
        final c = k.currentContext;
        if (c == null) return;
        final b = c.findRenderObject() as RenderBox?;
        if (b == null || !b.attached) return;
        rendered[n] = _controller.offset + b.localToGlobal(Offset.zero).dy;
      });

      if (rendered.length >= 2) {
        final keys = rendered.keys.toList()..sort();
        final firstK = keys.first;
        final lastK = keys.last;
        final firstY = rendered[firstK]!;
        final lastY = rendered[lastK]!;
        final perAyah =
        (lastK > firstK) ? (lastY - firstY) / (lastK - firstK) : 320.0;
        final closest = keys.reduce(
                (a, b) => (a - ayahNum).abs() < (b - ayahNum).abs() ? a : b);
        targetOffset = rendered[closest]! + (ayahNum - closest) * perAyah;
      } else if (rendered.length == 1) {
        final only = rendered.entries.first;
        targetOffset = only.value + (ayahNum - only.key) * 320.0;
      } else {
        targetOffset = totalAyahs > 1
            ? ((ayahNum - 1) / (totalAyahs - 1)) * maxScroll
            : 0;
      }

      targetOffset = targetOffset.clamp(0.0, maxScroll);
      _controller.jumpTo(targetOffset);

      await Future.delayed(const Duration(milliseconds: 90));
      if (!mounted) return;
    }
  }

  void _onScroll() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 80), _detectVisible);
  }

  void _detectVisible() {
    if (!mounted) return;
    int? best;
    double? bestY;
    _ayahKeys.forEach((number, key) {
      final ctx = key.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return;
      final pos = box.localToGlobal(Offset.zero).dy;
      if (pos > 80 && (bestY == null || pos < bestY!)) {
        bestY = pos;
        best = number;
      }
    });
    if (best != null && best != _visibleAyah) {
      if (_suppressScrollSaveUntil != null &&
          DateTime.now().isBefore(_suppressScrollSaveUntil!)) {
        return;
      }
      _visibleAyah = best!;
      _currentAyah = best!;
      _saveLastRead(_visibleAyah);
    }
  }

  void _onMushafPageAyah(int firstAyahNumberInSurah) {
    _currentAyah = firstAyahNumberInSurah;
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _saveLastRead(_currentAyah);
      }
    });
  }

  Future<void> _switchToSurah(int newNumber) async {
    if (newNumber < 1 || newNumber > 114) return;
    final nextMap =
        await QuranRepository.instance.getSurahPageMap(newNumber);
    if (!mounted || nextMap == null) return;
    final goingBack = newNumber < _surahNumber;
    final targetAyah = goingBack ? nextMap.meta.ayahCount : 1;
    setState(() {
      _pageMap = nextMap;
      _surah = null;
      _currentAyah = targetAyah;
      _visibleAyah = targetAyah;
      _ayahKeys.clear();
    });
    _saveLastRead(targetAyah);
    if (_scrollMode) {
      _ensureFullSurah();
    }
  }

  int? get _activePlayingAyah {
    if (_audio.surah != _surahNumber) return null;
    if (_audio.ayah == null) return null;
    if (!(_audio.playing || _audio.loading)) return null;
    return _audio.ayah;
  }

  Future<void> _toggleMode(bool isMushaf) async {
    if (isMushaf) {
      final target = _currentAyah;
      _suppressScrollSaveUntil =
          DateTime.now().add(const Duration(seconds: 4));
      ref.read(settingsProvider.notifier).setQuranReadMode('scroll');
      // Ensure full surah is loaded for scroll mode rendering.
      await _ensureFullSurah();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 180));
        if (!mounted) return;
        if (target > 1) {
          await _scrollToAyah(target);
        }
        _suppressScrollSaveUntil =
            DateTime.now().add(const Duration(milliseconds: 250));
      });
      return;
    }
    final playingAyah = _activePlayingAyah;
    if (playingAyah != null) {
      _currentAyah = playingAyah;
    }
    final installed = await MushafAssetService.instance.isInstalled();
    if (installed) {
      ref.read(settingsProvider.notifier).setQuranReadMode('mushaf');
      return;
    }
    if (!mounted) return;
    setState(() => _switchingToMushaf = true);
    final ok = await showMushafInstallSheet(context);
    if (!mounted) return;
    setState(() => _switchingToMushaf = false);
    if (ok) {
      ref.read(settingsProvider.notifier).setQuranReadMode('mushaf');
    }
  }

  void _saveLastRead(int ayah) {
    final meta = _meta;
    if (meta == null) return;
    ref.read(favoritesProvider.notifier).setLastSurah(LastReadEntry(
          number: meta.number,
          englishName: meta.englishName,
          name: meta.name,
          ayahCount: meta.ayahCount,
          lastAyah: ayah,
        ));
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    AyahAudioController.instance.stop();
    _scrollDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showMoreSheet(bool isMushaf, bool bookmarked) async {
    final l10n = AppL10n.of(context);
    await showAppSheet<void>(
      context: context,
      title: l10n.t('quran.moreActions'),
      builder: (sheetCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoreActionRow(
            icon: bookmarked
                ? Ionicons.bookmark
                : Ionicons.bookmark_outline,
            iconColor: bookmarked ? context.palette.accent : null,
            label: bookmarked
                ? l10n.t('quran.removeBookmark')
                : l10n.t('quran.bookmarkSurah'),
            onTap: () {
              ref
                  .read(favoritesProvider.notifier)
                  .toggleBookmarkSurah(_surahNumber);
              Navigator.of(sheetCtx).pop();
            },
          ),
          _MoreActionRow(
            icon: Ionicons.information_circle_outline,
            label: l10n.t('surahInfo.title'),
            onTap: () {
              Navigator.of(sheetCtx).pop();
              showSurahInfoSheet(
                context: context,
                surahNumber: _surahNumber,
                displayName: _displayTitle,
              );
            },
          ),
          if (!isMushaf)
            _MoreActionRow(
              icon: Ionicons.text_outline,
              label: l10n.t('settings.arabicFont'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                showAppSheet(
                  context: context,
                  title: l10n.t('settings.arabicFont'),
                  builder: (ctx) => const ArabicFontPicker(),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _onPlaySurahTap() async {
    final meta = _meta;
    if (meta == null) return;
    final ctrl = AyahAudioController.instance;
    final surahNumber = meta.number;
    if (ctrl.isQueueActive && ctrl.queueSurah == surahNumber) {
      await ctrl.stop();
      return;
    }
    final settings = ref.read(settingsProvider);
    final l10n = AppL10n.of(context);
    final reciterId = settings.selectedReciterId;
    if (reciterId == null) {
      if (!mounted) return;
      context.push('/settings/resources/reciters');
      return;
    }
    final ayahCount = meta.ayahCount;
    final ready = await RecitationService.instance
        .isSurahReady(reciterId, surahNumber, ayahCount);
    if (!ready) {
      if (!mounted) return;
      final ok = await showAppSheet<bool>(
        context: context,
        title: l10n.t('quran.downloadSurahTitle'),
        dismissible: false,
        builder: (ctx) => _SurahDownloadBody(
          reciterId: reciterId,
          surahNumber: surahNumber,
        ),
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    setState(() => _startingSurahPlay = true);
    try {
      await ctrl.playSurah(
        reciterId: reciterId,
        surah: surahNumber,
        startAyah: _currentAyah,
        endAyah: ayahCount,
      );
    } finally {
      if (mounted) setState(() => _startingSurahPlay = false);
    }
  }

  String get _displayTitle {
    final l10n = AppL10n.of(context);
    final lang = l10n.locale.languageCode;
    final preferArabic = lang != 'en';
    final meta = _meta;
    if (meta != null) {
      return preferArabic ? meta.name : meta.englishName;
    }
    if (preferArabic &&
        widget.arabicName != null &&
        widget.arabicName!.isNotEmpty) {
      return widget.arabicName!;
    }
    if (widget.englishName != null && widget.englishName!.isNotEmpty) {
      return widget.englishName!;
    }
    return l10n.t('quran.title');
  }

  String? get _displaySubtitle {
    final l10n = AppL10n.of(context);
    final isEn = l10n.locale.languageCode == 'en';
    final raw = _meta?.ayahCount ?? widget.ayahCount;
    if (raw == null) return null;
    final count = isEn ? raw.toString() : _arabicNum(raw);
    return '$count ${l10n.t('quran.ayahs')}';
  }

  static const _arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  String _arabicNum(int n) =>
      n.toString().split('').map((c) => _arDigits[int.parse(c)]).join();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    // Narrow Riverpod watches: per-row styling (font/scale/bold) is read
    // inside _AyahRow itself, and lastSurah updates leave bookmark state
    // unchanged — neither path rebuilds SurahPage during mushaf swipes.
    final quranReadMode =
        ref.watch(settingsProvider.select((s) => s.quranReadMode));
    final marked = ref.watch(
        favoritesProvider.select((f) => f.surahs.contains(_surahNumber)));

    final isMushaf = quranReadMode == 'mushaf';
    final activeSurahNumber = _surahNumber;
    if (!isMushaf && _pageMap != null && _surah == null && !_surahLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureFullSurah();
      });
    }
    final queueActiveHere =
        AyahAudioController.instance.isQueueActive &&
            AyahAudioController.instance.queueSurah == activeSurahNumber;
    final isEn = l10n.locale.languageCode == 'en';
    final titleWidget = isEn
        ? null
        : Text(
      SurahNameFont.glyphFor(activeSurahNumber),
      textDirection: TextDirection.rtl,
      style: TextStyle(
        color: palette.text,
        fontSize: 28,
        height: 1.0,
        fontFamily: SurahNameFont.fontFamily,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: _displayTitle,
              titleWidget: titleWidget,
              subtitle: _displaySubtitle,
              back: true,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconButton(
                    icon: isMushaf
                        ? Ionicons.list_outline
                        : Ionicons.book_outline,
                    semanticLabel: l10n.t('quran.toggleMode'),
                    onPressed: _switchingToMushaf
                        ? null
                        : () => _toggleMode(isMushaf),
                  ),
                  AppIconButton(
                    icon: queueActiveHere
                        ? Ionicons.stop_circle
                        : Ionicons.play_circle,
                    semanticLabel: l10n.t('quran.playSurah'),
                    color: queueActiveHere ? palette.accent : null,
                    onPressed: _startingSurahPlay
                        ? null
                        : _onPlaySurahTap,
                  ),
                  AppIconButton(
                    icon: Ionicons.ellipsis_horizontal,
                    semanticLabel: l10n.t('quran.moreActions'),
                    onPressed: () => _showMoreSheet(isMushaf, marked),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const PageLoader()
                  : _pageMap == null
                  ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.t('common.error'),
                  style: TextStyle(color: palette.textMuted),
                ),
              )
                  : AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final fade = FadeTransition(
                      opacity: anim, child: child);
                  return ScaleTransition(
                    scale: Tween(begin: 0.96, end: 1.0).animate(
                        CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOutCubic)),
                    child: fade,
                  );
                },
                child: isMushaf
                    ? KeyedSubtree(
                        key: ValueKey('mushaf-$activeSurahNumber'),
                        child: _buildMushaf(
                            _pageMap!, langKey(l10n.locale)),
                      )
                    : _surah == null
                        ? const KeyedSubtree(
                            key: ValueKey('scroll-loading'),
                            child: PageLoader(),
                          )
                        : ListView.separated(
                            key: ValueKey('scroll-$activeSurahNumber'),
                            controller: _controller,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                                18, 4, 18, 32),
                            itemCount: _surah!.ayahs.length,
                            separatorBuilder: (ctx, i) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final a = _surah!.ayahs[i];
                              return _AyahRow(
                                key: _ayahKeys[a.numberInSurah],
                                ayah: a,
                                surah: _surah!,
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahRow extends ConsumerStatefulWidget {
  const _AyahRow({
    super.key,
    required this.ayah,
    required this.surah,
  });

  final Ayah ayah;
  final Surah surah;

  @override
  ConsumerState<_AyahRow> createState() => _AyahRowState();
}

class _AyahRowState extends ConsumerState<_AyahRow> {
  bool _downBm = false;
  bool _downPlay = false;
  bool _downTafsir = false;
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

  Future<void> _onPlayTap() async {
    final settings = ref.read(settingsProvider);
    final reciterId = settings.selectedReciterId;
    if (reciterId == null) {
      context.push('/settings/resources/reciters');
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
    final marked = ref.watch(favoritesProvider.select((f) => f.ayahs.any(
        (a) =>
            a.surah == widget.surah.number &&
            a.ayah == widget.ayah.numberInSurah)));
    final arabicFont =
        ref.watch(settingsProvider.select((s) => s.arabicFont));
    final arScale =
        ref.watch(settingsProvider.select((s) => s.arabicFontScale));
    final trScale =
        ref.watch(settingsProvider.select((s) => s.translationFontScale));
    final arabicBold =
        ref.watch(settingsProvider.select((s) => s.quranBold));
    final translationBold =
        ref.watch(settingsProvider.select((s) => s.translationBold));
    final fontFamily = arabicFontFamilies[arabicFont] ?? 'UthmanicHafs';
    final ayah = widget.ayah;
    final surah = widget.surah;
    final isAudioForThis =
    _audio.isFor(surah.number, ayah.numberInSurah);
    final isPlaying = isAudioForThis && _audio.playing;
    final isAudioLoading = isAudioForThis && _audio.loading;

    final isActive = isPlaying || isAudioLoading;
    return Container(
      decoration: BoxDecoration(
        color: isActive ? palette.accentSoft : palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
            color: isActive ? palette.accent : palette.line),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${ayah.numberInSurah}',
                    style: TextStyle(
                      color: palette.accentStrong,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Juz ${ayah.juz}',
                  style:
                  TextStyle(color: palette.textSubtle, fontSize: 11.5),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => setState(() => _downTafsir = true),
                  onTapCancel: () => setState(() => _downTafsir = false),
                  onTapUp: (_) => setState(() => _downTafsir = false),
                  onTap: () => showTafsirSheet(
                    context: context,
                    surah: widget.surah,
                    ayah: widget.ayah,
                  ),
                  child: AnimatedContainer(
                    duration: AppTokens.durationFast,
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _downTafsir
                          ? palette.surface2
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Ionicons.book_outline,
                      size: 16,
                      color: palette.textSubtle,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => setState(() => _downPlay = true),
                  onTapCancel: () => setState(() => _downPlay = false),
                  onTapUp: (_) => setState(() => _downPlay = false),
                  onTap: _onPlayTap,
                  child: AnimatedContainer(
                    duration: AppTokens.durationFast,
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _downPlay ? palette.surface2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: isAudioLoading
                        ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.accent,
                      ),
                    )
                        : Icon(
                      isPlaying
                          ? Ionicons.stop
                          : Ionicons.play,
                      size: 16,
                      color: isPlaying
                          ? palette.accent
                          : palette.textSubtle,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => setState(() => _downBm = true),
                  onTapCancel: () => setState(() => _downBm = false),
                  onTapUp: (_) => setState(() => _downBm = false),
                  onTap: () => ref
                      .read(favoritesProvider.notifier)
                      .toggleBookmarkAyah(
                    surah.number,
                    ayah.numberInSurah,
                    surahName: surah.englishName,
                    arabicName: surah.name,
                    preview: ayah.translation.isNotEmpty
                        ? ayah.translation
                        : ayah.arabic.characters.take(80).toString(),
                  ),
                  child: AnimatedContainer(
                    duration: AppTokens.durationFast,
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _downBm ? palette.surface2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedToggleIcon(
                      outlineIcon: Ionicons.bookmark_outline,
                      filledIcon: Ionicons.bookmark,
                      active: marked,
                      activeColor: palette.accent,
                      inactiveColor: palette.textSubtle,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: palette.line),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                ayah.arabic,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: palette.text,
                  fontFamily: fontFamily,
                  fontSize: 26.0 * arScale,
                  height: 2.4,
                  fontWeight:
                  arabicBold ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (ayah.translation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              ayah.translation,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: palette.text,
                fontSize: 15 * trScale,
                height: 1.7,
                fontWeight: translationBold
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoreActionRow extends StatefulWidget {
  const _MoreActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  State<_MoreActionRow> createState() => _MoreActionRowState();
}

class _MoreActionRowState extends State<_MoreActionRow> {
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
            Icon(widget.icon,
                size: 20, color: widget.iconColor ?? palette.textMuted),
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

class _SurahDownloadBody extends StatefulWidget {
  const _SurahDownloadBody({
    required this.reciterId,
    required this.surahNumber,
  });
  final int reciterId;
  final int surahNumber;

  @override
  State<_SurahDownloadBody> createState() => _SurahDownloadBodyState();
}

class _SurahDownloadBodyState extends State<_SurahDownloadBody> {
  StreamSubscription<RecitationProgress>? _sub;
  RecitationProgress? _progress;
  bool _failed = false;
  String? _error;

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
    setState(() {
      _failed = false;
      _error = null;
    });
    _sub?.cancel();
    _sub = RecitationService.instance
        .downloadSurah(
      reciterId: widget.reciterId,
      surahNumber: widget.surahNumber,
    )
        .listen((p) {
      if (!mounted) return;
      setState(() {
        _progress = p;
        if (p.failed) {
          _failed = true;
          _error = p.errorMessage;
        }
      });
      if (p.isComplete) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final p = _progress;
    final fraction = p?.fraction ?? 0.0;
    final done = p?.filesDone ?? 0;
    final total = p?.totalFiles ?? 0;

    if (_failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Ionicons.alert_circle_outline,
              size: 28, color: palette.textMuted),
          const SizedBox(height: 8),
          Text(
            l10n.t('reciters.installFailed'),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.text, fontSize: 14),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: l10n.t('mushaf.installRetry'),
            variant: AppButtonVariant.solid,
            expand: true,
            onPressed: _start,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: l10n.t('common.cancel'),
            variant: AppButtonVariant.outline,
            expand: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('quran.downloadSurahBody'),
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.text, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction == 0 ? null : fraction,
            minHeight: 8,
            backgroundColor: palette.surface2,
            valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          total == 0 ? '' : '$done / $total',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 12.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 18),
        AppButton(
          label: l10n.t('common.cancel'),
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
