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
}

extension City {
    func saveCityToUserDefaults() -> Bool {
        let defaults = UserDefaults.standard

        do {
            // 기존 저장된 배열 가져오기
            var cities = City.loadCitiesFromUserDefaults()

            // 새로운 City 추가
            cities.append(self)

            // City 배열을 JSON 데이터로 인코딩
            let data = try JSONEncoder().encode(cities)

            // UserDefaults에 저장
            defaults.set(data, forKey: "cities")
            print("City saved successfully!")
            return true // 저장 성공
        } catch {
            print("Failed to save city: \(error)")
            return false // 저장 실패
        }
    }
    
    static func loadCitiesFromUserDefaults() -> [City] {
        let defaults = UserDefaults.standard

        guard let data = defaults.data(forKey: "cities") else {
            print("No cities found in UserDefaults.")
            return [] // 데이터가 없으면 빈 배열 반환
        }

        do {
            // JSON 데이터를 City 배열로 디코딩
            let cities = try JSONDecoder().decode([City].self, from: data)
            print("Cities loaded successfully!")
            return cities
        } catch {
            print("Failed to load cities: \(error)")
            return [] // 실패 시 빈 배열 반환
        }
    }
    
    func deleteCityFromUserDefaults(cityName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let defaults = UserDefaults.standard

        // 기존 City 배열 로드
        var cities = City.loadCitiesFromUserDefaults()

        // 이름이 일치하지 않는 City만 남기기
        cities = cities.filter { $0.name != cityName }

        do {
            // 갱신된 City 배열 저장
            let data = try JSONEncoder().encode(cities)
            defaults.set(data, forKey: "cities")
            print("City deleted successfully!")
            completion(.success(())) // 성공 시 호출
        } catch {
            print("Failed to delete city: \(error)")
            completion(.failure(error)) // 실패 시 호출
        }
    }
    
    func deleteAllCitiesFromUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "cities")
        print("All cities deleted successfully!")
    }
}

extension City: Equatable {
    
}
