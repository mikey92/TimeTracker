//
//  TimeTrackerWidget.swift
//  TimeTrackerWidget
//
//  Created by Hye Ri Kim on 5/17/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), alarms: [])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let alarms = loadAlarms()
        return SimpleEntry(date: Date(), configuration: configuration, alarms: alarms)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let now = Date()
        let alarms = loadAlarms()

        let entries: [SimpleEntry] = (0..<60).map { offset in
            let date = Calendar.current.date(byAdding: .minute, value: offset, to: now)!
            return SimpleEntry(date: date, configuration: configuration, alarms: alarms)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    private func loadAlarms() -> [AlarmInfo] {
        let userDefaults = UserDefaults(suiteName: "group.com.hyerikim.TimeTracker")
        guard let data = userDefaults?.array(forKey: "Top3Alarms") as? [[String: Any]] else {
            return []
        }

        return data.compactMap { dict -> AlarmInfo? in
            guard let city = dict["city"] as? String,
                  let tz = dict["timeZoneIdentifier"] as? String else {
                return nil
            }
            return AlarmInfo(city: city, timeZoneIdentifier: tz)
        }
    }
}

struct AlarmInfo: Codable, Identifiable {
    let id = UUID() // ForEach에 필요
    let city: String
    let timeZoneIdentifier: String
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let alarms: [AlarmInfo]
}

struct TimeTrackerWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            mediumView
        }
    }
    
    var smallView: some View {
        VStack(alignment: .leading) {
            ForEach(entry.alarms.prefix(2)) { alarm in
                if let tz = TimeZone(identifier: alarm.timeZoneIdentifier) {
                    VStack {
                        Text(alarm.city + ":")
                        Text(Date(), style: .time)
                            .environment(\.timeZone, tz)
                    }
                }
            }
        }
    }
    
    var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("current_time")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(Date(), style: .time)
                .font(.system(size: 28, weight: .bold))

            Divider()

            ForEach(entry.alarms.prefix(3)) { alarm in
                if let timeZone = TimeZone(identifier: alarm.timeZoneIdentifier) {
                    HStack {
                        Text(alarm.city + ":")
                        Text(Date(), style: .time)
                            .environment(\.timeZone, timeZone)
                    }
                    .font(.system(size: 14))
                }
            }
        }
        .padding()
    }


    private func formattedTime(inMedium timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale.autoupdatingCurrent
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: Date())
    }
    
    private func formattedTime(inSmall timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "hh:mm"
        return formatter.string(from: Date())
    }
}

struct TimeTrackerWidget: Widget {
    let kind: String = "TimeTrackerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TimeTrackerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("widget_display_name")
        .description("widget_description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    TimeTrackerWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        configuration: ConfigurationAppIntent(),
        alarms: [
            AlarmInfo(city: "New York", timeZoneIdentifier: "America/New_York"),
            AlarmInfo(city: "Seoul", timeZoneIdentifier: "Asia/Seoul"),
            AlarmInfo(city: "London", timeZoneIdentifier: "Europe/London")
        ]
    )
}
