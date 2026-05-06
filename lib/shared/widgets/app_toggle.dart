import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppTokens.duration,
        curve: AppTokens.ease,
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? palette.accent : palette.surface3,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? palette.accent : palette.line,
          ),
        ),
        alignment: value
            ? (isRtl ? Alignment.centerLeft : Alignment.centerRight)
            : (isRtl ? Alignment.centerRight : Alignment.centerLeft),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
