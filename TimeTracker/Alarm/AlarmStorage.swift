//
//  AlarmStorage.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 5/17/25.
//

import Foundation
import UIKit

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
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    static func remove(id: String) {
        var all = load()
        guard let alarm = all.first(where: { $0.id == id }) else { return }

        NotificationService.removeNotifications(for: alarm)

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

        if isOn {
            // 알람 다시 켜는 경우: fired 기록 삭제
            var fired = UserDefaults.standard.dictionary(forKey: firedKey) as? [String: Date] ?? [:]
            fired.removeValue(forKey: alarm.id)
            UserDefaults.standard.set(fired, forKey: firedKey)

            let content = NotificationService.makeAlarmContent(
                cityName: alarm.cityName,
                cityNameKR: alarm.cityNameKR,
                hour: alarm.hour,
                minute: alarm.minute
            )

            if alarm.weekdays.isEmpty {
                let didMoveToNextDay = NotificationService.scheduleOneTimeAlarm(
                    id: alarm.id,
                    content: content,
                    hour: alarm.hour,
                    minute: alarm.minute,
                    timeZoneIdentifier: alarm.timeZoneIdentifier
                )
                completion?(didMoveToNextDay)
            } else {
                NotificationService.scheduleRepeatingAlarm(
                    id: alarm.id,
                    content: content,
                    hour: alarm.hour,
                    minute: alarm.minute,
                    weekdays: alarm.weekdays,
                    timeZoneIdentifier: alarm.timeZoneIdentifier
                )
                completion?(false)
            }
        } else {
            NotificationService.removeNotifications(for: alarm)
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
