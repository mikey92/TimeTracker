//
//  City.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 2024/12/22.
//

import Foundation

struct City: Codable {
    let name: String        // 도시 이름
    let lng: String         // 경도
    let lat: String         // 위도
    let country: String     // 국가 이름
    let timeZoneIdentifier: String
    let name_kr: String
    let country_kr: String
}

extension City {
    func saveCityToUserDefaults() -> Bool {
        return CityRepository.add(self)
    }

    static func saveCityListToUserDefaults(_ cities: [City]) -> Bool {
        return CityRepository.saveAll(cities)
    }

    static func loadCitiesFromUserDefaults() -> [City] {
        return CityRepository.loadAll()
    }

    func deleteCityFromUserDefaults(cityName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        CityRepository.remove(cityName: cityName, completion: completion)
    }

    func deleteAllCitiesFromUserDefaults() {
        CityRepository.removeAll()
    }
}

extension City: Equatable {
    static func == (lhs: City, rhs: City) -> Bool {
        return lhs.name == rhs.name && lhs.timeZoneIdentifier == rhs.timeZoneIdentifier
    }
}

extension City {
    var displayName: String {
        if LocalizationManager.isKorean {
            return "\(name_kr) (\(name))"
        }
        return name
    }
}
