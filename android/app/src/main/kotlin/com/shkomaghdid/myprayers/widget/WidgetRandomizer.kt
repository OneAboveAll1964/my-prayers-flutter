package com.shkomaghdid.myprayers.widget

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin

object WidgetRandomizer {
    private val ayahs = listOf(
        Triple("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
            "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
            "Al-Fātiḥah 1:1"),
        Triple("فَٱذْكُرُونِىٓ أَذْكُرْكُمْ",
            "So remember Me; I will remember you.", "Al-Baqarah 2:152"),
        Triple("لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
            "Allah does not charge a soul except [with that within] its capacity.",
            "Al-Baqarah 2:286"),
        Triple("أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ",
            "Unquestionably, by the remembrance of Allah hearts are assured.",
            "Ar-Raʿd 13:28"),
        Triple("لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ",
            "Do not despair of the mercy of Allah.", "Az-Zumar 39:53"),
        Triple("وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥٓ",
            "And whoever relies upon Allah — then He is sufficient for him.",
            "Aṭ-Ṭalāq 65:3"),
        Triple("فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
            "For indeed, with hardship will be ease.", "Ash-Sharḥ 94:5"),
        Triple("رَّبِّ زِدْنِى عِلْمًا",
            "My Lord, increase me in knowledge.", "Ṭā Hā 20:114"),
    )
    private val azkars = listOf(
        Triple("سُبْحَانَ ٱللَّهِ", "Glory be to Allah.", "Tasbih"),
        Triple("ٱلْحَمْدُ لِلَّهِ", "All praise is due to Allah.", "Tahmid"),
        Triple("ٱللَّهُ أَكْبَرُ", "Allah is the Greatest.", "Takbir"),
        Triple("لَا إِلَٰهَ إِلَّا ٱللَّهُ", "There is no god but Allah.", "Tahlil"),
        Triple("أَسْتَغْفِرُ ٱللَّهَ", "I seek the forgiveness of Allah.", "Istighfar"),
        Triple("حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ",
            "Allah is sufficient for us, and He is the best Disposer of affairs.",
            "Āl ʿImrān 3:173"),
        Triple("لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّهِ",
            "There is no might nor power except with Allah.", "Hawqala"),
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
            putString("widget.${widgetId}.arabic", pick.first)
            putString("widget.${widgetId}.translation", pick.second)
            putString("widget.${widgetId}.reference", pick.third)
            putString("arabic", pick.first)
            putString("translation", pick.second)
            putString("reference", pick.third)
            apply()
        }
    }
}
