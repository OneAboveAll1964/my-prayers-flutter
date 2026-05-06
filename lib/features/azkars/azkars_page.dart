import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/hisnul_repository.dart';
import '../../shared/models/azkar.dart';
import '../../shared/widgets/app_field.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';

class AzkarsPage extends ConsumerStatefulWidget {
  const AzkarsPage({super.key});
  @override
  ConsumerState<AzkarsPage> createState() => _AzkarsPageState();
}

class _AzkarsPageState extends ConsumerState<AzkarsPage> {
  List<AzkarCategory> _categories = [];
  List<AzkarChapter> _searchResults = [];
  bool _loading = true;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppL10n.of(context);
    final cats = await HisnulMuslimRepository.instance
        .getCategories(langKey(l10n.locale));
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  Future<void> _runSearch(String q) async {
    final l10n = AppL10n.of(context);
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await HisnulMuslimRepository.instance
        .searchChapters(langCode: langKey(l10n.locale), query: q);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Column(
      children: [
        PageHeader(
          title: l10n.t('azkars.title'),
          search: AppTextField(
            hintText: l10n.t('azkars.search'),
            prefix: Icon(Icons.search_rounded, size: 18, color: palette.textMuted),
            onChanged: (v) {
              setState(() => _query = v);
              _runSearch(v);
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const PageLoader()
              : _query.trim().isNotEmpty
                  ? _SearchResults(results: _searchResults)
                  : _CategoryList(categories: _categories),
        ),
      ],
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});
  final List<AzkarCategory> categories;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      itemCount: categories.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _CategoryTile(cat: categories[i]),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({required this.cat});
  final AzkarCategory cat;
  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => context.push('/azkars/category/${widget.cat.id}'),
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: _down ? palette.surface2 : palette.surface,
          border: Border.all(color: palette.line),
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.cat.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isRtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: palette.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results});
  final List<AzkarChapter> results;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          l10n.t('common.noResults'),
          style: TextStyle(color: palette.textMuted),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < results.length; i++) ...[
                _ChapterListRow(chapter: results[i]),
                if (i < results.length - 1)
                  Container(height: 1, color: palette.line),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChapterListRow extends StatefulWidget {
  const _ChapterListRow({required this.chapter});
  final AzkarChapter chapter;

  @override
  State<_ChapterListRow> createState() => _ChapterListRowState();
}

class _ChapterListRowState extends State<_ChapterListRow> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => context.push(
          '/azkars/chapter/${widget.chapter.id}?name=${Uri.encodeComponent(widget.chapter.name)}'),
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        color: _down ? palette.surface2 : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.chapter.name,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            Icon(
              isRtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: palette.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}
