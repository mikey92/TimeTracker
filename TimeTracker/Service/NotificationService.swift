//
//  NotificationService.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 2025-02-12.
//

import Foundation
import UserNotifications

struct NotificationService {

    // MARK: - Content Creation

    static func makeAlarmContent(cityName: String, cityNameKR: String, hour: Int, minute: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        if LocalizationManager.isKorean {
            content.title = "\(cityNameKR) 알람"
            content.body = "\(cityNameKR)시간으로 \(hour)시 \(minute)분이 되었습니다!"
        } else if LocalizationManager.isJapanese {
            content.title = "\(cityName)のアラーム"
            content.body = "\(cityName)の時間で\(hour)時\(minute)分になりました。"
        } else if LocalizationManager.isSimplifiedChinese {
            content.title = "\(cityName)闹钟"
            content.body = "现在是\(cityName)时间的\(hour)点\(minute)分。"
        } else {
            content.title = "\(cityName) Alarm"
            content.body = "It's \(hour):\(String(format: "%02d", minute)) in \(cityName)"
        }
        content.sound = .default
        return content
    }

    // MARK: - Scheduling

    /// Schedule a one-time alarm. Returns true if the alarm was moved to the next day.
    @discardableResult
    static func scheduleOneTimeAlarm(id: String, content: UNNotificationContent, hour: Int, minute: Int, timeZoneIdentifier: String) -> Bool {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else { return false }

        let now = Date()
        var cityCalendar = Calendar.current
        cityCalendar.timeZone = timeZone

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        guard var cityDate = cityCalendar.date(from: dateComponents) else { return false }

        var didMoveToNextDay = false
        if cityDate < now {
            cityDate = cityCalendar.date(byAdding: .day, value: 1, to: cityDate) ?? cityDate
            didMoveToNextDay = true
        }

        // Convert city time to local time for trigger
        let localOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: cityDate))
        let targetOffset = TimeInterval(timeZone.secondsFromGMT(for: cityDate))
        let adjustedDate = cityDate - (targetOffset - localOffset)

        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: adjustedDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)

        return didMoveToNextDay
    }

    /// Schedule a repeating alarm for specific weekdays.
    static func scheduleRepeatingAlarm(id: String, content: UNNotificationContent, hour: Int, minute: Int, weekdays: [Int], timeZoneIdentifier: String) {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else { return }

        var cityCalendar = Calendar.current
        cityCalendar.timeZone = timeZone

        for weekday in weekdays {
            var weekdayComponents = DateComponents()
            weekdayComponents.weekday = weekday
            weekdayComponents.hour = hour
            weekdayComponents.minute = minute

            guard let cityDate = cityCalendar.nextDate(after: Date(), matching: weekdayComponents, matchingPolicy: .nextTime) else {
                continue
            }

            let localComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: cityDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "\(id)_\(weekday)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Removal

    static func removeNotifications(for alarm: AlarmMeta) {
        let center = UNUserNotificationCenter.current()
        if alarm.weekdays.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: [alarm.id])
        } else {
            let ids = alarm.weekdays.map { "\(alarm.id)_\($0)" }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
