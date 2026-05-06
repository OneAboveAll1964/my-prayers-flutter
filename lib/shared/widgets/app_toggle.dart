import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppTokens.duration,
        curve: AppTokens.ease,
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? palette.accent : palette.surface3,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: value ? palette.accentOn : palette.surface,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
