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
        let step = max(1, min(24, configuration.refreshHours))
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
        case .small:  return 14
        case .medium: return 17
        case .large:  return 20
        case .xlarge: return 23
        }
    }
    var translation: CGFloat {
        switch self {
        case .small:  return 10
        case .medium: return 12
        case .large:  return 13.5
        case .xlarge: return 15
        }
    }
    var reference: CGFloat {
        switch self {
        case .small:  return 9
        case .medium: return 10.5
        case .large:  return 11.5
        case .xlarge: return 12.5
        }
    }
}

private struct WidgetPalette {
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let onAccent: Color
    let accent: Color
    let line: Color

    static func resolve(scheme: ColorScheme, style: WidgetStyle) -> WidgetPalette {
        let dark = scheme == .dark
        let onAccentColor: Color = dark
            ? Color(red: 14/255, green: 16/255, blue: 19/255)
            : Color.white
        if style == .accent {
            return WidgetPalette(
                textPrimary: onAccentColor,
                textSecondary: onAccentColor.opacity(0.85),
                textTertiary: onAccentColor.opacity(0.7),
                onAccent: onAccentColor,
                accent: onAccentColor,
                line: onAccentColor.opacity(0.18)
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
                : Color(red: 137/255, green: 142/255, blue: 149/255),
            onAccent: onAccentColor,
            accent: dark
                ? Color(red: 52/255, green: 201/255, blue: 122/255)
                : Color(red: 31/255, green: 138/255, blue: 76/255),
            line: dark
                ? Color(red: 35/255, green: 40/255, blue: 48/255)
                : Color(red: 230/255, green: 230/255, blue: 225/255)
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
        let arabicFontName = (cfg.arabicFont == .uthmani)
            ? "KFGQPC HAFS Uthmanic Script"
            : ""
        let arabicSize = cfg.textSize.arabic + sizeBumpForFamily()
        let translationSize = cfg.textSize.translation + sizeBumpForFamily() * 0.5

        let arabicFont: Font = arabicFontName.isEmpty
            ? .system(size: arabicSize, weight: .regular)
            : .custom(arabicFontName, size: arabicSize)

        return VStack(alignment: .leading, spacing: spacing) {
            Text(entry.piece.arabic)
                .font(arabicFont)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(arabicSize * 0.45)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .lineLimit(arabicLineLimit)

            if cfg.showTranslation && family != .systemSmall {
                Text(entry.piece.translation(for: cfg.language))
                    .font(.system(size: translationSize, weight: .regular))
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(translationSize * 0.25)
                    .lineLimit(translationLineLimit)
                    .padding(.top, family == .systemLarge ? 4 : 2)
            }

            Spacer(minLength: 4)

            if cfg.style == .ornate {
                OrnamentLine(color: palette.line)
                    .padding(.vertical, 4)
            }

            if cfg.showReference {
                Text(entry.piece.reference)
                    .font(.system(size: cfg.textSize.reference, weight: .medium))
                    .italic()
                    .foregroundStyle(palette.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            BackgroundView(style: cfg.style, scheme: scheme, palette: palette)
        }
    }

    private func sizeBumpForFamily() -> CGFloat {
        switch family {
        case .systemSmall:  return -1
        case .systemMedium: return 1
        case .systemLarge:  return 4
        default:            return 0
        }
    }

    private var padding: EdgeInsets {
        switch family {
        case .systemSmall:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .systemLarge:
            return EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        default:
            return EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        }
    }

    private var spacing: CGFloat {
        switch family {
        case .systemSmall:  return 4
        case .systemLarge:  return 10
        default:            return 6
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
    let palette: WidgetPalette

    var body: some View {
        switch style {
        case .transparent:
            Color.clear
        case .tinted:
            ZStack {
                Color.clear
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)
            }
        case .solid:
            scheme == .dark
                ? Color(red: 22/255, green: 25/255, blue: 29/255)
                : Color.white
        case .accent:
            LinearGradient(
                colors: scheme == .dark
                    ? [Color(red: 52/255, green: 201/255, blue: 122/255),
                       Color(red: 43/255, green: 185/255, blue: 109/255)]
                    : [Color(red: 31/255, green: 138/255, blue: 76/255),
                       Color(red: 24/255, green: 107/255, blue: 59/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ornate:
            ZStack {
                scheme == .dark
                    ? Color(red: 22/255, green: 25/255, blue: 29/255)
                    : Color.white
                OrnamentBorder(color: palette.line)
                    .padding(6)
            }
        }
    }
}

private struct OrnamentLine: View {
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(height: 1)
            Image(systemName: "diamond.fill")
                .font(.system(size: 5, weight: .regular))
                .foregroundStyle(color)
            Rectangle()
                .fill(color)
                .frame(height: 1)
        }
    }
}

private struct OrnamentBorder: View {
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(color, lineWidth: 1)
            .overlay(
                VStack {
                    HStack {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 4))
                            .foregroundStyle(color)
                            .padding(.leading, -2)
                            .padding(.top, -2)
                        Spacer()
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 4))
                            .foregroundStyle(color)
                            .padding(.trailing, -2)
                            .padding(.top, -2)
                    }
                    Spacer()
                    HStack {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 4))
                            .foregroundStyle(color)
                            .padding(.leading, -2)
                            .padding(.bottom, -2)
                        Spacer()
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 4))
                            .foregroundStyle(color)
                            .padding(.trailing, -2)
                            .padding(.bottom, -2)
                    }
                }
            )
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
