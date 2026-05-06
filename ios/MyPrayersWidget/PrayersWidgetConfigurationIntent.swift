import AppIntents
import WidgetKit

enum WidgetContentType: String, AppEnum {
    case ayah, azkar, mix

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Content"
    static var caseDisplayRepresentations: [WidgetContentType: DisplayRepresentation] = [
        .ayah: DisplayRepresentation(title: "Ayah"),
        .azkar: DisplayRepresentation(title: "Azkar"),
        .mix: DisplayRepresentation(title: "Both")
    ]
}

enum WidgetLayout: String, AppEnum {
    case standard = "default"
    case centered

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Layout"
    static var caseDisplayRepresentations: [WidgetLayout: DisplayRepresentation] = [
        .standard: DisplayRepresentation(title: "Default"),
        .centered: DisplayRepresentation(title: "Centered")
    ]
}

enum WidgetStyle: String, AppEnum {
    case transparent, tinted, solid, accent

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Background"
    static var caseDisplayRepresentations: [WidgetStyle: DisplayRepresentation] = [
        .transparent: DisplayRepresentation(title: "Clear"),
        .tinted: DisplayRepresentation(title: "Tinted"),
        .solid: DisplayRepresentation(title: "Solid"),
        .accent: DisplayRepresentation(title: "Green")
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
    case small, medium, large

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Text size"
    static var caseDisplayRepresentations: [WidgetTextSize: DisplayRepresentation] = [
        .small: DisplayRepresentation(title: "Small"),
        .medium: DisplayRepresentation(title: "Medium"),
        .large: DisplayRepresentation(title: "Large")
    ]
}

enum WidgetLanguage: String, AppEnum {
    case english, arabic, kurdish

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Translation language"
    static var caseDisplayRepresentations: [WidgetLanguage: DisplayRepresentation] = [
        .english: DisplayRepresentation(title: "English"),
        .arabic: DisplayRepresentation(title: "Arabic"),
        .kurdish: DisplayRepresentation(title: "Kurdish")
    ]
}

enum WidgetFont: String, AppEnum {
    case uthmanic, scheherazade, naskh

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Arabic font"
    static var caseDisplayRepresentations: [WidgetFont: DisplayRepresentation] = [
        .uthmanic: DisplayRepresentation(title: "Uthmanic"),
        .scheherazade: DisplayRepresentation(title: "Scheherazade"),
        .naskh: DisplayRepresentation(title: "Naskh")
    ]
}

struct PrayersWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "My Prayers"
    static var description: IntentDescription? = IntentDescription("Show an ayah or azkar on your home screen.")

    @Parameter(title: "Content", default: WidgetContentType.mix)
    var contentType: WidgetContentType

    @Parameter(title: "Layout", default: WidgetLayout.standard)
    var layout: WidgetLayout

    @Parameter(title: "Background", default: WidgetStyle.transparent)
    var style: WidgetStyle

    @Parameter(title: "Theme", default: WidgetTheme.dark)
    var theme: WidgetTheme

    @Parameter(title: "Arabic font", default: WidgetFont.uthmanic)
    var arabicFont: WidgetFont

    @Parameter(title: "Text size", default: WidgetTextSize.medium)
    var textSize: WidgetTextSize

    @Parameter(title: "Translation", default: WidgetLanguage.english)
    var language: WidgetLanguage

    @Parameter(title: "Show translation", default: true)
    var showTranslation: Bool

    @Parameter(title: "Show reference", default: true)
    var showReference: Bool

    init() {}
}
