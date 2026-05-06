import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

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
    final wrapped = options.map((opt) {
      final selected = opt.value == value;
      final child = AnimatedContainer(
        duration: AppTokens.durationFast,
        curve: AppTokens.ease,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: palette.lineStrong) : null,
        ),
        child: Text(
          opt.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: selected ? palette.text : palette.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(opt.value),
        child: child,
      );
    }).toList();

    final container = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      child: layout == SegmentedLayout.row
          ? Row(
              children: [
                for (final w in wrapped) Expanded(child: w),
              ],
            )
          : GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 3.4,
              children: wrapped,
            ),
    );
    return container;
  }
}

enum SegmentedLayout { row, grid }

class SegmentedOption<T> {
  const SegmentedOption({required this.value, required this.label});
  final T value;
  final String label;
}
