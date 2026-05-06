import AppIntents
import WidgetKit

struct PrayersWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure"
    static var description: IntentDescription? = "Pick what kind of verse to show, and how it looks."

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

    @Parameter(title: "Refresh interval (hours)", default: 6)
    var refreshHours: Int

    init() {}
}
