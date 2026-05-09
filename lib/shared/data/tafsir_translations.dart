const Map<int, Map<String, String>> _tafsirNames = {
  14: {
    'en': 'Tafsir Ibn Kathir',
    'ar': 'تفسير ابن كثير',
    'ckb': 'تەفسیری ئیبن کەسیر',
    'ckb_Badini': 'تەفسیرا ئیبن کەسیر',
  },
  15: {
    'en': 'Tafsir al-Tabari',
    'ar': 'تفسير الطبري',
    'ckb': 'تەفسیری تەبەری',
    'ckb_Badini': 'تەفسیرا تەبەری',
  },
  16: {
    'en': 'Tafsir al-Muyassar',
    'ar': 'التفسير الميسر',
    'ckb': 'تەفسیری میەسسەر',
    'ckb_Badini': 'تەفسیرا میەسسەر',
  },
  90: {
    'en': 'Tafsir al-Qurtubi',
    'ar': 'تفسير القرطبي',
    'ckb': 'تەفسیری قورتوبی',
    'ckb_Badini': 'تەفسیرا قورتوبی',
  },
  91: {
    'en': "Tafsir al-Sa'di",
    'ar': 'تفسير السعدي',
    'ckb': 'تەفسیری سەعدی',
    'ckb_Badini': 'تەفسیرا سەعدی',
  },
  93: {
    'en': 'al-Tafsir al-Wasit (Tantawi)',
    'ar': 'التفسير الوسيط (الطنطاوي)',
    'ckb': 'تەفسیری وەسیت (تەنتاوی)',
    'ckb_Badini': 'تەفسیرا وەسیت (تەنتاوی)',
  },
  94: {
    'en': 'Tafsir al-Baghawi',
    'ar': 'تفسير البغوي',
    'ckb': 'تەفسیری بەغەوی',
    'ckb_Badini': 'تەفسیرا بەغەوی',
  },
  157: {
    'en': "Fi Zilal al-Qur'an",
    'ar': 'في ظلال القرآن',
    'ckb': 'فی ظلال القرآن',
    'ckb_Badini': 'فی ظلال القرآن',
  },
  159: {
    'en': "Bayan ul Qur'an",
    'ar': 'بيان القرآن',
    'ckb': 'بەیانی قورئان',
    'ckb_Badini': 'بەیانا قورئانێ',
  },
  160: {
    'en': 'Tafsir Ibn Kathir',
    'ar': 'تفسير ابن كثير',
    'ckb': 'تەفسیری ئیبن کەسیر',
    'ckb_Badini': 'تەفسیرا ئیبن کەسیر',
  },
  164: {
    'en': 'Tafsir Ibn Kathir',
    'ar': 'تفسير ابن كثير',
    'ckb': 'تەفسیری ئیبن کەسیر',
    'ckb_Badini': 'تەفسیرا ئیبن کەسیر',
  },
  165: {
    'en': 'Tafsir Ahsanul Bayaan',
    'ar': 'تفسير أحسن البيان',
    'ckb': 'تەفسیری ئەحسەنول بەیان',
    'ckb_Badini': 'تەفسیرا ئەحسەنول بەیان',
  },
  166: {
    'en': 'Tafsir Abu Bakr Zakaria',
    'ar': 'تفسير أبو بكر زكريا',
    'ckb': 'تەفسیری ئەبو بەکر زەکەریا',
    'ckb_Badini': 'تەفسیرا ئەبو بەکر زەکەریا',
  },
  168: {
    'en': "Ma'arif al-Qur'an",
    'ar': 'معارف القرآن',
    'ckb': 'مەعاریفی قورئان',
    'ckb_Badini': 'مەعاریفا قورئانێ',
  },
  169: {
    'en': 'Tafsir Ibn Kathir (Abridged)',
    'ar': 'تفسير ابن كثير (مختصر)',
    'ckb': 'تەفسیری ئیبن کەسیر (کورتکراوە)',
    'ckb_Badini': 'تەفسیرا ئیبن کەسیر (کورتکری)',
  },
  170: {
    'en': "Tafsir al-Sa'di",
    'ar': 'تفسير السعدي',
    'ckb': 'تەفسیری سەعدی',
    'ckb_Badini': 'تەفسیرا سەعدی',
  },
  381: {
    'en': 'Tafsir Fathul Majid',
    'ar': 'تفسير فتح المجيد',
    'ckb': 'تەفسیری فەتحول مەجید',
    'ckb_Badini': 'تەفسیرا فەتحول مەجید',
  },
  804: {
    'en': 'Rebar Kurdish Tafsir',
    'ar': 'تفسير ریبەر الكردي',
    'ckb': 'تەفسیری ڕێبەر',
    'ckb_Badini': 'تەفسیرا ڕێبەر',
  },
  817: {
    'en': "Tazkirul Qur'an (Wahiduddin Khan)",
    'ar': 'تذكير القرآن (وحيد الدين خان)',
    'ckb': 'تەزکیری قورئان (وەحیدودین خان)',
    'ckb_Badini': 'تەزکیرا قورئانێ (وەحیدودین خان)',
  },
  818: {
    'en': "Tazkir ul Qur'an",
    'ar': 'تذكير القرآن',
    'ckb': 'تەزکیری قورئان',
    'ckb_Badini': 'تەزکیرا قورئانێ',
  },
};

String localizedTafsirName(int id, String fallback, String langCode) {
  final t = _tafsirNames[id];
  if (t == null) return fallback;
  return t[langCode] ?? t['en'] ?? fallback;
}

Iterable<String> tafsirNameVariants(int id) =>
    _tafsirNames[id]?.values ?? const <String>[];
