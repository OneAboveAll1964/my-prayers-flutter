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
  late String _lang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lang = AppL10n.of(context).locale.languageCode;
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
                  : _CategoryGrid(categories: _categories),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});
  final List<AzkarCategory> categories;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (ctx, i) {
        return _CategoryTile(cat: categories[i]);
      },
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => context.push('/azkars/category/${widget.cat.id}'),
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: _down ? palette.surface2 : palette.surface,
          border: Border.all(color: palette.line),
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.menu_book_rounded,
                  size: 16, color: palette.accent),
            ),
            const SizedBox(height: 12),
            Text(
              widget.cat.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final c = results[i];
        return _ChapterRow(chapter: c);
      },
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter});
  final AzkarChapter chapter;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TapRow(
      onTap: () => context.push(
          '/azkars/chapter/${chapter.id}?name=${Uri.encodeComponent(chapter.name)}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: palette.line),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                chapter.name,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}
