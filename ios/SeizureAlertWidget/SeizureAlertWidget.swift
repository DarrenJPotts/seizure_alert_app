import SwiftUI
import WidgetKit

private let appGroupId = "group.com.darren.potts.seizureApp"
private let widgetKind = "SeizureAlertWidget"

struct SafetyEntry: TimelineEntry {
    let date: Date
    let title: String
    let detail: String
    let updated: String
    let actionLabel: String
    let actionURL: URL
}

struct SafetyProvider: TimelineProvider {
    func placeholder(in context: Context) -> SafetyEntry {
        entry(
            title: "All clear",
            detail: "Your circle is ready.",
            updated: "Open the app to update",
            actionLabel: "SOS",
            actionURI: "seizurealert://widget/sos"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SafetyEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SafetyEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> SafetyEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return entry(
            title: defaults?.string(forKey: "widget_title") ?? "Sign in required",
            detail: defaults?.string(forKey: "widget_detail") ?? "Open the app to continue.",
            updated: defaults?.string(forKey: "widget_updated") ?? "Not updated yet",
            actionLabel: defaults?.string(forKey: "widget_action_label") ?? "OPEN",
            actionURI: defaults?.string(forKey: "widget_action_uri") ?? "seizurealert://widget/openApp"
        )
    }

    private func entry(
        title: String,
        detail: String,
        updated: String,
        actionLabel: String,
        actionURI: String
    ) -> SafetyEntry {
        SafetyEntry(
            date: Date(),
            title: title,
            detail: detail,
            updated: updated,
            actionLabel: actionLabel,
            actionURL: URL(string: actionURI) ?? URL(string: "seizurealert://widget/openApp")!
        )
    }
}

struct SeizureAlertWidgetView: View {
    let entry: SafetyEntry

    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(Color.white, for: .widget)
        } else {
            content.background(Color.white)
        }
    }

    private var content: some View {
        VStack(spacing: 8) {
            Text(entry.title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.black.opacity(0.55))
                .lineLimit(1)

            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
                Circle()
                    .inset(by: 13)
                    .fill(Color.white)
                    .overlay(
                        Circle()
                            .inset(by: 13)
                            .stroke(Color.black, lineWidth: 3)
                    )
                Text(entry.actionLabel)
                    .font(.system(size: entry.actionLabel == "SOS" ? 31 : 23, weight: .bold))
                    .tracking(entry.actionLabel == "SOS" ? 5 : 1)
                    .foregroundColor(Color.black)
            }
            .accessibilityLabel("\(entry.actionLabel). \(entry.title). \(entry.detail)")

            Text(entry.updated)
                .font(.system(size: 10))
                .foregroundColor(Color.black.opacity(0.45))
                .lineLimit(1)
        }
        .padding(12)
        .widgetURL(entry.actionURL)
    }
}

@main
struct SeizureAlertWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: SafetyProvider()) { entry in
            SeizureAlertWidgetView(entry: entry)
        }
        .configurationDisplayName("Seizure Alert")
        .description("Current safety state and SOS shortcut")
        .supportedFamilies([.systemSmall])
    }
}
