import AppIntents
import WidgetKit

enum WidgetContentType: String, AppEnum {
    case ayah, azkar, mix

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Content"
    static var caseDisplayRepresentations: [WidgetContentType: DisplayRepresentation] = [
        .ayah: DisplayRepresentation(title: "Ayah only"),
        .azkar: DisplayRepresentation(title: "Azkar only"),
        .mix: DisplayRepresentation(title: "Both")
    ]
}

enum WidgetStyle: String, AppEnum {
    case transparent, tinted, solid, accent, ornate

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Style"
    static var caseDisplayRepresentations: [WidgetStyle: DisplayRepresentation] = [
        .transparent: DisplayRepresentation(title: "Transparent"),
        .tinted: DisplayRepresentation(title: "Tinted glass"),
        .solid: DisplayRepresentation(title: "Solid card"),
        .accent: DisplayRepresentation(title: "Accent green"),
        .ornate: DisplayRepresentation(title: "Ornate frame")
    ]
}

enum WidgetTheme: String, AppEnum {
    case system, light, dark

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Theme"
    static var caseDisplayRepresentations: [WidgetTheme: DisplayRepresentation] = [
        .system: DisplayRepresentation(title: "Auto"),
        .light: DisplayRepresentation(title: "Light"),
        .dark: DisplayRepresentation(title: "Dark")
    ]
}

enum WidgetTextSize: String, AppEnum {
    case small, medium, large, xlarge

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Text size"
    static var caseDisplayRepresentations: [WidgetTextSize: DisplayRepresentation] = [
        .small: DisplayRepresentation(title: "Small"),
        .medium: DisplayRepresentation(title: "Medium"),
        .large: DisplayRepresentation(title: "Large"),
        .xlarge: DisplayRepresentation(title: "Extra large")
    ]
}

enum WidgetLanguage: String, AppEnum {
    case english, arabic, kurdish

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Translation language"
    static var caseDisplayRepresentations: [WidgetLanguage: DisplayRepresentation] = [
        .english: DisplayRepresentation(title: "English"),
        .arabic: DisplayRepresentation(title: "Arabic only"),
        .kurdish: DisplayRepresentation(title: "Kurdish")
    ]
}

enum WidgetFont: String, AppEnum {
    case uthmani, system

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Arabic font"
    static var caseDisplayRepresentations: [WidgetFont: DisplayRepresentation] = [
        .uthmani: DisplayRepresentation(title: "Uthmanic Hafs"),
        .system: DisplayRepresentation(title: "System")
    ]
}

struct PrayersWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "My Prayers"
    static var description: IntentDescription? = IntentDescription("Show an ayah or azkar on your home screen.")

    @Parameter(title: "Content", default: WidgetContentType.mix)
    var contentType: WidgetContentType

    @Parameter(title: "Style", default: WidgetStyle.tinted)
    var style: WidgetStyle

    @Parameter(title: "Theme", default: WidgetTheme.system)
    var theme: WidgetTheme

    @Parameter(title: "Text size", default: WidgetTextSize.medium)
    var textSize: WidgetTextSize

    @Parameter(title: "Translation", default: WidgetLanguage.english)
    var language: WidgetLanguage

    @Parameter(title: "Show translation", default: true)
    var showTranslation: Bool

    @Parameter(title: "Show reference", default: true)
    var showReference: Bool

    @Parameter(title: "Arabic font", default: WidgetFont.uthmani)
    var arabicFont: WidgetFont

    @Parameter(title: "Refresh every (hours)",
               default: 6,
               inclusiveRange: (1, 24))
    var refreshHours: Int

    init() {}
}
