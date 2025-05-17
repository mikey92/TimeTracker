//
//  AlarmStorage.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 5/17/25.
//

import Foundation
import UIKit
import UserNotifications

enum AlarmStorage {
    private static let key = "alarm_metas"

    static func load() -> [AlarmMeta] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let result = try? JSONDecoder().decode([AlarmMeta].self, from: data) else {
            return []
        }
        return result
    }

    static func save(_ list: [AlarmMeta]) {
        let data = try? JSONEncoder().encode(list)
        UserDefaults.standard.set(data, forKey: key)
    }

    static func add(_ meta: AlarmMeta) {
        var all = load()
        all.append(meta)
        save(all)
    }

    static func deactivateExpiredOneTimeAlarms() {
        var all = load()
        let now = Date()

        var changed = false

        for i in 0..<all.count {
            var alarm = all[i]
            if alarm.isOn,
               alarm.weekdays.isEmpty { // 1회성
                let calendar = Calendar.current
                var triggerDateComponents = DateComponents()
                triggerDateComponents.hour = alarm.hour
                triggerDateComponents.minute = alarm.minute

                // 시간대 고려
                if let timeZone = TimeZone(identifier: alarm.timeZoneIdentifier) {
                    var tzCalendar = calendar
                    tzCalendar.timeZone = timeZone
                    if let today = tzCalendar.date(from: triggerDateComponents),
                       today < now {
                        alarm.isOn = false
                        all[i] = alarm
                        changed = true
                    }
                }
            }
        }

        if changed {
            save(all)
        }
    }
    
    static func remove(id: String) {
        var all = load()
        guard let alarm = all.first(where: { $0.id == id }) else { return }

        let center = UNUserNotificationCenter.current()

        if alarm.weekdays.isEmpty {
            // 1회성 알람
            center.removePendingNotificationRequests(withIdentifiers: [alarm.id])
        } else {
            // 반복 알람
            let ids = alarm.weekdays.map { "\(alarm.id)_\($0)" }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }

        all.removeAll { $0.id == id }
        save(all)
    }
    
    static func update(_ meta: AlarmMeta) {
        var all = load()
        if let index = all.firstIndex(where: { $0.id == meta.id }) {
            all[index] = meta
        } else {
            all.append(meta)
        }
        save(all)
    }

    static func update(id: String, isOn: Bool, completion: ((Bool) -> Void)? = nil) {
        var all = load()
        guard let index = all.firstIndex(where: { $0.id == id }) else {
            completion?(false)
            return
        }

        all[index].isOn = isOn
        save(all)

        let alarm = all[index]
        let center = UNUserNotificationCenter.current()

        if isOn {
            var didMoveToNextDay = false

            let content = UNMutableNotificationContent()
            content.title = "\(alarm.cityName) 알람"
            content.body = "\(alarm.cityName)의 알람 시간이 되었습니다!"
            content.sound = .default

            if alarm.weekdays.isEmpty {
                let now = Date()
                if let timeZone = TimeZone(identifier: alarm.timeZoneIdentifier) {
                    var calendar = Calendar.current
                    calendar.timeZone = timeZone

                    var dateComponents = DateComponents()
                    dateComponents.hour = alarm.hour
                    dateComponents.minute = alarm.minute

                    guard var finalDate = calendar.date(from: dateComponents) else {
                        completion?(false)
                        return
                    }

                    if finalDate < now {
                        finalDate = calendar.date(byAdding: .day, value: 1, to: finalDate) ?? finalDate
                        didMoveToNextDay = true
                    }

                    let localOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: finalDate))
                    let targetOffset = TimeInterval(timeZone.secondsFromGMT(for: finalDate))
                    let adjustedDate = finalDate - (targetOffset - localOffset)

                    let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: adjustedDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                    let request = UNNotificationRequest(identifier: alarm.id, content: content, trigger: trigger)
                    center.add(request)
                }
            } else {
                // 반복 알람
                for weekday in alarm.weekdays {
                    var dateComponents = DateComponents()
                    dateComponents.weekday = weekday
                    dateComponents.hour = alarm.hour
                    dateComponents.minute = alarm.minute

                    var calendar = Calendar.current
                    if let tz = TimeZone(identifier: alarm.timeZoneIdentifier) {
                        calendar.timeZone = tz
                    }

                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(identifier: "\(alarm.id)_\(weekday)", content: content, trigger: trigger)
                    center.add(request)
                }
            }

            completion?(didMoveToNextDay)
        } else {
            if alarm.weekdays.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: [alarm.id])
            } else {
                let ids = alarm.weekdays.map { "\(alarm.id)_\($0)" }
                center.removePendingNotificationRequests(withIdentifiers: ids)
            }

            completion?(false)
        }
    }
}
