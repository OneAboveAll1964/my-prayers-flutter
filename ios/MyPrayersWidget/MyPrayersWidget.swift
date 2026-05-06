import WidgetKit
import SwiftUI

struct ShortPiece {
    let arabic: String
    let translation: String
    let reference: String
}

let pieces: [ShortPiece] = [
    ShortPiece(
        arabic: "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
        translation: "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
        reference: "Al-Fātiḥah 1:1"
    ),
    ShortPiece(
        arabic: "فَٱذْكُرُونِىٓ أَذْكُرْكُمْ",
        translation: "So remember Me; I will remember you.",
        reference: "Al-Baqarah 2:152"
    ),
    ShortPiece(
        arabic: "وَإِذَا سَأَلَكَ عِبَادِى عَنِّى فَإِنِّى قَرِيبٌ",
        translation: "And when My servants ask you concerning Me — indeed I am near.",
        reference: "Al-Baqarah 2:186"
    ),
    ShortPiece(
        arabic: "لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
        translation: "Allah does not charge a soul except [with that within] its capacity.",
        reference: "Al-Baqarah 2:286"
    ),
    ShortPiece(
        arabic: "أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ",
        translation: "Unquestionably, by the remembrance of Allah hearts are assured.",
        reference: "Ar-Raʿd 13:28"
    ),
    ShortPiece(
        arabic: "وَٱلَّذِينَ جَاهَدُوا۟ فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا",
        translation: "And those who strive for Us — We will surely guide them to Our ways.",
        reference: "Al-ʿAnkabūt 29:69"
    ),
    ShortPiece(
        arabic: "لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ",
        translation: "Do not despair of the mercy of Allah.",
        reference: "Az-Zumar 39:53"
    ),
    ShortPiece(
        arabic: "وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥٓ",
        translation: "And whoever relies upon Allah — then He is sufficient for him.",
        reference: "Aṭ-Ṭalāq 65:3"
    ),
    ShortPiece(
        arabic: "فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
        translation: "For indeed, with hardship will be ease.",
        reference: "Ash-Sharḥ 94:5"
    ),
    ShortPiece(
        arabic: "رَّبِّ زِدْنِى عِلْمًا",
        translation: "My Lord, increase me in knowledge.",
        reference: "Ṭā Hā 20:114"
    ),
    ShortPiece(
        arabic: "سُبْحَانَ ٱللَّهِ",
        translation: "Glory be to Allah.",
        reference: "Tasbih"
    ),
    ShortPiece(
        arabic: "ٱلْحَمْدُ لِلَّهِ",
        translation: "All praise is due to Allah.",
        reference: "Tahmid"
    ),
    ShortPiece(
        arabic: "ٱللَّهُ أَكْبَرُ",
        translation: "Allah is the Greatest.",
        reference: "Takbir"
    ),
    ShortPiece(
        arabic: "لَا إِلَٰهَ إِلَّا ٱللَّهُ",
        translation: "There is no god but Allah.",
        reference: "Tahlil"
    ),
    ShortPiece(
        arabic: "أَسْتَغْفِرُ ٱللَّهَ",
        translation: "I seek the forgiveness of Allah.",
        reference: "Istighfar"
    ),
    ShortPiece(
        arabic: "حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ",
        translation: "Allah is sufficient for us, and He is the best Disposer of affairs.",
        reference: "Āl ʿImrān 3:173"
    ),
    ShortPiece(
        arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّهِ",
        translation: "There is no might nor power except with Allah.",
        reference: "Hawqala"
    )
]

func pickPiece(seed: Date) -> ShortPiece {
    let cal = Calendar.current
    let comps = cal.dateComponents([.year, .month, .day, .hour], from: seed)
    let year = comps.year ?? 0
    let month = comps.month ?? 0
    let day = comps.day ?? 0
    let hour = comps.hour ?? 0
    let stable = (year * 1000000) + (month * 10000) + (day * 100) + hour
    let idx = abs(stable) % pieces.count
    return pieces[idx]
}

struct PrayersEntry: TimelineEntry {
    let date: Date
    let piece: ShortPiece
}

struct PrayersProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayersEntry {
        PrayersEntry(date: Date(), piece: pieces[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayersEntry) -> Void) {
        let entry = PrayersEntry(date: Date(), piece: pickPiece(seed: Date()))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayersEntry>) -> Void) {
        let now = Date()
        let cal = Calendar.current
        var entries: [PrayersEntry] = []
        for i in 0..<8 {
            let when = cal.date(byAdding: .hour, value: i * 3, to: now) ?? now
            entries.append(PrayersEntry(date: when, piece: pickPiece(seed: when)))
        }
        let next = cal.date(byAdding: .hour, value: 24, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(next)))
    }
}

struct PrayersWidgetView: View {
    let entry: PrayersEntry
    @Environment(\.colorScheme) var scheme
    @Environment(\.widgetFamily) var family

    var textColor: Color {
        scheme == .dark
            ? Color(red: 241/255, green: 243/255, blue: 245/255)
            : Color(red: 21/255, green: 23/255, blue: 26/255)
    }

    var mutedColor: Color {
        scheme == .dark
            ? Color(red: 182/255, green: 187/255, blue: 194/255)
            : Color(red: 90/255, green: 95/255, blue: 102/255)
    }

    var subtleColor: Color {
        scheme == .dark
            ? Color(red: 138/255, green: 143/255, blue: 150/255)
            : Color(red: 137/255, green: 142/255, blue: 149/255)
    }

    var arabicSize: CGFloat {
        switch family {
        case .systemLarge: return 26
        case .systemMedium: return 20
        default: return 17
        }
    }

    var translationSize: CGFloat {
        switch family {
        case .systemLarge: return 14
        case .systemMedium: return 12.5
        default: return 11
        }
    }

    var lineLimitArabic: Int {
        switch family {
        case .systemLarge: return 4
        case .systemMedium: return 2
        default: return 2
        }
    }

    var lineLimitTranslation: Int {
        switch family {
        case .systemLarge: return 4
        default: return 2
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.piece.arabic)
                .font(.custom("KFGQPC HAFS Uthmanic Script", size: arabicSize))
                .foregroundColor(textColor)
                .lineLimit(lineLimitArabic)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .environment(\.layoutDirection, .rightToLeft)
            if family != .systemSmall {
                Text(entry.piece.translation)
                    .font(.system(size: translationSize, weight: .regular))
                    .foregroundColor(mutedColor)
                    .lineLimit(lineLimitTranslation)
                    .padding(.top, 2)
            }
            Spacer(minLength: 4)
            Text(entry.piece.reference)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(subtleColor)
                .italic()
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct MyPrayersWidget: Widget {
    let kind: String = "MyPrayersWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            if #available(iOS 17.0, *) {
                PrayersWidgetView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            } else {
                PrayersWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("My Prayers")
        .description("Ayah or azkar of the day, transparent style.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabledIfAvailable()
    }
}

extension WidgetConfiguration {
    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}

@main
struct MyPrayersWidgetBundle: WidgetBundle {
    var body: some Widget {
        MyPrayersWidget()
    }
}
