import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';

class DateBar extends StatelessWidget {
  const DateBar({super.key, required this.gregorian, required this.hijri});

  final DateTime gregorian;
  final String hijri;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final intlLocale = _intlLocale(l10n.locale.languageCode);
    final day = DateFormat.EEEE(intlLocale).format(gregorian);
    final dateLine = DateFormat.yMMMMd(intlLocale).format(gregorian);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: TextStyle(
              color: palette.textSubtle,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateLine,
            style: TextStyle(
              color: palette.text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hijri,
            style: TextStyle(color: palette.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _intlLocale(String code) {
    if (code == 'ckb' || code == 'ckb_Badini') return 'ar';
    return code;
  }
}
