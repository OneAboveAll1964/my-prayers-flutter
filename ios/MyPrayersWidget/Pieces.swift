import Foundation

struct ShortPiece {
    let arabic: String
    let translations: [String: String]
    let reference: String

    func translation(for lang: WidgetLanguage) -> String {
        switch lang {
        case .english: return translations["en"] ?? ""
        case .arabic:  return translations["ar"] ?? ""
        case .kurdish: return translations["ku"] ?? translations["en"] ?? ""
        }
    }
}

let shortAyahs: [ShortPiece] = [
    ShortPiece(
        arabic: "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
        translations: [
            "en": "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
            "ar": "بسم الله الرحمن الرحيم",
            "ku": "بە ناوی خوای بەخشندە و میهرەبان"
        ],
        reference: "Al-Fātiḥah 1:1"
    ),
    ShortPiece(
        arabic: "فَٱذْكُرُونِىٓ أَذْكُرْكُمْ",
        translations: [
            "en": "So remember Me; I will remember you.",
            "ar": "فاذكروني أذكركم",
            "ku": "یادم بکەن، یادتان دەکەم"
        ],
        reference: "Al-Baqarah 2:152"
    ),
    ShortPiece(
        arabic: "وَإِذَا سَأَلَكَ عِبَادِى عَنِّى فَإِنِّى قَرِيبٌ",
        translations: [
            "en": "When My servants ask you concerning Me — indeed I am near.",
            "ar": "وإذا سألك عبادي عني فإني قريب",
            "ku": "هەرکات بەندەکانم لێم پرسیار کرد، من نزیکم"
        ],
        reference: "Al-Baqarah 2:186"
    ),
    ShortPiece(
        arabic: "لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
        translations: [
            "en": "Allah does not charge a soul beyond its capacity.",
            "ar": "لا يكلف الله نفسا إلا وسعها",
            "ku": "خوا کەس ناخاتە سەر دەرەجەی توانستی"
        ],
        reference: "Al-Baqarah 2:286"
    ),
    ShortPiece(
        arabic: "أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ",
        translations: [
            "en": "Hearts find rest in the remembrance of Allah.",
            "ar": "ألا بذكر الله تطمئن القلوب",
            "ku": "تەنها بە یادی خوا دڵەکان ئارام دەگرن"
        ],
        reference: "Ar-Raʿd 13:28"
    ),
    ShortPiece(
        arabic: "وَٱلَّذِينَ جَاهَدُوا۟ فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا",
        translations: [
            "en": "Those who strive for Us — We will surely guide them to Our ways.",
            "ar": "والذين جاهدوا فينا لنهدينهم سبلنا",
            "ku": "ئەوانەی لە پێناوماندا تێدەکۆشن، ڕێگاکانمانیان پیشان دەدەین"
        ],
        reference: "Al-ʿAnkabūt 29:69"
    ),
    ShortPiece(
        arabic: "لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ",
        translations: [
            "en": "Do not despair of the mercy of Allah.",
            "ar": "لا تقنطوا من رحمة الله",
            "ku": "لە ڕەحمەتی خوا نائومێد مەبن"
        ],
        reference: "Az-Zumar 39:53"
    ),
    ShortPiece(
        arabic: "وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥٓ",
        translations: [
            "en": "Whoever relies upon Allah, He is sufficient for him.",
            "ar": "ومن يتوكل على الله فهو حسبه",
            "ku": "هەرکەس پشت بە خوا ببەستێت، خۆی بۆی بەسە"
        ],
        reference: "Aṭ-Ṭalāq 65:3"
    ),
    ShortPiece(
        arabic: "فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
        translations: [
            "en": "With every hardship comes ease.",
            "ar": "فإن مع العسر يسرا",
            "ku": "بێگومان لەگەڵ سەختی ئاسانی هەیە"
        ],
        reference: "Ash-Sharḥ 94:5"
    ),
    ShortPiece(
        arabic: "رَّبِّ زِدْنِى عِلْمًا",
        translations: [
            "en": "My Lord, increase me in knowledge.",
            "ar": "رب زدني علما",
            "ku": "پەروەردگارا، زانیاریم زیاد بکە"
        ],
        reference: "Ṭā Hā 20:114"
    ),
    ShortPiece(
        arabic: "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
        translations: [
            "en": "Indeed, with hardship will be ease.",
            "ar": "إن مع العسر يسرا",
            "ku": "بێگومان لەگەڵ سەختی ئاسانی هەیە"
        ],
        reference: "Ash-Sharḥ 94:6"
    ),
    ShortPiece(
        arabic: "تُعِزُّ مَن تَشَآءُ وَتُذِلُّ مَن تَشَآءُ",
        translations: [
            "en": "You honor whom You will and humble whom You will.",
            "ar": "تعز من تشاء وتذل من تشاء",
            "ku": "هەرکەسێ ویست بەرز دەکەیتەوە و هەرکەسێ ویست نزم"
        ],
        reference: "Āl ʿImrān 3:26"
    ),
    ShortPiece(
        arabic: "رَبَّنَآ ءَاتِنَا فِى ٱلدُّنْيَا حَسَنَةً وَفِى ٱلْـَٔاخِرَةِ حَسَنَةً",
        translations: [
            "en": "Our Lord, give us good in this world and good in the Hereafter.",
            "ar": "ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة",
            "ku": "پەروەردگارا، خێرمان بدەوە لە دونیا و لە قیامەت"
        ],
        reference: "Al-Baqarah 2:201"
    )
]

let shortAzkars: [ShortPiece] = [
    ShortPiece(
        arabic: "سُبْحَانَ ٱللَّهِ",
        translations: [
            "en": "Glory be to Allah.",
            "ar": "سبحان الله",
            "ku": "پاکی بۆ خوا"
        ],
        reference: "Tasbih"
    ),
    ShortPiece(
        arabic: "ٱلْحَمْدُ لِلَّهِ",
        translations: [
            "en": "All praise is due to Allah.",
            "ar": "الحمد لله",
            "ku": "سوپاس بۆ خوا"
        ],
        reference: "Tahmid"
    ),
    ShortPiece(
        arabic: "ٱللَّهُ أَكْبَرُ",
        translations: [
            "en": "Allah is the Greatest.",
            "ar": "الله أكبر",
            "ku": "خوا گەورەترە"
        ],
        reference: "Takbir"
    ),
    ShortPiece(
        arabic: "لَا إِلَٰهَ إِلَّا ٱللَّهُ",
        translations: [
            "en": "There is no god but Allah.",
            "ar": "لا إله إلا الله",
            "ku": "هیچ خوایێک نییە جگە لە خوا"
        ],
        reference: "Tahlil"
    ),
    ShortPiece(
        arabic: "أَسْتَغْفِرُ ٱللَّهَ",
        translations: [
            "en": "I seek the forgiveness of Allah.",
            "ar": "أستغفر الله",
            "ku": "لە خوا داوای لێبووردن دەکەم"
        ],
        reference: "Istighfar"
    ),
    ShortPiece(
        arabic: "حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ",
        translations: [
            "en": "Allah is sufficient for us; an excellent guardian.",
            "ar": "حسبنا الله ونعم الوكيل",
            "ku": "خوامان بەسە و باشترین پشتیوانە"
        ],
        reference: "Āl ʿImrān 3:173"
    ),
    ShortPiece(
        arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّهِ",
        translations: [
            "en": "No power except with Allah.",
            "ar": "لا حول ولا قوة إلا بالله",
            "ku": "هیچ گۆڕان و هێزێک نییە جگە بە خوا"
        ],
        reference: "Hawqala"
    ),
    ShortPiece(
        arabic: "إِنَّ ٱللَّهَ مَعَ ٱلصَّابِرِينَ",
        translations: [
            "en": "Indeed Allah is with the patient.",
            "ar": "إن الله مع الصابرين",
            "ku": "بێگومان خوا لەگەڵ ئارامگیرانە"
        ],
        reference: "Al-Baqarah 2:153"
    ),
    ShortPiece(
        arabic: "بِسْمِ ٱللَّهِ ٱلَّذِى لَا يَضُرُّ مَعَ ٱسْمِهِۦ شَىْءٌ",
        translations: [
            "en": "In the name of Allah, with whose name nothing can harm.",
            "ar": "بسم الله الذي لا يضر مع اسمه شيء",
            "ku": "بە ناوی خوا، کە هیچ شت بە ناوی ئەو زیانی نییە"
        ],
        reference: "Hisnul Muslim"
    )
]

func pickPiece(seed: Date, type: WidgetContentType) -> ShortPiece {
    let pool: [ShortPiece]
    switch type {
    case .ayah:  pool = shortAyahs
    case .azkar: pool = shortAzkars
    case .mix:   pool = shortAyahs + shortAzkars
    }
    let comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: seed)
    let y = comps.year ?? 0
    let m = comps.month ?? 0
    let d = comps.day ?? 0
    let h = comps.hour ?? 0
    let stable = (y * 1_000_000) + (m * 10_000) + (d * 100) + h
    return pool[abs(stable) % pool.count]
}
