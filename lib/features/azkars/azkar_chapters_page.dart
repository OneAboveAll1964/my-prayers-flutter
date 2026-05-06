import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/hisnul_repository.dart';
import '../../shared/models/azkar.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';
import 'package:ionicons/ionicons.dart';

class AzkarChaptersPage extends ConsumerStatefulWidget {
  const AzkarChaptersPage({super.key, required this.categoryId});
  final int categoryId;

  @override
  ConsumerState<AzkarChaptersPage> createState() => _AzkarChaptersPageState();
}

class _AzkarChaptersPageState extends ConsumerState<AzkarChaptersPage> {
  bool _loading = true;
  List<AzkarChapter> _chapters = [];
  String _categoryName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppL10n.of(context);
    final list = await HisnulMuslimRepository.instance.getChapters(
      langCode: langKey(l10n.locale),
      categoryId: widget.categoryId,
    );
    if (!mounted) return;
    setState(() {
      _chapters = list;
      _loading = false;
      _categoryName = list.isNotEmpty ? list.first.categoryName : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: _categoryName.isEmpty
                  ? AppL10n.of(context).t('nav.azkars')
                  : _categoryName,
              back: true,
            ),
            Expanded(
              child: _loading
                  ? const PageLoader()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                      children: [
                        AppSurface(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < _chapters.length; i++) ...[
                                _ChapterRow(
                                  chapter: _chapters[i],
                                  starred:
                                      fav.chapters.contains(_chapters[i].id),
                                  onTap: () => context.push(
                                      '/azkars/chapter/${_chapters[i].id}?name=${Uri.encodeComponent(_chapters[i].name)}'),
                                  onStar: () => ref
                                      .read(favoritesProvider.notifier)
                                      .toggleChapter(_chapters[i].id),
                                ),
                                if (i < _chapters.length - 1)
                                  Container(height: 1, color: palette.line),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterRow extends StatefulWidget {
  const _ChapterRow({
    required this.chapter,
    required this.starred,
    required this.onTap,
    required this.onStar,
  });

  final AzkarChapter chapter;
  final bool starred;
  final VoidCallback onTap;
  final VoidCallback onStar;

  @override
  State<_ChapterRow> createState() => _ChapterRowState();
}

class _ChapterRowState extends State<_ChapterRow> {
  bool _downBody = false;
  bool _downStar = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _downStar = true),
          onTapCancel: () => setState(() => _downStar = false),
          onTapUp: (_) => setState(() => _downStar = false),
          onTap: widget.onStar,
          child: AnimatedContainer(
            duration: AppTokens.durationFast,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _downStar ? palette.surface2 : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              widget.starred ? Ionicons.star : Ionicons.star_outline,
              color: widget.starred ? palette.accent : palette.textSubtle,
              size: 22,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _downBody = true),
            onTapCancel: () => setState(() => _downBody = false),
            onTapUp: (_) => setState(() => _downBody = false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: AppTokens.durationFast,
              padding: const EdgeInsets.fromLTRB(8, 14, 16, 14),
              color: _downBody ? palette.surface2 : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.chapter.name,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    isRtl
                        ? Ionicons.chevron_back
                        : Ionicons.chevron_forward,
                    size: 18,
                    color: palette.textSubtle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
