//
//  TimeZoneHelper.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 2025/01/15.
//

import Foundation

struct TimeZoneHelper {

    /// Calculate hour difference between a timezone and local timezone
    static func hourDifference(for timeZone: TimeZone, at date: Date = Date()) -> Double {
        let currentOffset = timeZone.secondsFromGMT(for: date)
        let localOffset = TimeZone.current.secondsFromGMT(for: date)
        return Double(currentOffset - localOffset) / 3600.0
    }

    /// Calculate day difference between a timezone and local timezone
    static func dayDifference(for timeZone: TimeZone, at date: Date = Date()) -> Int {
        let calendar = Calendar.current
        var cityCalendar = Calendar.current
        cityCalendar.timeZone = timeZone
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: cityCalendar.startOfDay(for: date)).day ?? 0
    }

    /// Format hour difference as string (e.g., "+9", "-5.5")
    static func formatHourDifference(_ hourDiff: Double) -> String {
        if hourDiff == hourDiff.rounded() {
            return "\(hourDiff >= 0 ? "+" : "")\(Int(hourDiff))"
        } else {
            return "\(hourDiff >= 0 ? "+" : "")\(String(format: "%.1f", hourDiff))"
        }
    }

    /// Format day difference as localized string
    static func formatDayDifference(_ dayDiff: Int) -> String {
        switch dayDiff {
        case 1: return String(localized: "tomorrow")
        case -1: return String(localized: "yesterday")
        default: return String(localized: "today")
        }
    }

    /// Get full gap text like "내일, +14" or "오늘, ±0"
    static func gapText(for timeZone: TimeZone, at date: Date = Date()) -> String {
        let hourDiff = hourDifference(for: timeZone, at: date)
        let dayDiff = dayDifference(for: timeZone, at: date)

        if hourDiff == 0 {
            return "\(String(localized: "today")), ±0"
        }

        let dayText = formatDayDifference(dayDiff)
        let hourStr = formatHourDifference(hourDiff)
        return "\(dayText), \(hourStr)"
    }

    /// Get localized short weekday symbol (e.g., "Mon", "월")
    static func weekdaySymbol(for weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols[(weekday - 1) % 7]
    }
}
