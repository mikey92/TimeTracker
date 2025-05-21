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
    let cityNameKR: String
    let timeZoneIdentifier: String
    let hour: Int
    let minute: Int
    let weekdays: [Int] // 반복 요일 (비었으면 1회성)
    var isOn: Bool
}
