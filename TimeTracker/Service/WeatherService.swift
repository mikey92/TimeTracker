//
//  WeatherService.swift
//  TimeTracker
//
//  Created by Claude on 2026/02/12.
//

import Foundation

struct WeatherService {

    private static let apiKey = ""
    private static var cache: [String: (value: String, timestamp: Date)] = [:]
    private static let cacheTTL: TimeInterval = 30 * 60 // 30 minutes

    static func fetchWeather(for city: City, completion: @escaping (String) -> Void) {
        // Check cache first
        if let cached = cache[city.name],
           Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            completion(cached.value)
            return
        }

        let apiUrl = "https://api.openweathermap.org/data/2.5/weather?lat=\(city.lat)&lon=\(city.lng)&appid=\(apiKey)"

        guard let url = URL(string: apiUrl) else {
            print("Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Weather error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let main = json["main"] as? [String: Any],
                   let tempKelvin = main["temp"] as? Double {

                    let tempCelsius = tempKelvin - 273.15
                    let measurement = Measurement(value: tempCelsius, unit: UnitTemperature.celsius)
                    let convertedTemp = measurement.converted(to: TemperatureUnitManager.unit)

                    let flooredTemp = Int(floor(convertedTemp.value))
                    let formattedTemp: String
                    if TemperatureUnitManager.isCelsius {
                        formattedTemp = "\(flooredTemp)°C"
                    } else {
                        formattedTemp = "\(flooredTemp)°F"
                    }

                    DispatchQueue.main.async {
                        cache[city.name] = (value: formattedTemp, timestamp: Date())
                        completion(formattedTemp)
                    }
                }
            } catch {
                print("Weather JSON parsing error: \(error.localizedDescription)")
            }
        }

        task.resume()
    }
}
