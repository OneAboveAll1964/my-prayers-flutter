import 'package:flutter/material.dart';

class SurahNameFont {
  SurahNameFont._();

  static const String fontFamily = 'SurahNameV2';

  static String glyphFor(int surahNumber) =>
      'surah${surahNumber.toString().padLeft(3, '0')}';

  /// Builds a Row that combines an optional prefix (e.g. "Tafsir"),
  /// the calligraphic surah glyph, and an optional ayah number, all
  /// separated by " · ". Designed for sheet/page titles.
  static Widget buildTitle({
    required int surahNumber,
    String? prefix,
    int? ayahNumber,
    double glyphSize = 24,
    double textSize = 17,
    FontWeight textWeight = FontWeight.w700,
    Color? color,
  }) {
    final divider = Text(
      ' · ',
      style: TextStyle(
        fontSize: textSize,
        fontWeight: textWeight,
        color: color,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null && prefix.isNotEmpty) ...[
          Flexible(
            child: Text(
              prefix,
              style: TextStyle(
                fontSize: textSize,
                fontWeight: textWeight,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          divider,
        ],
        Text(
          glyphFor(surahNumber),
          style: TextStyle(
            fontSize: glyphSize,
            height: 1.0,
            fontFamily: fontFamily,
            color: color,
          ),
        ),
        if (ayahNumber != null) ...[
          divider,
          Text(
            '$ayahNumber',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: textWeight,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}
