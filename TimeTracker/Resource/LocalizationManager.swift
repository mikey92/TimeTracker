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
    
    static var isJapanese: Bool {
        return Locale.current.languageCode == "ja"
    }

    static var isSimplifiedChinese: Bool {
        // 언어 코드가 zh이고, 지역이 CN, SG 등인 경우
        return Locale.current.identifier.contains("zh-Hans")
            || Locale.current.languageCode == "zh" && (Locale.current.regionCode == "CN" || Locale.current.regionCode == "SG")
    }

    static var isTraditionalChinese: Bool {
        // 언어 코드가 zh이고, 지역이 TW, HK, MO 등인 경우
        return Locale.current.identifier.contains("zh-Hant")
            || Locale.current.languageCode == "zh" && (Locale.current.regionCode == "TW" || Locale.current.regionCode == "HK" || Locale.current.regionCode == "MO")
    }

    static var isChinese: Bool {
        return isSimplifiedChinese || isTraditionalChinese
    }
}
