import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';

class LocationBar extends StatelessWidget {
  const LocationBar({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: () => context.push('/settings/location'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surface2,
          border: Border.all(color: palette.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_rounded, size: 14, color: palette.accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: palette.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
