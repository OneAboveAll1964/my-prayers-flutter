import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/quran.dart';
import '../../../shared/state/favorites_provider.dart';
import 'ayah_actions_sheet.dart';

class MushafView extends ConsumerStatefulWidget {
  const MushafView({
    super.key,
    required this.surah,
    required this.fontFamily,
    required this.arScale,
    required this.fullscreen,
    required this.onToggleFullscreen,
    this.initialAyah,
  });

  final Surah surah;
  final String fontFamily;
  final double arScale;
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;
  final int? initialAyah;

  @override
  ConsumerState<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends ConsumerState<MushafView> {
  late final List<_MushafPage> _pages;
  late final PageController _pageController;
  int? _selectedAyah;

  double? _baseFont;
  double? _bodyHeight;
  String? _baseKey;

  @override
  void initState() {
    super.initState();
    _pages = _groupByPage(widget.surah.ayahs);
    final initial = widget.initialAyah == null
        ? 0
        : _pages.indexWhere(
            (p) => p.ayahs.any((a) => a.numberInSurah == widget.initialAyah));
    _pageController = PageController(initialPage: initial < 0 ? 0 : initial);
  }

  @override
  void didUpdateWidget(covariant MushafView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fontFamily != widget.fontFamily ||
        oldWidget.fullscreen != widget.fullscreen) {
      _baseFont = null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static List<_MushafPage> _groupByPage(List<Ayah> ayahs) {
    final out = <_MushafPage>[];
    for (final a in ayahs) {
      if (out.isEmpty || out.last.pageNumber != a.page) {
        out.add(_MushafPage(pageNumber: a.page, ayahs: [a]));
      } else {
        out.last.ayahs.add(a);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (rootCtx, rootC) {
      final viewportKey =
          '${rootC.maxWidth.toStringAsFixed(0)}x${rootC.maxHeight.toStringAsFixed(0)}|${widget.fontFamily}|${widget.fullscreen}';
      if (_baseFont == null || _baseKey != viewportKey) {
        const headerH = 28.0;
        const footerH = 48.0;
        const padH = 18.0;
        const padV = 8.0;
        final width = rootC.maxWidth - padH * 2;
        final available = widget.fullscreen
            ? rootC.maxHeight - 56 - padV * 2
            : rootC.maxHeight - headerH - footerH - padV * 2;
        final body = available * 0.94;
        _bodyHeight = available;
        _baseFont = _computeBaseFont(width: width, height: body);
        _baseKey = viewportKey;
      }
      final size = _baseFont! * widget.arScale;
      return Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            reverse: Directionality.of(context) == TextDirection.rtl,
            itemBuilder: (ctx, idx) {
              final page = _pages[idx];
              return _MushafPageView(
                page: page,
                surahNumber: widget.surah.number,
                fontFamily: widget.fontFamily,
                fontSize: size,
                arScale: widget.arScale,
                selectedAyah: _selectedAyah,
                onTapAyah: _handleTap,
                totalPages: _pages.length,
                pageIndex: idx,
                fullscreen: widget.fullscreen,
                onToggleFullscreen: widget.onToggleFullscreen,
                bodyHeight: _bodyHeight ?? rootC.maxHeight,
              );
            },
          ),
          if (widget.fullscreen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right:
                  Directionality.of(context) == TextDirection.rtl ? null : 12,
              left:
                  Directionality.of(context) == TextDirection.rtl ? 12 : null,
              child: _FloatingButton(
                icon: Ionicons.contract_outline,
                onTap: widget.onToggleFullscreen,
              ),
            ),
        ],
      );
    });
  }

  double _computeBaseFont({required double width, required double height}) {
    var minSize = 26.0;
    for (final page in _pages) {
      final s = _maxFitForPage(page, width: width, height: height);
      if (s < minSize) minSize = s;
    }
    return minSize.clamp(14.0, 26.0);
  }

  double _maxFitForPage(
    _MushafPage page, {
    required double width,
    required double height,
  }) {
    final measure = _pageMeasureText(page);
    var lo = 14.0;
    var hi = 26.0;
    for (var i = 0; i < 8; i++) {
      final mid = (lo + hi) / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: measure,
          style: TextStyle(
            fontFamily: widget.fontFamily,
            fontSize: mid,
            height: 2.0,
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      )..layout(maxWidth: width);
      if (tp.height <= height) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  String _pageMeasureText(_MushafPage page) {
    final buf = StringBuffer();
    for (var i = 0; i < page.ayahs.length; i++) {
      buf.write(page.ayahs[i].arabic);
      buf.write(' ۝${_arabicNumber(page.ayahs[i].numberInSurah)} ');
    }
    return buf.toString();
  }

  void _handleTap(Ayah ayah) {
    setState(() => _selectedAyah = ayah.numberInSurah);
    showAyahActionsSheet(
      context: context,
      surah: widget.surah,
      ayah: ayah,
      ref: ref,
      fontFamily: widget.fontFamily,
      arScale: widget.arScale,
    ).whenComplete(() {
      if (!mounted) return;
      setState(() => _selectedAyah = null);
    });
  }
}

class _MushafPage {
  _MushafPage({required this.pageNumber, required this.ayahs});
  final int pageNumber;
  final List<Ayah> ayahs;
}

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String _arabicNumber(int n) =>
    n.toString().split('').map((c) => _arabicDigits[int.parse(c)]).join();

String _localeNumber(int n, BuildContext context) {
  final lang = AppL10n.of(context).locale.languageCode;
  if (lang == 'en') return n.toString();
  return _arabicNumber(n);
}

class _MushafPageView extends ConsumerWidget {
  const _MushafPageView({
    required this.page,
    required this.surahNumber,
    required this.fontFamily,
    required this.fontSize,
    required this.arScale,
    required this.selectedAyah,
    required this.onTapAyah,
    required this.totalPages,
    required this.pageIndex,
    required this.fullscreen,
    required this.onToggleFullscreen,
    required this.bodyHeight,
  });

  final _MushafPage page;
  final int surahNumber;
  final String fontFamily;
  final double fontSize;
  final double arScale;
  final int? selectedAyah;
  final void Function(Ayah ayah) onTapAyah;
  final int totalPages;
  final int pageIndex;
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;
  final double bodyHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);
    final l10n = AppL10n.of(context);
    final spans = _buildSpans(palette: palette, fav: fav);

    final body = Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: double.infinity,
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
        ),
      ),
    );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (fullscreen) const SizedBox(height: 56),
          if (!fullscreen)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Row(
                children: [
                  Text(
                    '${l10n.t('quran.juz')} ${_localeNumber(page.ayahs.first.juz, context)}',
                    style: TextStyle(
                      color: palette.textSubtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${l10n.t('quran.page')} ${_localeNumber(page.pageNumber, context)}',
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: arScale > 1.0
                  ? SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: body,
                    )
                  : Center(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: body,
                      ),
                    ),
            ),
          ),
          if (!fullscreen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggleFullscreen,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.line),
                      ),
                      child: Icon(Ionicons.expand_outline,
                          size: 16, color: palette.textMuted),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_localeNumber(pageIndex + 1, context)} / ${_localeNumber(totalPages, context)}',
                        style: TextStyle(
                          color: palette.textSubtle,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildSpans({
    required AppPalette palette,
    required FavoritesState fav,
  }) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < page.ayahs.length; i++) {
      final a = page.ayahs[i];
      final isBookmarked = fav.ayahs
          .any((e) => e.surah == surahNumber && e.ayah == a.numberInSurah);
      final selected = selectedAyah == a.numberInSurah;
      final tap = TapGestureRecognizer()..onTap = () => onTapAyah(a);

      final fillColor = selected
          ? palette.accentSoft
          : (isBookmarked
              ? palette.accentSoft.withValues(alpha: 0.5)
              : null);

      spans.add(TextSpan(
        text: a.arabic,
        recognizer: tap,
        style: TextStyle(
          color: palette.text,
          fontFamily: fontFamily,
          fontSize: fontSize,
          height: 2.0,
          background: fillColor == null ? null : (Paint()..color = fillColor),
        ),
      ));

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTapAyah(a),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: fontSize * 0.08),
            child: SizedBox(
              width: fontSize * 1.4,
              height: fontSize * 1.6,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '۝',
                    style: TextStyle(
                      color: palette.accent,
                      fontFamily: fontFamily,
                      fontSize: fontSize * 1.5,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    _arabicNumber(a.numberInSurah),
                    style: TextStyle(
                      color: palette.accent,
                      fontFamily: fontFamily,
                      fontSize: fontSize * 0.42,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }
    return spans;
  }
}

class _FloatingButton extends StatelessWidget {
  const _FloatingButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.line),
        ),
        child: Icon(icon, size: 18, color: palette.textMuted),
      ),
    );
  }
}
