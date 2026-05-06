class ShortPiece {
  const ShortPiece({
    required this.id,
    required this.arabic,
    required this.en,
    required this.ar,
    required this.ku,
    required this.reference,
  });

  final String id;
  final String arabic;
  final String en;
  final String ar;
  final String ku;
  final String reference;

  String translationFor(String code) {
    if (code == 'ar') return ar;
    if (code == 'ckb' || code == 'ckb_Badini') return ku;
    return en;
  }
}

const shortAyahs = <ShortPiece>[
  ShortPiece(
    id: 'a-fatiha-1',
    arabic: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
    en: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
    ar: 'بسم الله الرحمن الرحيم',
    ku: 'بە ناوی خوای بەخشندە و میهرەبان',
    reference: 'Al-Fātiḥah 1:1',
  ),
  ShortPiece(
    id: 'a-2-152',
    arabic: 'فَٱذْكُرُونِىٓ أَذْكُرْكُمْ',
    en: 'So remember Me; I will remember you.',
    ar: 'فاذكروني أذكركم',
    ku: 'یادم بکەن، یادتان دەکەم',
    reference: 'Al-Baqarah 2:152',
  ),
  ShortPiece(
    id: 'a-2-186',
    arabic: 'وَإِذَا سَأَلَكَ عِبَادِى عَنِّى فَإِنِّى قَرِيبٌ',
    en: 'And when My servants ask you, [O Muhammad], concerning Me — indeed I am near.',
    ar: 'وإذا سألك عبادي عني فإني قريب',
    ku: 'هەرکات بەندەکانم لێم پرسیار کرد، من نزیکم',
    reference: 'Al-Baqarah 2:186',
  ),
  ShortPiece(
    id: 'a-2-286',
    arabic: 'لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
    en: 'Allah does not charge a soul except [with that within] its capacity.',
    ar: 'لا يكلف الله نفسا إلا وسعها',
    ku: 'خوا کەس ناخاتە سەر دەرەجەی توانستی',
    reference: 'Al-Baqarah 2:286',
  ),
  ShortPiece(
    id: 'a-3-26',
    arabic: 'تُعِزُّ مَن تَشَآءُ وَتُذِلُّ مَن تَشَآءُ ۖ بِيَدِكَ ٱلْخَيْرُ',
    en: 'You honor whom You will and You humble whom You will. In Your hand is [all] good.',
    ar: 'تعز من تشاء وتذل من تشاء بيدك الخير',
    ku: 'هەرکەسێ ویست بەرز دەکەیتەوە و هەرکەسێ ویست نزم دەکەیتەوە، خێر بە دەستی تۆیە',
    reference: 'Āl ʿImrān 3:26',
  ),
  ShortPiece(
    id: 'a-13-28',
    arabic: 'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
    en: 'Unquestionably, by the remembrance of Allah hearts are assured.',
    ar: 'ألا بذكر الله تطمئن القلوب',
    ku: 'ئاگاداربن، تەنها بە یادی خوا دڵەکان ئارام دەگرن',
    reference: 'Ar-Raʿd 13:28',
  ),
  ShortPiece(
    id: 'a-29-69',
    arabic: 'وَٱلَّذِينَ جَاهَدُوا۟ فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا',
    en: 'And those who strive for Us — We will surely guide them to Our ways.',
    ar: 'والذين جاهدوا فينا لنهدينهم سبلنا',
    ku: 'ئەوانەی لە پێناوی ئێمەدا تێدەکۆشن، بێگومان ڕێگاکانمانیان پیشان دەدەین',
    reference: 'Al-ʿAnkabūt 29:69',
  ),
  ShortPiece(
    id: 'a-39-53',
    arabic: 'لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ',
    en: 'Do not despair of the mercy of Allah.',
    ar: 'لا تقنطوا من رحمة الله',
    ku: 'لە ڕەحمەتی خوا نائومێد مەبن',
    reference: 'Az-Zumar 39:53',
  ),
  ShortPiece(
    id: 'a-65-3',
    arabic: 'وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥٓ',
    en: 'And whoever relies upon Allah — then He is sufficient for him.',
    ar: 'ومن يتوكل على الله فهو حسبه',
    ku: 'هەرکەس پشت بە خوا ببەستێت، خۆی بۆی بەسە',
    reference: 'Aṭ-Ṭalāq 65:3',
  ),
  ShortPiece(
    id: 'a-94-5-6',
    arabic: 'فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا * إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا',
    en: 'For indeed, with hardship will be ease. Indeed, with hardship will be ease.',
    ar: 'فإن مع العسر يسرا، إن مع العسر يسرا',
    ku: 'بێگومان لەگەڵ سەختی، ئاسانی هەیە',
    reference: 'Ash-Sharḥ 94:5-6',
  ),
  ShortPiece(
    id: 'a-103-1-3',
    arabic:
        'وَٱلْعَصْرِ * إِنَّ ٱلْإِنسَـٰنَ لَفِى خُسْرٍ * إِلَّا ٱلَّذِينَ ءَامَنُوا۟ وَعَمِلُوا۟ ٱلصَّـٰلِحَـٰتِ',
    en: 'By time, indeed, mankind is in loss, except for those who have believed and done righteous deeds.',
    ar: 'والعصر، إن الإنسان لفي خسر، إلا الذين آمنوا وعملوا الصالحات',
    ku: 'سوێند بە کات، بێگومان مرۆڤ لە زیاندایە، جگە لەوانەی باوەڕیان هێناوە و کاری چاکیان کردووە',
    reference: 'Al-ʿAṣr 103:1-3',
  ),
  ShortPiece(
    id: 'a-112-1-4',
    arabic:
        'قُلْ هُوَ ٱللَّهُ أَحَدٌ * ٱللَّهُ ٱلصَّمَدُ * لَمْ يَلِدْ وَلَمْ يُولَدْ * وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ',
    en: 'Say, "He is Allah, [who is] One. Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent."',
    ar: 'قل هو الله أحد، الله الصمد، لم يلد ولم يولد، ولم يكن له كفوا أحد',
    ku: 'بڵێ: ئەو خوایە یەکێکە، خوایەکە کە هەموو شت پێویستی پێیەتی، نە منداڵی بووە و نە منداڵە، و نە کەس هاوتای ئەوە',
    reference: 'Al-Ikhlāṣ 112',
  ),
  ShortPiece(
    id: 'a-2-201',
    arabic:
        'رَبَّنَآ ءَاتِنَا فِى ٱلدُّنْيَا حَسَنَةً وَفِى ٱلْـَٔاخِرَةِ حَسَنَةً وَقِنَا عَذَابَ ٱلنَّارِ',
    en: 'Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.',
    ar: 'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار',
    ku: 'پەروەردگارا، خێرمان بدەوە لە دونیا و لە قیامەت، و لە سزای ئاگر بمانپارێزە',
    reference: 'Al-Baqarah 2:201',
  ),
  ShortPiece(
    id: 'a-20-114',
    arabic: 'رَّبِّ زِدْنِى عِلْمًا',
    en: 'My Lord, increase me in knowledge.',
    ar: 'رب زدني علما',
    ku: 'پەروەردگارا، زانیاریم زیاد بکە',
    reference: 'Ṭā Hā 20:114',
  ),
  ShortPiece(
    id: 'a-3-8',
    arabic: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا',
    en: 'Our Lord, let not our hearts deviate after You have guided us.',
    ar: 'ربنا لا تزغ قلوبنا بعد إذ هديتنا',
    ku: 'پەروەردگارا، دڵەکانمان لاناجێ مەکە دوای ئەوەی ڕێنماییت کردووین',
    reference: 'Āl ʿImrān 3:8',
  ),
];

const shortAzkars = <ShortPiece>[
  ShortPiece(
    id: 'd-tasbih',
    arabic: 'سُبْحَانَ ٱللَّهِ',
    en: 'Glory be to Allah.',
    ar: 'سبحان الله',
    ku: 'پاکی بۆ خوا',
    reference: 'Tasbih',
  ),
  ShortPiece(
    id: 'd-hamd',
    arabic: 'ٱلْحَمْدُ لِلَّهِ',
    en: 'All praise is due to Allah.',
    ar: 'الحمد لله',
    ku: 'سوپاس بۆ خوا',
    reference: 'Tahmid',
  ),
  ShortPiece(
    id: 'd-takbir',
    arabic: 'ٱللَّهُ أَكْبَرُ',
    en: 'Allah is the Greatest.',
    ar: 'الله أكبر',
    ku: 'خوا گەورەترە',
    reference: 'Takbir',
  ),
  ShortPiece(
    id: 'd-tahlil',
    arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّهُ',
    en: 'There is no god but Allah.',
    ar: 'لا إله إلا الله',
    ku: 'هیچ خوایێک نییە جگە لە خوا',
    reference: 'Tahlil',
  ),
  ShortPiece(
    id: 'd-istighfar',
    arabic: 'أَسْتَغْفِرُ ٱللَّهَ',
    en: 'I seek the forgiveness of Allah.',
    ar: 'أستغفر الله',
    ku: 'لە خوا داوای لێبووردن دەکەم',
    reference: 'Istighfar',
  ),
  ShortPiece(
    id: 'd-hasbi',
    arabic: 'حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ',
    en: 'Allah is sufficient for us, and He is the best Disposer of affairs.',
    ar: 'حسبنا الله ونعم الوكيل',
    ku: 'خوامان بەسە و باشترین پشتیوانە',
    reference: 'Āl ʿImrān 3:173',
  ),
  ShortPiece(
    id: 'd-quwwah',
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّهِ',
    en: 'There is no might nor power except with Allah.',
    ar: 'لا حول ولا قوة إلا بالله',
    ku: 'هیچ گۆڕان و هێزێک نییە جگە بە خوا',
    reference: 'Hawqala',
  ),
  ShortPiece(
    id: 'd-bismillah',
    arabic: 'بِٱسْمِ ٱللَّهِ',
    en: 'In the name of Allah.',
    ar: 'بسم الله',
    ku: 'بە ناوی خوا',
    reference: 'Bismillah',
  ),
  ShortPiece(
    id: 'd-ali-imran-173',
    arabic: 'إِنَّ ٱللَّهَ مَعَ ٱلصَّابِرِينَ',
    en: 'Indeed Allah is with the patient.',
    ar: 'إن الله مع الصابرين',
    ku: 'بێگومان خوا لەگەڵ ئارامگیرانە',
    reference: 'Al-Baqarah 2:153',
  ),
  ShortPiece(
    id: 'd-shukr',
    arabic: 'سُبْحَانَ ٱللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ ٱللَّهِ ٱلْعَظِيمِ',
    en: 'Glory be to Allah and praise Him; glory be to Allah the Magnificent.',
    ar: 'سبحان الله وبحمده، سبحان الله العظيم',
    ku: 'پاکی بۆ خوا و سوپاس بۆ ئەو، پاکی بۆ خوای گەورە',
    reference: 'Bukhari, Muslim',
  ),
];

const shortPieceTypes = ['ayah', 'azkar', 'mix'];
