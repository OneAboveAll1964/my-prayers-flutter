package com.shkomaghdid.myprayers.widget

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin

object WidgetRandomizer {

    data class Piece(
        val arabic: String,
        val en: String,
        val ar: String,
        val ku: String,
        val reference: String
    )

    private val ayahs = listOf(
        Piece(
            arabic = "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
            en = "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
            ar = "بسم الله الرحمن الرحيم",
            ku = "بە ناوی خوای بەخشندە و میهرەبان",
            reference = "Al-Fātiḥah 1:1"
        ),
        Piece(
            arabic = "فَٱذْكُرُونِىٓ أَذْكُرْكُمْ",
            en = "So remember Me; I will remember you.",
            ar = "فاذكروني أذكركم",
            ku = "یادم بکەن، یادتان دەکەم",
            reference = "Al-Baqarah 2:152"
        ),
        Piece(
            arabic = "لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
            en = "Allah does not charge a soul except [with that within] its capacity.",
            ar = "لا يكلف الله نفسا إلا وسعها",
            ku = "خوا کەس ناخاتە سەر دەرەجەی توانستی",
            reference = "Al-Baqarah 2:286"
        ),
        Piece(
            arabic = "أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ",
            en = "Unquestionably, by the remembrance of Allah hearts are assured.",
            ar = "ألا بذكر الله تطمئن القلوب",
            ku = "تەنها بە یادی خوا دڵەکان ئارام دەگرن",
            reference = "Ar-Raʿd 13:28"
        ),
        Piece(
            arabic = "لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ",
            en = "Do not despair of the mercy of Allah.",
            ar = "لا تقنطوا من رحمة الله",
            ku = "لە ڕەحمەتی خوا نائومێد مەبن",
            reference = "Az-Zumar 39:53"
        ),
        Piece(
            arabic = "وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥٓ",
            en = "And whoever relies upon Allah — then He is sufficient for him.",
            ar = "ومن يتوكل على الله فهو حسبه",
            ku = "هەرکەس پشت بە خوا ببەستێت، خۆی بۆی بەسە",
            reference = "Aṭ-Ṭalāq 65:3"
        ),
        Piece(
            arabic = "فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
            en = "For indeed, with hardship will be ease.",
            ar = "فإن مع العسر يسرا",
            ku = "بێگومان لەگەڵ سەختی ئاسانی هەیە",
            reference = "Ash-Sharḥ 94:5"
        ),
        Piece(
            arabic = "رَّبِّ زِدْنِى عِلْمًا",
            en = "My Lord, increase me in knowledge.",
            ar = "رب زدني علما",
            ku = "پەروەردگارا، زانیاریم زیاد بکە",
            reference = "Ṭā Hā 20:114"
        ),
        Piece(
            arabic = "وَإِذَا سَأَلَكَ عِبَادِى عَنِّى فَإِنِّى قَرِيبٌ",
            en = "When My servants ask you concerning Me — indeed I am near.",
            ar = "وإذا سألك عبادي عني فإني قريب",
            ku = "هەرکات بەندەکانم لێم پرسیار کرد، من نزیکم",
            reference = "Al-Baqarah 2:186"
        ),
        Piece(
            arabic = "إِنَّ ٱللَّهَ مَعَ ٱلصَّابِرِينَ",
            en = "Indeed Allah is with the patient.",
            ar = "إن الله مع الصابرين",
            ku = "بێگومان خوا لەگەڵ ئارامگیرانە",
            reference = "Al-Baqarah 2:153"
        ),
        Piece(
            arabic = "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
            en = "You alone we worship, and You alone we ask for help.",
            ar = "إياك نعبد وإياك نستعين",
            ku = "تەنها تۆ دەپەرستین و تەنها لە تۆ یارمەتی دەخوازین",
            reference = "Al-Fātiḥah 1:5"
        ),
        Piece(
            arabic = "تُعِزُّ مَن تَشَآءُ وَتُذِلُّ مَن تَشَآءُ",
            en = "You honor whom You will and humble whom You will.",
            ar = "تعز من تشاء وتذل من تشاء",
            ku = "هەرکەسێ ویست بەرز دەکەیتەوە و هەرکەسێ ویست نزم",
            reference = "Āl ʿImrān 3:26"
        ),
        Piece(
            arabic = "وَكَفَىٰ بِٱللَّهِ وَكِيلًا",
            en = "And Allah is sufficient as a Disposer of affairs.",
            ar = "وكفى بالله وكيلا",
            ku = "خوا بەسە وەک پشتیوان",
            reference = "An-Nisā' 4:81"
        ),
        Piece(
            arabic = "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
            en = "Indeed, with hardship will be ease.",
            ar = "إن مع العسر يسرا",
            ku = "بێگومان لەگەڵ سەختی ئاسانی هەیە",
            reference = "Ash-Sharḥ 94:6"
        ),
        Piece(
            arabic = "وَلَذِكْرُ ٱللَّهِ أَكْبَرُ",
            en = "And the remembrance of Allah is greater.",
            ar = "ولذكر الله أكبر",
            ku = "یادی خوا گەورەترە",
            reference = "Al-ʿAnkabūt 29:45"
        ),
        Piece(
            arabic = "حَسْبِىَ ٱللَّهُ",
            en = "Allah is sufficient for me.",
            ar = "حسبي الله",
            ku = "خوام بەسە",
            reference = "At-Tawbah 9:129"
        ),
        Piece(
            arabic = "رَبَّنَآ ءَاتِنَا فِى ٱلدُّنْيَا حَسَنَةً",
            en = "Our Lord, give us good in this world.",
            ar = "ربنا آتنا في الدنيا حسنة",
            ku = "پەروەردگارا، خێرمان بدەوە لە دونیا",
            reference = "Al-Baqarah 2:201"
        ),
        Piece(
            arabic = "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ",
            en = "And He is with you wherever you are.",
            ar = "وهو معكم أين ما كنتم",
            ku = "ئەو لەگەڵتانە لە هەرکوێی بن",
            reference = "Al-Ḥadīd 57:4"
        ),
        Piece(
            arabic = "إِنَّ ٱللَّهَ غَفُورٌ رَّحِيمٌ",
            en = "Indeed Allah is Forgiving, Merciful.",
            ar = "إن الله غفور رحيم",
            ku = "بێگومان خوا لێبووردە و میهرەبانە",
            reference = "Al-Baqarah 2:173"
        ),
        Piece(
            arabic = "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ",
            en = "All praise is for Allah — Lord of all worlds.",
            ar = "الحمد لله رب العالمين",
            ku = "سوپاس بۆ خوای جیهانان",
            reference = "Al-Fātiḥah 1:2"
        )
    )

    private val azkars = listOf(
        Piece(
            arabic = "سُبْحَانَ ٱللَّهِ",
            en = "Glory be to Allah.",
            ar = "سبحان الله",
            ku = "پاکی بۆ خوا",
            reference = "Tasbih"
        ),
        Piece(
            arabic = "ٱلْحَمْدُ لِلَّهِ",
            en = "All praise is due to Allah.",
            ar = "الحمد لله",
            ku = "سوپاس بۆ خوا",
            reference = "Tahmid"
        ),
        Piece(
            arabic = "ٱللَّهُ أَكْبَرُ",
            en = "Allah is the Greatest.",
            ar = "الله أكبر",
            ku = "خوا گەورەترە",
            reference = "Takbir"
        ),
        Piece(
            arabic = "لَا إِلَٰهَ إِلَّا ٱللَّهُ",
            en = "There is no god but Allah.",
            ar = "لا إله إلا الله",
            ku = "هیچ خوایێک نییە جگە لە خوا",
            reference = "Tahlil"
        ),
        Piece(
            arabic = "أَسْتَغْفِرُ ٱللَّهَ",
            en = "I seek the forgiveness of Allah.",
            ar = "أستغفر الله",
            ku = "لە خوا داوای لێبووردن دەکەم",
            reference = "Istighfar"
        ),
        Piece(
            arabic = "حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ",
            en = "Allah is sufficient for us, and He is the best Disposer of affairs.",
            ar = "حسبنا الله ونعم الوكيل",
            ku = "خوامان بەسە و باشترین پشتیوانە",
            reference = "Āl ʿImrān 3:173"
        ),
        Piece(
            arabic = "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّهِ",
            en = "There is no might nor power except with Allah.",
            ar = "لا حول ولا قوة إلا بالله",
            ku = "هیچ گۆڕان و هێزێک نییە جگە بە خوا",
            reference = "Hawqala"
        )
    )

    fun rotate(context: Context, widgetId: Int) {
        val prefs = HomeWidgetPlugin.getData(context)
        val type = prefs.getString("widget.${widgetId}.type", "mix")
        val pool = when (type) {
            "ayah" -> ayahs
            "azkar" -> azkars
            else -> ayahs + azkars
        }
        val pick = pool.random()
        prefs.edit().apply {
            putString("widget.${widgetId}.arabic", pick.arabic)
            putString("widget.${widgetId}.translation_en", pick.en)
            putString("widget.${widgetId}.translation_ar", pick.ar)
            putString("widget.${widgetId}.translation_ku", pick.ku)
            putString("widget.${widgetId}.reference", pick.reference)
            putString("arabic", pick.arabic)
            putString("translation_en", pick.en)
            putString("translation_ar", pick.ar)
            putString("translation_ku", pick.ku)
            putString("reference", pick.reference)
            apply()
        }
    }
}
