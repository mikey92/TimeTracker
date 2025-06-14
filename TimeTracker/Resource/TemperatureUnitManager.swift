//
//  TemperatureUnitManager.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 6/14/25.
//

import Foundation

struct TemperatureUnitManager {
    static var isCelsius: Bool {
        return Locale.current.usesMetricSystem
    }
    
    static var unit: UnitTemperature {
        return isCelsius ? .celsius : .fahrenheit
    }
}
