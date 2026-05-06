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
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      itemCount: _chapters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final c = _chapters[i];
                        final starred = fav.chapters.contains(c.id);
                        return _ChapterTile(
                          chapter: c,
                          starred: starred,
                          onTap: () => context.push(
                              '/azkars/chapter/${c.id}?name=${Uri.encodeComponent(c.name)}'),
                          onStar: () => ref
                              .read(favoritesProvider.notifier)
                              .toggleChapter(c.id),
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

class _ChapterTile extends StatefulWidget {
  const _ChapterTile({
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
  State<_ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<_ChapterTile> {
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
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: _down ? palette.surface2 : palette.surface,
          border: Border.all(color: palette.line),
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.chapter.name,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onStar,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    widget.starred
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: widget.starred ? palette.accent : palette.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.textMuted,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
