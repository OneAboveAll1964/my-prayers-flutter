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
    final intl = _intlLocale(l10n.locale.languageCode);
    final day = DateFormat.EEEE(intl).format(gregorian);
    final dateLine = DateFormat.MMMd(intl).format(gregorian);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(
            day,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text('·', style: TextStyle(color: palette.textSubtle, fontSize: 13.5)),
          Text(
            dateLine,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text('·', style: TextStyle(color: palette.textSubtle, fontSize: 13.5)),
          Text(
            hijri,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
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
