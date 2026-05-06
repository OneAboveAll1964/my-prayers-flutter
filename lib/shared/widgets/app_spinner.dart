import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.6,
        valueColor: AlwaysStoppedAnimation<Color>(context.palette.accent),
        backgroundColor: context.palette.line,
      ),
    );
  }
}

class PageLoader extends StatelessWidget {
  const PageLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: AppSpinner(),
      ),
    );
  }
}
