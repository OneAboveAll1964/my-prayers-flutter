import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/services/ayah_audio_controller.dart';
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
import '../settings/widgets/arabic_font_picker.dart';
import 'widgets/mushaf_install_sheet.dart';
import 'widgets/mushaf_view.dart';
import 'package:ionicons/ionicons.dart';

class SurahPage extends ConsumerStatefulWidget {
  const SurahPage({
    super.key,
    required this.number,
    this.initialAyah,
    this.englishName,
    this.arabicName,
    this.ayahCount,
  });

  final int number;
  final int? initialAyah;
  final String? englishName;
  final String? arabicName;
  final int? ayahCount;

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  Surah? _surah;
  bool _loading = true;
  late final ScrollController _controller;
  final Map<int, GlobalKey> _ayahKeys = {};
  int _visibleAyah = 1;
  int _currentAyah = 1;
  bool _initialScrollScheduled = false;
  Timer? _scrollDebounce;
  bool _switchingToMushaf = false;
  DateTime? _suppressScrollSaveUntil;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
    _currentAyah = widget.initialAyah ?? 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_surah == null) _load();
  }

  Future<void> _load() async {
    final l10n = AppL10n.of(context);
    final surah = await QuranRepository.instance
        .getSurah(widget.number, langKey(l10n.locale));
    if (!mounted) return;
    setState(() {
      _surah = surah;
      _loading = false;
      if (surah != null) {
        for (final a in surah.ayahs) {
          _ayahKeys[a.numberInSurah] = GlobalKey();
        }
      }
    });

    if (surah != null) {
      _saveLastRead(widget.initialAyah ?? 1);
      if (!_initialScrollScheduled &&
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
  }

  Future<void> _scrollToAyah(int ayahNum) async {
    if (!mounted || _surah == null) return;
    if (!_controller.hasClients) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted || !_controller.hasClients) return;
    }

    const estHeight = 280.0;
    var targetOffset = (ayahNum - 1) * estHeight;

    for (var pass = 0; pass < 6; pass++) {
      if (!mounted || !_controller.hasClients) return;
      final maxScroll = _controller.position.maxScrollExtent;
      _controller.jumpTo(targetOffset.clamp(0.0, maxScroll));

      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;

      final ctx = _ayahKeys[ayahNum]?.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null && box.attached && _controller.hasClients) {
          final globalY = box.localToGlobal(Offset.zero).dy;
          final scrollableBox =
              Scrollable.maybeOf(ctx)?.context.findRenderObject() as RenderBox?;
          final viewportTop =
              scrollableBox?.localToGlobal(Offset.zero).dy ?? 0;
          final relY = globalY - viewportTop;
          final delta = relY - 4;
          final newOffset =
              (_controller.offset + delta).clamp(0.0, _controller.position.maxScrollExtent);
          await _controller.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 240),
            curve: AppTokens.ease,
          );
          return;
        }
      }

      targetOffset += estHeight * 4;
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

  void _onMushafPageAyah(Ayah firstAyahOfPage) {
    _currentAyah = firstAyahOfPage.numberInSurah;
    _saveLastRead(_currentAyah);
  }

  Future<void> _switchToSurah(int newNumber) async {
    if (newNumber < 1 || newNumber > 114) return;
    final l10n = AppL10n.of(context);
    final next = await QuranRepository.instance
        .getSurah(newNumber, langKey(l10n.locale));
    if (!mounted || next == null) return;
    setState(() {
      _surah = next;
      _currentAyah = 1;
      _visibleAyah = 1;
      _ayahKeys
        ..clear()
        ..addEntries(next.ayahs.map(
            (a) => MapEntry(a.numberInSurah, GlobalKey())));
    });
    _saveLastRead(1);
  }

  Future<void> _toggleMode(bool isMushaf) async {
    if (isMushaf) {
      final target = _currentAyah;
      _suppressScrollSaveUntil =
          DateTime.now().add(const Duration(seconds: 3));
      ref.read(settingsProvider.notifier).setQuranReadMode('scroll');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (target > 1) {
          await _scrollToAyah(target);
        }
        _suppressScrollSaveUntil =
            DateTime.now().add(const Duration(milliseconds: 250));
      });
      return;
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
    if (_surah == null) return;
    ref.read(favoritesProvider.notifier).setLastSurah(LastReadEntry(
          number: _surah!.number,
          englishName: _surah!.englishName,
          name: _surah!.name,
          ayahCount: _surah!.ayahs.length,
          lastAyah: ayah,
        ));
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get _displayTitle {
    final l10n = AppL10n.of(context);
    final lang = l10n.locale.languageCode;
    final preferArabic = lang != 'en';
    if (_surah != null) {
      return preferArabic ? _surah!.name : _surah!.englishName;
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
    final raw = _surah?.ayahs.length ?? widget.ayahCount;
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
    final settings = ref.watch(settingsProvider);
    final fav = ref.watch(favoritesProvider);
    final fontFamily = arabicFontFamilies[settings.arabicFont] ?? 'UthmanicHafs';
    final arScale = settings.arabicFontScale;
    final marked = fav.surahs.contains(widget.number);

    final isMushaf = settings.quranReadMode == 'mushaf';
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
                title: _displayTitle,
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
                    if (!isMushaf)
                      AppIconButton(
                        icon: Ionicons.text_outline,
                        semanticLabel: l10n.t('settings.arabicFont'),
                        onPressed: () {
                          showAppSheet(
                            context: context,
                            title: l10n.t('settings.arabicFont'),
                            builder: (ctx) => const ArabicFontPicker(),
                          );
                        },
                      ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => ref
                          .read(favoritesProvider.notifier)
                          .toggleBookmarkSurah(widget.number),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: AnimatedToggleIcon(
                            outlineIcon: Ionicons.bookmark_outline,
                            filledIcon: Ionicons.bookmark,
                            active: marked,
                            activeColor: palette.accent,
                            inactiveColor: palette.textMuted,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const PageLoader()
                  : _surah == null
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
                                  key: ValueKey('mushaf-${_surah!.number}'),
                                  child: MushafView(
                                    surah: _surah!,
                                    initialAyah: _currentAyah,
                                    onPageAyahChanged: _onMushafPageAyah,
                                    onSwitchSurah: _switchToSurah,
                                  ),
                                )
                              : ListView.separated(
                                  key: ValueKey('scroll-${_surah!.number}'),
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
                                      fontFamily: fontFamily,
                                      arScale: arScale,
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
    required this.fontFamily,
    required this.arScale,
  });

  final Ayah ayah;
  final Surah surah;
  final String fontFamily;
  final double arScale;

  @override
  ConsumerState<_AyahRow> createState() => _AyahRowState();
}

class _AyahRowState extends ConsumerState<_AyahRow> {
  bool _downBm = false;
  bool _downPlay = false;
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
    final fav = ref.watch(favoritesProvider);
    final marked = fav.ayahs.any((a) =>
        a.surah == widget.surah.number && a.ayah == widget.ayah.numberInSurah);
    final ayah = widget.ayah;
    final surah = widget.surah;
    final isAudioForThis =
        _audio.isFor(surah.number, ayah.numberInSurah);
    final isPlaying = isAudioForThis && _audio.playing;
    final isAudioLoading = isAudioForThis && _audio.loading;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
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
                  fontFamily: widget.fontFamily,
                  fontSize: 26.0 * widget.arScale,
                  height: 2.4,
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
                fontSize: 15,
                height: 1.7,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
