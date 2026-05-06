import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

enum SegmentedLayout { row, grid }

class SegmentedOption<T> {
  const SegmentedOption({required this.value, required this.label});
  final T value;
  final String label;
}

class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.layout = SegmentedLayout.row,
  });

  final T value;
  final List<SegmentedOption<T>> options;
  final ValueChanged<T> onChanged;
  final SegmentedLayout layout;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget item(SegmentedOption<T> opt) {
      final selected = opt.value == value;
      return _SegmentItem(
        label: opt.label,
        selected: selected,
        palette: palette,
        onTap: () => onChanged(opt.value),
      );
    }

    if (layout == SegmentedLayout.row) {
      return Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            for (final opt in options)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: item(opt),
                ),
              ),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += 2) {
      final left = options[i];
      final right = i + 1 < options.length ? options[i + 1] : null;
      rows.add(Row(
        children: [
          Expanded(child: SizedBox(height: 36, child: item(left))),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: 36,
              child: right == null ? const SizedBox.shrink() : item(right),
            ),
          ),
        ],
      ));
      if (i + 2 < options.length) rows.add(const SizedBox(height: 4));
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }
}

class _SegmentItem extends StatefulWidget {
  const _SegmentItem({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  State<_SegmentItem> createState() => _SegmentItemState();
}

class _SegmentItemState extends State<_SegmentItem> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        curve: AppTokens.ease,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.selected
              ? p.surface
              : (_down ? p.surface3 : Colors.transparent),
          borderRadius: BorderRadius.circular(999),
          border: widget.selected
              ? Border.all(color: p.lineStrong, width: 1)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: widget.selected ? p.text : p.textMuted,
              letterSpacing: -0.05,
            ),
          ),
        ),
      ),
    );
  }
}
