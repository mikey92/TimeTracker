//
//  AlarmStorage.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 5/17/25.
//

import Foundation
import UIKit
import UserNotifications

class AlarmStorage {
    private static let key = "alarms"
    private static let firedKey = "firedOneTimeAlarmIDs"

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
            // 알람 다시 켜는 경우: fired 기록 삭제
            var fired = UserDefaults.standard.dictionary(forKey: firedKey) as? [String: Date] ?? [:]
            fired.removeValue(forKey: alarm.id)
            UserDefaults.standard.set(fired, forKey: firedKey)

            var didMoveToNextDay = false

            let content = UNMutableNotificationContent()
            if LocalizationManager.isKorean {
                content.title = "\(alarm.cityName) 알람"
                content.body = "\(alarm.cityName)시간으로 \(alarm.hour)시 \(alarm.minute)분이 되었습니다!"
            } else if LocalizationManager.isJapanese {
                content.title = "\(alarm.cityName)のアラーム"
                content.body = "\(alarm.cityName)の時間で\(alarm.hour)時\(alarm.minute)分になりました。"
            } else if LocalizationManager.isSimplifiedChinese {
                content.title = "\(alarm.cityName)闹钟"
                content.body = "现在是\(alarm.cityName)时间的\(alarm.hour)点\(alarm.minute)分。"
            } else {
                content.title = "\(alarm.cityName) Alarm"
                content.body = "It's \(alarm.hour):\(String(format: "%02d", alarm.minute)) in \(alarm.cityName)"
            }
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
                for weekday in alarm.weekdays {
                    var weekdayComponents = DateComponents()
                    weekdayComponents.weekday = weekday
                    weekdayComponents.hour = alarm.hour
                    weekdayComponents.minute = alarm.minute

                    var cityCalendar = Calendar.current
                    if let tz = TimeZone(identifier: alarm.timeZoneIdentifier) {
                        cityCalendar.timeZone = tz
                    }

                    guard let cityDate = cityCalendar.nextDate(after: Date(), matching: weekdayComponents, matchingPolicy: .nextTime) else {
                        continue
                    }

                    let localComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: cityDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: true)
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
    
    static func deactivateExpiredOneTimeAlarms() {
        var all = load()
        let now = Date()
        let userDefaults = UserDefaults.standard
        let firedIDs = userDefaults.dictionary(forKey: firedKey) as? [String: Date] ?? [:]

        var changed = false

        for i in 0..<all.count {
            var alarm = all[i]
            guard alarm.isOn, alarm.weekdays.isEmpty else { continue }

            if let timeZone = TimeZone(identifier: alarm.timeZoneIdentifier) {
                var calendar = Calendar.current
                calendar.timeZone = timeZone

                var triggerComponents = DateComponents()
                triggerComponents.hour = alarm.hour
                triggerComponents.minute = alarm.minute

                if let triggerDate = calendar.nextDate(after: now, matching: triggerComponents, matchingPolicy: .nextTime, direction: .backward),
                   triggerDate < now, firedIDs[alarm.id] != nil {
                    alarm.isOn = false
                    all[i] = alarm
                    changed = true
                }
            }
        }

        if changed {
            save(all)
        }
    }

    static func markAlarmAsFired(id: String) {
        var fired = UserDefaults.standard.dictionary(forKey: firedKey) as? [String: Date] ?? [:]
        fired[id] = Date()
        UserDefaults.standard.set(fired, forKey: firedKey)
    }
}
