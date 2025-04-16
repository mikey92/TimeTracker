//
//  Alarm.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 4/12/25.
//

import Foundation

struct Alarm {
    let city: City
    let time: Date
    let isEnabled: Bool
}

struct AlarmMeta: Codable, Equatable {
    let id: String
    let cityName: String
    let timeZoneIdentifier: String
    let hour: Int
    let minute: Int
    let weekdays: [Int] // 반복 요일 (비었으면 1회성)
}

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

    static func remove(id: String) {
        var all = load()
        all.removeAll { $0.id == id }
        save(all)
    }
}
