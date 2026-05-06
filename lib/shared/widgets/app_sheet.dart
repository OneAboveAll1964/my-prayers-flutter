import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext) builder,
}) {
  final palette = context.palette;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    barrierColor: palette.text.withValues(alpha: 0.32),
    backgroundColor: palette.surface,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    useSafeArea: true,
    showDragHandle: false,
    builder: (ctx) {
      return _SheetBody(title: title, child: Builder(builder: builder));
    },
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final media = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, controller) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(
                      18, 4, 18, 18 + media.padding.bottom),
                  children: [child],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
