import WidgetKit
import SwiftUI

struct ShortPiece {
    let arabic: String
    let translation: [String: String]
    let reference: String
}

let shortAyahs: [ShortPiece] = [
    ShortPiece(
        arabic: "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
        translation: [
            "en": "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
            "ar": "بسم الله الرحمن الرحيم",
            "ku": "بە ناوی خوای بەخشندە و میهرەبان"
        ],
        reference: "Al-Fātiḥah 1:1"
    ),
    ShortPiece(
        arabic: "فَٱذْكُرُونِىٓ أَذْكُرْكُمْ",
        translation: [
            "en": "So remember Me; I will remember you.",
            "ar": "فاذكروني أذكركم",
            "ku": "یادم بکەن، یادتان دەکەم"
        ],
        reference: "Al-Baqarah 2:152"
    ),
    ShortPiece(
        arabic: "لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
        translation: [
            "en": "Allah does not charge a soul except [with that within] its capacity.",
            "ar": "لا يكلف الله نفسا إلا وسعها",
            "ku": "خوا کەس ناخاتە سەر دەرەجەی توانستی"
        ],
        reference: "Al-Baqarah 2:286"
    ),
    ShortPiece(
        arabic: "أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ",
        translation: [
            "en": "Unquestionably, by the remembrance of Allah hearts are assured.",
            "ar": "ألا بذكر الله تطمئن القلوب",
            "ku": "ئاگاداربن، تەنها بە یادی خوا دڵەکان ئارام دەگرن"
        ],
        reference: "Ar-Raʿd 13:28"
    ),
    ShortPiece(
        arabic: "لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ",
        translation: [
            "en": "Do not despair of the mercy of Allah.",
            "ar": "لا تقنطوا من رحمة الله",
            "ku": "لە ڕەحمەتی خوا نائومێد مەبن"
        ],
        reference: "Az-Zumar 39:53"
    ),
    ShortPiece(
        arabic: "وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥٓ",
        translation: [
            "en": "And whoever relies upon Allah — then He is sufficient for him.",
            "ar": "ومن يتوكل على الله فهو حسبه",
            "ku": "هەرکەس پشت بە خوا ببەستێت، خۆی بۆی بەسە"
        ],
        reference: "Aṭ-Ṭalāq 65:3"
    ),
    ShortPiece(
        arabic: "فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
        translation: [
            "en": "For indeed, with hardship will be ease.",
            "ar": "فإن مع العسر يسرا",
            "ku": "بێگومان لەگەڵ سەختی، ئاسانی هەیە"
        ],
        reference: "Ash-Sharḥ 94:5"
    ),
    ShortPiece(
        arabic: "رَّبِّ زِدْنِى عِلْمًا",
        translation: [
            "en": "My Lord, increase me in knowledge.",
            "ar": "رب زدني علما",
            "ku": "پەروەردگارا، زانیاریم زیاد بکە"
        ],
        reference: "Ṭā Hā 20:114"
    )
]

let shortAzkars: [ShortPiece] = [
    ShortPiece(
        arabic: "سُبْحَانَ ٱللَّهِ",
        translation: ["en": "Glory be to Allah.", "ar": "سبحان الله", "ku": "پاکی بۆ خوا"],
        reference: "Tasbih"
    ),
    ShortPiece(
        arabic: "ٱلْحَمْدُ لِلَّهِ",
        translation: ["en": "All praise is due to Allah.", "ar": "الحمد لله", "ku": "سوپاس بۆ خوا"],
        reference: "Tahmid"
    ),
    ShortPiece(
        arabic: "ٱللَّهُ أَكْبَرُ",
        translation: ["en": "Allah is the Greatest.", "ar": "الله أكبر", "ku": "خوا گەورەترە"],
        reference: "Takbir"
    ),
    ShortPiece(
        arabic: "لَا إِلَٰهَ إِلَّا ٱللَّهُ",
        translation: ["en": "There is no god but Allah.", "ar": "لا إله إلا الله", "ku": "هیچ خوایێک نییە جگە لە خوا"],
        reference: "Tahlil"
    ),
    ShortPiece(
        arabic: "أَسْتَغْفِرُ ٱللَّهَ",
        translation: ["en": "I seek the forgiveness of Allah.", "ar": "أستغفر الله", "ku": "لە خوا داوای لێبووردن دەکەم"],
        reference: "Istighfar"
    ),
    ShortPiece(
        arabic: "حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ",
        translation: [
            "en": "Allah is sufficient for us, and He is the best Disposer of affairs.",
            "ar": "حسبنا الله ونعم الوكيل",
            "ku": "خوامان بەسە و باشترین پشتیوانە"
        ],
        reference: "Āl ʿImrān 3:173"
    ),
    ShortPiece(
        arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّهِ",
        translation: [
            "en": "There is no might nor power except with Allah.",
            "ar": "لا حول ولا قوة إلا بالله",
            "ku": "هیچ گۆڕان و هێزێک نییە جگە بە خوا"
        ],
        reference: "Hawqala"
    )
]

struct PrayersEntry: TimelineEntry {
    let date: Date
    let arabic: String
    let translation: String
    let reference: String
    let langCode: String
    let theme: String
    let textSize: String
    let showTranslation: Bool
}

struct PrayersConfigurationProvider: AppIntentTimelineProvider {
    typealias Entry = PrayersEntry
    typealias Intent = PrayersWidgetConfigurationIntent

    let appGroup = "group.com.shkomaghdid.myprayers"

    func placeholder(in context: Context) -> PrayersEntry {
        return makeEntry(piece: shortAyahs[0], lang: "en", theme: "auto", size: "m", showTr: true)
    }

    func snapshot(for configuration: PrayersWidgetConfigurationIntent,
                  in context: Context) async -> PrayersEntry {
        return makeEntry(
            piece: pickPiece(type: configuration.contentType),
            lang: configuration.language,
            theme: configuration.theme,
            size: configuration.textSize,
            showTr: configuration.showTranslation
        )
    }

    func timeline(for configuration: PrayersWidgetConfigurationIntent,
                  in context: Context) async -> Timeline<PrayersEntry> {
        let now = Date()
        let entry = makeEntry(
            piece: pickPiece(type: configuration.contentType),
            lang: configuration.language,
            theme: configuration.theme,
            size: configuration.textSize,
            showTr: configuration.showTranslation
        )
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func pickPiece(type: String) -> ShortPiece {
        let pool: [ShortPiece] = {
            switch type {
            case "ayah": return shortAyahs
            case "azkar": return shortAzkars
            default: return shortAyahs + shortAzkars
            }
        }()
        if let stored = readStoredPick() { return stored }
        return pool.randomElement() ?? shortAyahs[0]
    }

    private func readStoredPick() -> ShortPiece? {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return nil }
        guard let arabic = defaults.string(forKey: "arabic") else { return nil }
        let ref = defaults.string(forKey: "reference") ?? ""
        let translations: [String: String] = [
            "en": defaults.string(forKey: "translation_en") ?? defaults.string(forKey: "translation") ?? "",
            "ar": defaults.string(forKey: "translation_ar") ?? "",
            "ku": defaults.string(forKey: "translation_ku") ?? ""
        ]
        return ShortPiece(arabic: arabic, translation: translations, reference: ref)
    }

    private func makeEntry(piece: ShortPiece, lang: String, theme: String,
                           size: String, showTr: Bool) -> PrayersEntry {
        let key = (lang == "ckb" || lang == "ckb_Badini") ? "ku" : lang
        let tr = piece.translation[key] ?? piece.translation["en"] ?? ""
        return PrayersEntry(
            date: Date(),
            arabic: piece.arabic,
            translation: tr,
            reference: piece.reference,
            langCode: lang,
            theme: theme,
            textSize: size,
            showTranslation: showTr
        )
    }
}

struct PrayersWidgetView: View {
    let entry: PrayersEntry
    @Environment(\.colorScheme) var systemScheme

    var resolvedScheme: ColorScheme {
        switch entry.theme {
        case "light": return .light
        case "dark": return .dark
        default: return systemScheme
        }
    }

    var textColor: Color {
        resolvedScheme == .dark
            ? Color(red: 241/255, green: 243/255, blue: 245/255)
            : Color(red: 21/255, green: 23/255, blue: 26/255)
    }

    var mutedColor: Color {
        resolvedScheme == .dark
            ? Color(red: 182/255, green: 187/255, blue: 194/255)
            : Color(red: 90/255, green: 95/255, blue: 102/255)
    }

    var subtleColor: Color {
        resolvedScheme == .dark
            ? Color(red: 138/255, green: 143/255, blue: 150/255)
            : Color(red: 137/255, green: 142/255, blue: 149/255)
    }

    var arabicSize: CGFloat {
        switch entry.textSize {
        case "s": return 16
        case "l": return 24
        default: return 20
        }
    }

    var translationSize: CGFloat {
        switch entry.textSize {
        case "s": return 11
        case "l": return 14
        default: return 12.5
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.arabic)
                .font(.custom("AmiriQuran", size: arabicSize))
                .foregroundColor(textColor)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .environment(\.layoutDirection, .rightToLeft)
            if entry.showTranslation && !entry.translation.isEmpty {
                Text(entry.translation)
                    .font(.system(size: translationSize, weight: .regular))
                    .foregroundColor(mutedColor)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            Spacer(minLength: 4)
            if !entry.reference.isEmpty {
                Text(entry.reference)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(subtleColor)
                    .italic()
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct MyPrayersWidget: Widget {
    let kind: String = "MyPrayersWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: PrayersWidgetConfigurationIntent.self,
            provider: PrayersConfigurationProvider()
        ) { entry in
            PrayersWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("My Prayers")
        .description("Ayah or azkar of the day, transparent style.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct MyPrayersWidgetBundle: WidgetBundle {
    var body: some Widget {
        MyPrayersWidget()
    }
}
