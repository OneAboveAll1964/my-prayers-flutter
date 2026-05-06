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
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                      itemCount: _items.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
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
    final target = item.count ?? 0;
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
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Spacer(),
              if (target > 0)
                _CounterPill(
                  count: dhikr,
                  target: target,
                  reached: reached,
                  onTap: () => notifier.setDhikr(
                      item.id, dhikr + 1 > target ? 0 : dhikr + 1),
                  onReset: () => notifier.setDhikr(item.id, 0),
                ),
            ],
          ),
          if (item.topNote != null && item.topNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              item.topNote!,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
          if (item.item != null && item.item!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                item.item!,
                style: TextStyle(
                  color: palette.text,
                  fontFamily: fontFamily,
                  fontSize: 21,
                  height: 2.2,
                ),
              ),
            ),
          ],
          if (item.transliteration != null &&
              item.transliteration!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.transliteration!,
              style: TextStyle(
                color: palette.text,
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                height: 1.55,
              ),
            ),
          ],
          if (item.translation != null && item.translation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.translation!,
              style: TextStyle(
                color: palette.text,
                fontSize: 15,
                height: 1.7,
              ),
            ),
          ],
          if (item.bottomNote != null && item.bottomNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.bottomNote!,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
          if (item.reference.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.reference,
              style: TextStyle(
                color: palette.textSubtle,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          if (target == 0) ...[
            const SizedBox(height: 8),
            _ReadToggle(
              done: dhikr > 0,
              onToggle: () => notifier.setDhikr(item.id, dhikr > 0 ? 0 : 1),
              label: l10n.t('azkars.tap'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CounterPill extends StatefulWidget {
  const _CounterPill({
    required this.count,
    required this.target,
    required this.reached,
    required this.onTap,
    required this.onReset,
  });
  final int count;
  final int target;
  final bool reached;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  State<_CounterPill> createState() => _CounterPillState();
}

class _CounterPillState extends State<_CounterPill> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bg = widget.reached ? palette.accent : palette.accentSoft;
    final fg = widget.reached ? palette.accentOn : palette.accentStrong;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppTokens.durationFast,
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _down ? palette.surface2 : bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: '${widget.count}'),
                    TextSpan(
                      text: ' / ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: fg.withValues(alpha: 0.6),
                      ),
                    ),
                    TextSpan(text: '${widget.target}'),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.count > 0) ...[
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onReset,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Icon(Icons.refresh_rounded,
                  size: 16, color: palette.textMuted),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReadToggle extends StatelessWidget {
  const _ReadToggle({
    required this.done,
    required this.onToggle,
    required this.label,
  });
  final bool done;
  final VoidCallback onToggle;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: done ? palette.accent : palette.surface2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: done ? palette.accentOn : palette.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
