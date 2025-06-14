//
//  LocalizationManager.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 6/14/25.
//

import Foundation

struct LocalizationManager {
    static var isKorean: Bool {
        return Locale.current.languageCode == "ko"
    }
}
