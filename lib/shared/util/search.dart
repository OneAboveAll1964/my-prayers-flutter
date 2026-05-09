/// Normalize a string for fuzzy/diacritic-insensitive search matching.
///
/// - Lowercases Latin characters.
/// - Strips Arabic harakat (U+064B–U+065F), superscript alif (U+0670), and
///   tatweel (U+0640).
/// - Folds alif variants (آ، أ، إ، ٱ) → ا.
/// - Folds ta marbuta (ة) → ha (ه).
/// - Folds alif maksura (ى) → ya (ي).
/// - Folds common Latin transliteration diacritics (ā→a, ḥ→h, ṣ→s, …).
/// - Drops everything that isn't an ASCII alphanumeric or an Arabic letter,
///   so spaces, hyphens, dots, apostrophes, and brackets are ignored.
String normalizeForSearch(String s) {
  if (s.isEmpty) return s;
  var out = s.toLowerCase();

  out = out.replaceAll(RegExp(r'[ً-ٰٟـ]'), '');
  out = out.replaceAll(RegExp(r'[آأإٱ]'), 'ا');
  out = out.replaceAll('ة', 'ه');
  out = out.replaceAll('ى', 'ي');

  out = _foldLatin(out);

  out = out.replaceAll(RegExp(r'[^a-z0-9؀-ۿ]'), '');
  return out;
}

/// True if `needle` (after normalization) appears anywhere in `haystack`.
bool matchesQuery(String haystack, String needle) {
  final n = normalizeForSearch(needle);
  if (n.isEmpty) return true;
  return normalizeForSearch(haystack).contains(n);
}

/// True if any of the haystacks contain the normalized needle.
bool matchesAny(Iterable<String> haystacks, String needle) {
  final n = normalizeForSearch(needle);
  if (n.isEmpty) return true;
  for (final h in haystacks) {
    if (normalizeForSearch(h).contains(n)) return true;
  }
  return false;
}

const Map<String, String> _latinFold = {
  'ā': 'a', 'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'ą': 'a', 'ă': 'a',
  'ē': 'e', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ę': 'e', 'ě': 'e',
  'ī': 'i', 'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ō': 'o', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ő': 'o',
  'ū': 'u', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ű': 'u',
  'ḥ': 'h', 'ḫ': 'h', 'ḩ': 'h',
  'ṣ': 's', 'š': 's', 'ś': 's', 'ş': 's',
  'ḍ': 'd', 'ḏ': 'd', 'đ': 'd',
  'ṭ': 't', 'ṯ': 't', 'ţ': 't',
  'ẓ': 'z', 'ž': 'z', 'ź': 'z', 'ż': 'z',
  'ñ': 'n', 'ń': 'n',
  'ç': 'c', 'č': 'c', 'ć': 'c',
  'ġ': 'g',
  'ŋ': 'n',
  'ł': 'l',
  'ʿ': '', 'ʾ': '', '`': '',
};

String _foldLatin(String s) {
  if (s.isEmpty) return s;
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    buf.write(_latinFold[ch] ?? ch);
  }
  return buf.toString();
}
