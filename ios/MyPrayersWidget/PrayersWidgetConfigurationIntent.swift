import AppIntents
import WidgetKit

struct PrayersWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure"
    static var description: IntentDescription? = "Configure your widget."

    @Parameter(title: "Type", default: "mix")
    var contentType: String

    @Parameter(title: "Theme", default: "auto")
    var theme: String

    @Parameter(title: "Text size", default: "m")
    var textSize: String

    @Parameter(title: "Language", default: "en")
    var language: String

    @Parameter(title: "Show translation", default: true)
    var showTranslation: Bool

    @Parameter(title: "Randomize verse")
    var randomize: Bool?

    init() {}
}
