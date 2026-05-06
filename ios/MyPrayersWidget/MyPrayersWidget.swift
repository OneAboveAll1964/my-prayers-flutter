import WidgetKit
import SwiftUI

struct PrayersEntry: TimelineEntry {
    let date: Date
    let piece: ShortPiece
    let configuration: PrayersWidgetConfigurationIntent
}

struct PrayersTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = PrayersEntry
    typealias Intent = PrayersWidgetConfigurationIntent

    func placeholder(in context: Context) -> PrayersEntry {
        PrayersEntry(date: Date(),
                     piece: shortAyahs[0],
                     configuration: PrayersWidgetConfigurationIntent())
    }

    func snapshot(for configuration: PrayersWidgetConfigurationIntent,
                  in context: Context) async -> PrayersEntry {
        PrayersEntry(date: Date(),
                     piece: pickPiece(seed: Date(), type: configuration.contentType),
                     configuration: configuration)
    }

    func timeline(for configuration: PrayersWidgetConfigurationIntent,
                  in context: Context) async -> Timeline<PrayersEntry> {
        let now = Date()
        let cal = Calendar.current
        let step = 6
        var entries: [PrayersEntry] = []
        for i in 0..<6 {
            let when = cal.date(byAdding: .hour, value: i * step, to: now) ?? now
            let piece = pickPiece(seed: when, type: configuration.contentType)
            entries.append(PrayersEntry(date: when, piece: piece, configuration: configuration))
        }
        let next = cal.date(byAdding: .hour, value: step, to: now) ?? now
        return Timeline(entries: entries, policy: .after(next))
    }
}

private extension WidgetTextSize {
    var arabic: CGFloat {
        switch self {
        case .small:  return 18
        case .medium: return 26
        case .large:  return 36
        }
    }
    var translation: CGFloat {
        switch self {
        case .small:  return 11
        case .medium: return 14
        case .large:  return 17
        }
    }
    var reference: CGFloat {
        switch self {
        case .small:  return 9
        case .medium: return 11
        case .large:  return 13
        }
    }
}

private extension WidgetFont {
    var fontName: String {
        switch self {
        case .uthmanic:    return "KFGQPC HAFS Uthmanic Script"
        case .scheherazade: return "Scheherazade New"
        case .naskh:        return "Noto Naskh Arabic"
        }
    }
}

private struct WidgetPalette {
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    static func resolve(scheme: ColorScheme, style: WidgetStyle) -> WidgetPalette {
        let dark = scheme == .dark
        if style == .accent {
            return WidgetPalette(
                textPrimary: .white,
                textSecondary: Color.white.opacity(0.85),
                textTertiary: Color.white.opacity(0.7)
            )
        }
        return WidgetPalette(
            textPrimary: dark
                ? Color(red: 241/255, green: 243/255, blue: 245/255)
                : Color(red: 21/255, green: 23/255, blue: 26/255),
            textSecondary: dark
                ? Color(red: 182/255, green: 187/255, blue: 194/255)
                : Color(red: 90/255, green: 95/255, blue: 102/255),
            textTertiary: dark
                ? Color(red: 138/255, green: 143/255, blue: 150/255)
                : Color(red: 137/255, green: 142/255, blue: 149/255)
        )
    }
}

private func resolvedScheme(_ system: ColorScheme,
                            _ override: WidgetTheme) -> ColorScheme {
    switch override {
    case .light: return .light
    case .dark:  return .dark
    case .system: return system
    }
}

struct PrayersWidgetView: View {
    let entry: PrayersEntry
    @Environment(\.colorScheme) var systemScheme
    @Environment(\.widgetFamily) var family

    var body: some View {
        let cfg = entry.configuration
        let scheme = resolvedScheme(systemScheme, cfg.theme)
        let palette = WidgetPalette.resolve(scheme: scheme, style: cfg.style)
        let arabicSize = cfg.textSize.arabic + sizeBumpForFamily()
        let translationSize = cfg.textSize.translation + sizeBumpForFamily() * 0.5
        let arabicFont: Font = .custom(cfg.arabicFont.fontName, size: arabicSize)
        let isCentered = cfg.layout == .centered
        let arabicText = isCentered ? "﴿ \(entry.piece.arabic) ﴾" : entry.piece.arabic

        return VStack(alignment: isCentered ? .center : .leading, spacing: spacing) {
            Text(arabicText)
                .font(arabicFont)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(arabicSize * 0.25)
                .multilineTextAlignment(isCentered ? .center : .trailing)
                .frame(maxWidth: .infinity, alignment: isCentered ? .center : .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .lineLimit(arabicLineLimit)

            if cfg.showTranslation && family != .systemSmall {
                Text(entry.piece.translation(for: cfg.language))
                    .font(.system(size: translationSize, weight: .regular))
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(translationSize * 0.2)
                    .lineLimit(translationLineLimit)
                    .multilineTextAlignment(isCentered ? .center : .leading)
                    .frame(maxWidth: .infinity, alignment: isCentered ? .center : .leading)
                    .padding(.top, 2)
            }

            if !isCentered {
                Spacer(minLength: 4)
            }

            if cfg.showReference {
                Text(entry.piece.reference)
                    .font(.system(size: cfg.textSize.reference, weight: .medium))
                    .italic()
                    .foregroundStyle(palette.textTertiary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: isCentered ? .center : .leading)
            }
        }
        .padding(padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity,
               alignment: isCentered ? .center : .topLeading)
        .containerBackground(for: .widget) {
            BackgroundView(style: cfg.style, scheme: scheme)
        }
    }

    private func sizeBumpForFamily() -> CGFloat {
        switch family {
        case .systemSmall:  return -2
        case .systemMedium: return 0
        case .systemLarge:  return 4
        default:            return 0
        }
    }

    private var padding: EdgeInsets {
        switch family {
        case .systemSmall:
            return EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        case .systemLarge:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        default:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        }
    }

    private var spacing: CGFloat {
        switch family {
        case .systemSmall:  return 2
        case .systemLarge:  return 6
        default:            return 3
        }
    }

    private var arabicLineLimit: Int {
        switch family {
        case .systemSmall:  return 2
        case .systemMedium: return 3
        case .systemLarge:  return 5
        default:            return 3
        }
    }

    private var translationLineLimit: Int {
        switch family {
        case .systemMedium: return 2
        case .systemLarge:  return 4
        default:            return 1
        }
    }
}

private struct BackgroundView: View {
    let style: WidgetStyle
    let scheme: ColorScheme

    var body: some View {
        switch style {
        case .transparent:
            Color.clear
        case .tinted:
            scheme == .dark
                ? Color(red: 22/255, green: 25/255, blue: 29/255).opacity(0.8)
                : Color.white.opacity(0.8)
        case .solid:
            scheme == .dark
                ? Color(red: 22/255, green: 25/255, blue: 29/255)
                : Color.white
        case .accent:
            LinearGradient(
                colors: scheme == .dark
                    ? [Color(red: 91/255, green: 174/255, blue: 130/255),
                       Color(red: 74/255, green: 152/255, blue: 112/255)]
                    : [Color(red: 46/255, green: 124/255, blue: 79/255),
                       Color(red: 31/255, green: 92/255, blue: 57/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct MyPrayersWidget: Widget {
    let kind: String = "MyPrayersWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: PrayersWidgetConfigurationIntent.self,
            provider: PrayersTimelineProvider()
        ) { entry in
            PrayersWidgetView(entry: entry)
        }
        .configurationDisplayName("My Prayers")
        .description("A short ayah or azkar with rich style options.")
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
