import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/quran_repository.dart';
import '../../shared/models/quran.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_sheet.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../settings/widgets/arabic_font_picker.dart';

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
  bool _initialScrollScheduled = false;
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAyah(widget.initialAyah!);
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
          final viewport = _controller.position.viewportDimension;
          final globalY = box.localToGlobal(Offset.zero).dy;
          final scrollableBox =
              Scrollable.maybeOf(ctx)?.context.findRenderObject() as RenderBox?;
          final viewportTop =
              scrollableBox?.localToGlobal(Offset.zero).dy ?? 0;
          final relY = globalY - viewportTop;
          final delta = relY - viewport * 0.06;
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
      _visibleAyah = best!;
      _saveLastRead(_visibleAyah);
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
    if (_surah != null) return _surah!.englishName;
    if (widget.englishName != null && widget.englishName!.isNotEmpty) {
      return widget.englishName!;
    }
    return AppL10n.of(context).t('quran.title');
  }

  String? get _displaySubtitle {
    final l10n = AppL10n.of(context);
    if (_surah != null) {
      return '${_surah!.ayahs.length} ${l10n.t('quran.ayahs')}';
    }
    if (widget.ayahCount != null) {
      return '${widget.ayahCount} ${l10n.t('quran.ayahs')}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final settings = ref.watch(settingsProvider);
    final fav = ref.watch(favoritesProvider);
    final fontFamily = arabicFontFamilies[settings.arabicFont] ?? 'UthmanicHafs';
    final arScale = settings.arabicFontScale;
    final marked = fav.surahs.contains(widget.number);

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
                    icon: Icons.text_fields_rounded,
                    semanticLabel: l10n.t('settings.arabicFont'),
                    onPressed: () {
                      showAppSheet(
                        context: context,
                        title: l10n.t('settings.arabicFont'),
                        builder: (ctx) => const ArabicFontPicker(),
                      );
                    },
                  ),
                  AppIconButton(
                    icon: marked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: marked ? palette.accent : palette.textMuted,
                    onPressed: () => ref
                        .read(favoritesProvider.notifier)
                        .toggleBookmarkSurah(widget.number),
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
                      : ListView.separated(
                          controller: _controller,
                          physics: const ClampingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(18, 4, 18, 32),
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);
    final marked = fav.ayahs.any((a) =>
        a.surah == widget.surah.number && a.ayah == widget.ayah.numberInSurah);
    final ayah = widget.ayah;
    final surah = widget.surah;

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
                    child: Icon(
                      marked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      size: 18,
                      color: marked ? palette.accent : palette.textSubtle,
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
