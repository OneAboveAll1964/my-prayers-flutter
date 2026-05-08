import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/hisnul_repository.dart';
import '../../shared/models/azkar.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/animated_toggle_icon.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_sheet.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../settings/widgets/arabic_font_picker.dart';
import 'package:ionicons/ionicons.dart';

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
    final l10n = AppL10n.of(context);
    final fav = ref.watch(favoritesProvider);
    final isStarred = fav.chapters.contains(widget.chapterId);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: widget.chapterName,
              back: true,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        .toggleChapter(widget.chapterId),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: AnimatedToggleIcon(
                          outlineIcon: Ionicons.star_outline,
                          filledIcon: Ionicons.star,
                          active: isStarred,
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
    final settings = ref.watch(settingsProvider);
    final fontFamily = arabicFontFamilies[settings.arabicFont] ?? 'UthmanicHafs';
    final arScale = settings.arabicFontScale;
    final trScale = settings.translationFontScale;
    final bold = settings.quranBold;
    final fav = ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);

    final dhikr = fav.dhikr[item.id] ?? 0;
    final target = item.count ?? 0;
    final hasTarget = target > 0;
    final reached = hasTarget && dhikr >= target;
    final progress = hasTarget ? (dhikr / target).clamp(0.0, 1.0) : 0.0;

    void increment() {
      HapticFeedback.selectionClick();
      if (hasTarget) {
        final next = dhikr + 1;
        final reset = next > target;
        notifier.setDhikr(item.id, reset ? 0 : next);
      } else {
        notifier.setDhikr(item.id, dhikr + 1);
      }
    }

    void reset() {
      HapticFeedback.lightImpact();
      notifier.setDhikr(item.id, 0);
    }

    final card = AnimatedContainer(
      duration: AppTokens.durationFast,
      curve: AppTokens.ease,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
          color: reached ? palette.accent : palette.line,
          width: 1,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 4),
            child: Row(
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
                if (!hasTarget)
                  AnimatedContainer(
                    duration: AppTokens.duration,
                    curve: AppTokens.ease,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: dhikr > 0
                          ? palette.accentSoft
                          : palette.surface2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$dhikr',
                      style: TextStyle(
                        color: dhikr > 0
                            ? palette.accentStrong
                            : palette.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                AnimatedSize(
                  duration: AppTokens.duration,
                  curve: AppTokens.ease,
                  alignment: Alignment.centerLeft,
                  child: dhikr > 0
                      ? _ResetButton(onTap: reset)
                      : const SizedBox(width: 0, height: 36),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.topNote != null && item.topNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                  SizedBox(
                    width: double.infinity,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        item.item!,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: palette.text,
                          fontFamily: fontFamily,
                          fontSize: 22.0 * arScale,
                          height: 2.1,
                          fontWeight:
                              bold ? FontWeight.w700 : FontWeight.normal,
                        ),
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
                      fontSize: 13.5 * trScale,
                      fontStyle: FontStyle.italic,
                      height: 1.55,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
                if (item.translation != null &&
                    item.translation!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.translation!,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 15 * trScale,
                      height: 1.7,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
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
              ],
            ),
          ),
          if (hasTarget)
            _CounterBar(
              count: dhikr,
              target: target,
              progress: progress,
              reached: reached,
            ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: increment,
      child: card,
    );
  }
}

class _CounterBar extends StatelessWidget {
  const _CounterBar({
    required this.count,
    required this.target,
    required this.progress,
    required this.reached,
  });
  final int count;
  final int target;
  final double progress;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    return AnimatedContainer(
      duration: AppTokens.durationFast,
      color: reached ? palette.accent : palette.surface2,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reached
                      ? l10n.t('common.done').toUpperCase()
                      : l10n.t('azkars.tap'),
                  style: TextStyle(
                    color: reached
                        ? palette.accentOn
                        : palette.textMuted,
                    fontSize: 13,
                    fontWeight: reached ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: reached ? 0.7 : 0,
                  ),
                ),
              ),
              Text(
                '$count / $target',
                style: TextStyle(
                  color: reached ? palette.accentOn : palette.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: reached
                  ? palette.accentOn.withValues(alpha: 0.2)
                  : palette.surface3,
              valueColor: AlwaysStoppedAnimation(
                reached ? palette.accentOn : palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatefulWidget {
  const _ResetButton({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_ResetButton> createState() => _ResetButtonState();
}

class _ResetButtonState extends State<_ResetButton> {
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
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _down ? palette.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(Ionicons.refresh,
            size: 18, color: palette.textMuted),
      ),
    );
  }
}
