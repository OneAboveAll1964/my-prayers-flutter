import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/hisnul_repository.dart';
import '../../shared/models/azkar.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';

class AzkarItemsPage extends ConsumerStatefulWidget {
  const AzkarItemsPage({
    super.key,
    required this.chapterId,
    required this.categoryName,
    required this.chapterName,
  });

  final int chapterId;
  final String categoryName;
  final String chapterName;

  @override
  ConsumerState<AzkarItemsPage> createState() => _AzkarItemsPageState();
}

class _AzkarItemsPageState extends ConsumerState<AzkarItemsPage> {
  bool _loading = true;
  List<AzkarItem> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppL10n.of(context);
    final list = await HisnulMuslimRepository.instance.getItems(
      langCode: langKey(l10n.locale),
      chapterId: widget.chapterId,
    );
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: widget.chapterName, back: true),
            Expanded(
              child: _loading
                  ? const PageLoader()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) =>
                          _AzkarItemCard(item: _items[i], index: i + 1),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AzkarItemCard extends ConsumerWidget {
  const _AzkarItemCard({required this.item, required this.index});
  final AzkarItem item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final settings = ref.watch(settingsProvider);
    final fontFamily = arabicFontFamilies[settings.arabicFont] ?? 'AmiriQuran';
    final fav = ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);

    final dhikr = fav.dhikr[item.id] ?? 0;
    final target = item.count ?? 1;
    final reached = target > 0 && dhikr >= target;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (item.reference.isNotEmpty)
                Text(
                  item.reference,
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textSubtle,
                  ),
                ),
            ],
          ),
          if (item.topNote != null && item.topNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              item.topNote!,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          if (item.item != null && item.item!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                item.item!,
                style: TextStyle(
                  color: palette.text,
                  fontFamily: fontFamily,
                  fontSize: 22,
                  height: 1.85,
                ),
              ),
            ),
          ],
          if (item.transliteration != null &&
              item.transliteration!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.transliteration!,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
          if (item.translation != null && item.translation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.translation!,
              style: TextStyle(
                color: palette.text,
                fontSize: 14.5,
                height: 1.55,
              ),
            ),
          ],
          if (item.bottomNote != null && item.bottomNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.bottomNote!,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
            ),
          ],
          if (item.count != null && item.count! > 0) ...[
            const SizedBox(height: 14),
            _DhikrCounter(
              count: dhikr,
              target: target,
              reached: reached,
              onTap: () =>
                  notifier.setDhikr(item.id, dhikr + 1 > target ? 0 : dhikr + 1),
              onReset: () => notifier.setDhikr(item.id, 0),
              tapLabel: l10n.t('azkars.tap'),
              resetLabel: l10n.t('azkars.reset'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DhikrCounter extends StatelessWidget {
  const _DhikrCounter({
    required this.count,
    required this.target,
    required this.reached,
    required this.onTap,
    required this.onReset,
    required this.tapLabel,
    required this.resetLabel,
  });

  final int count;
  final int target;
  final bool reached;
  final VoidCallback onTap;
  final VoidCallback onReset;
  final String tapLabel;
  final String resetLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: reached ? palette.accent : palette.surface2,
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(
                  color: reached ? palette.accent : palette.line,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '$count / $target',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: reached ? palette.accentOn : palette.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    tapLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: reached
                          ? palette.accentOn.withValues(alpha: 0.8)
                          : palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onReset,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: palette.line),
            ),
            child: Icon(Icons.restart_alt_rounded,
                size: 18, color: palette.textMuted),
          ),
        ),
      ],
    );
  }
}
