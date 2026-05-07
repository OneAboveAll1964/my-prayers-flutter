import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    this.initialAyah,
  });

  final Surah surah;
  final String fontFamily;
  final double arScale;
  final int? initialAyah;

  @override
  ConsumerState<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends ConsumerState<MushafView> {
  late final List<_MushafPage> _pages;
  late final PageController _pageController;
  int? _selectedAyah;

  @override
  void initState() {
    super.initState();
    _pages = _groupByPage(widget.surah.ayahs);
    final initial = widget.initialAyah == null
        ? 0
        : _pages.indexWhere(
            (p) => p.ayahs.any((a) => a.numberInSurah == widget.initialAyah));
    _pageController =
        PageController(initialPage: initial < 0 ? 0 : initial);
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
    final palette = context.palette;
    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      reverse: Directionality.of(context) == TextDirection.rtl,
      itemBuilder: (ctx, idx) {
        final page = _pages[idx];
        return _MushafPageView(
          page: page,
          surahNumber: widget.surah.number,
          fontFamily: widget.fontFamily,
          arScale: widget.arScale,
          selectedAyah: _selectedAyah,
          onTapAyah: (ayah) => _handleTap(ayah, palette),
          totalPages: _pages.length,
          pageIndex: idx,
        );
      },
    );
  }

  void _handleTap(Ayah ayah, AppPalette palette) {
    setState(() => _selectedAyah = ayah.numberInSurah);
    showAyahActionsSheet(
      context: context,
      surah: widget.surah,
      ayah: ayah,
      ref: ref,
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

class _MushafPageView extends ConsumerWidget {
  const _MushafPageView({
    required this.page,
    required this.surahNumber,
    required this.fontFamily,
    required this.arScale,
    required this.selectedAyah,
    required this.onTapAyah,
    required this.totalPages,
    required this.pageIndex,
  });

  final _MushafPage page;
  final int surahNumber;
  final String fontFamily;
  final double arScale;
  final int? selectedAyah;
  final void Function(Ayah ayah) onTapAyah;
  final int totalPages;
  final int pageIndex;

  static const _arabicDigits = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
  static String _arabicNumber(int n) =>
      n.toString().split('').map((c) => _arabicDigits[int.parse(c)]).join();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);
    final size = 24.0 * arScale;
    final markerSize = 22.0 * arScale;

    final spans = <InlineSpan>[];
    for (var i = 0; i < page.ayahs.length; i++) {
      final a = page.ayahs[i];
      final isBookmarked = fav.ayahs.any(
          (e) => e.surah == surahNumber && e.ayah == a.numberInSurah);
      final selected = selectedAyah == a.numberInSurah;
      final tap = TapGestureRecognizer()..onTap = () => onTapAyah(a);

      final fillColor = selected
          ? palette.accentSoft
          : (isBookmarked ? palette.accentSoft.withValues(alpha: 0.5) : null);

      spans.add(TextSpan(
        text: a.arabic,
        recognizer: tap,
        style: TextStyle(
          color: palette.text,
          fontFamily: fontFamily,
          fontSize: size,
          height: 2.1,
          background: fillColor == null ? null : (Paint()..color = fillColor),
        ),
      ));

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTapAyah(a),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _AyahMarker(
              number: a.numberInSurah,
              size: markerSize,
              accentColor: palette.accent,
              backgroundColor: palette.bg,
            ),
          ),
        ),
      ));

      if (i < page.ayahs.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Text(
                  '${AppL10n.of(context).t('quran.juz')} ${_arabicNumber(page.ayahs.first.juz)}',
                  style: TextStyle(
                    color: palette.textSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${AppL10n.of(context).t('quran.page')} ${_arabicNumber(page.pageNumber)}',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text.rich(
                  TextSpan(children: spans),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14, top: 4),
            child: Center(
              child: Text(
                '${pageIndex + 1} / $totalPages',
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

class _AyahMarker extends StatelessWidget {
  const _AyahMarker({
    required this.number,
    required this.size,
    required this.accentColor,
    required this.backgroundColor,
  });

  final int number;
  final double size;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: accentColor, width: 1.4),
      ),
      child: Text(
        _MushafPageView._arabicNumber(number),
        style: TextStyle(
          color: accentColor,
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
          height: 1.0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
