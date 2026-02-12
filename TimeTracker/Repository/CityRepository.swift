//
//  CityRepository.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 2024/12/22.
//

import Foundation

struct CityRepository {

    private static let key = "cities"

    // MARK: - Read

    static func loadAll() -> [City] {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: key) else {
            return []
        }
        do {
            return try JSONDecoder().decode([City].self, from: data)
        } catch {
            print("Failed to load cities: \(error)")
            return []
        }
    }

    // MARK: - Write

    @discardableResult
    static func add(_ city: City) -> Bool {
        var cities = loadAll()
        if cities.contains(city) {
            return false
        }
        cities.append(city)
        return saveAll(cities)
    }

    @discardableResult
    static func saveAll(_ cities: [City]) -> Bool {
        do {
            let data = try JSONEncoder().encode(cities)
            UserDefaults.standard.set(data, forKey: key)
            return true
        } catch {
            print("Failed to save cities: \(error)")
            return false
        }
    }

    // MARK: - Delete

    static func remove(cityName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var cities = loadAll()
        cities = cities.filter { $0.name != cityName }
        do {
            let data = try JSONEncoder().encode(cities)
            UserDefaults.standard.set(data, forKey: key)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    static func removeAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
