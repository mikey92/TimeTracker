//
//  AlarmViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 4/11/25.
//

import UIKit
import UserNotifications
import SnapKit

final class AlarmViewController: UIViewController {
    
    var city: City!
    
    var alarmMeta: AlarmMeta! // 수정 모드용 알람 정보

    private let cityLabel = UILabel()
    private let timePicker = UIDatePicker()
    private let repeatStack = UIStackView()
    private let saveButton = UIButton(type: .system)

    private var selectedWeekdays: Set<Int> = [] // 일(1) ~ 토(7)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "알람 추가"
        city = City(name: "New York", lng: "-74.0060", lat: "40.7128", country: "United States", timeZoneIdentifier: "America/New_York")
        setupUI()
    }

    private func setupUI() {
        cityLabel.text = "기준 도시: \(city.name)"
        cityLabel.textAlignment = .center
        cityLabel.font = .boldSystemFont(ofSize: 18)
        view.addSubview(cityLabel)

        cityLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.right.equalToSuperview().inset(24)
        }

        // 시간 선택
        timePicker.datePickerMode = .time
        timePicker.timeZone = TimeZone(identifier: city.timeZoneIdentifier)
        view.addSubview(timePicker)

        timePicker.snp.makeConstraints { make in
            make.top.equalTo(cityLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        // 반복 요일 선택
        repeatStack.axis = .horizontal
        repeatStack.spacing = 8
        repeatStack.distribution = .fillEqually
        view.addSubview(repeatStack)

        let days = ["일", "월", "화", "수", "목", "금", "토"]
        for (index, day) in days.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(day, for: .normal)
            button.tag = index + 1 // 일: 1, 월: 2 ...
            button.addTarget(self, action: #selector(toggleWeekday(_:)), for: .touchUpInside)
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray3.cgColor
            repeatStack.addArrangedSubview(button)
        }

        repeatStack.snp.makeConstraints { make in
            make.top.equalTo(timePicker.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(40)
        }

        // 저장 버튼
        saveButton.setTitle("저장", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        saveButton.addTarget(self, action: #selector(saveAlarm), for: .touchUpInside)
        view.addSubview(saveButton)

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(repeatStack.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }
    }
    
    private func configureFromMeta() {
        guard let meta = alarmMeta else { return }
        
        if let timeZone = TimeZone(identifier: meta.timeZoneIdentifier) {
            var components = DateComponents()
            components.hour = meta.hour
            components.minute = meta.minute
            
            let calendar = Calendar.current
            if let date = calendar.date(from: components) {
                // datePicker에 시간 설정
//                datePicker.setDate(date, animated: false)
//                datePicker.timeZone = timeZone
            }
            
            cityLabel.text = meta.cityName
            selectedWeekdays = Set(meta.weekdays)
            
            // 요일 버튼 상태도 업데이트 (필요 시 따로 구현)
        }
    }
    
    @objc private func toggleWeekday(_ sender: UIButton) {
        let weekday = sender.tag
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
            sender.backgroundColor = .clear
        } else {
            selectedWeekdays.insert(weekday)
            sender.backgroundColor = .systemBlue.withAlphaComponent(0.2)
        }
    }

    @objc private func saveAlarm() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: timePicker.date)

        var content = UNMutableNotificationContent()
        content.title = "\(city.name) 알람"
        content.body = "\(city.name)의 알람 시간이 되었습니다!"
        content.sound = .default

        if selectedWeekdays.isEmpty {
            // ✅ 1회성 알람 처리
            let triggerDate = timePicker.date // 기준 도시 시간대 반영 필요
            let triggerCalendar = Calendar.current
            var finalDate = triggerDate
            if let timeZone = TimeZone(identifier: city.timeZoneIdentifier) {
                let now = Date()
                let localNowOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: now))
                let targetOffset = TimeInterval(timeZone.secondsFromGMT(for: now))
                let delta = targetOffset - localNowOffset
                finalDate = triggerDate - delta // 보정
            }

            let triggerComponents = triggerCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            let id = "alarm_once_\(UUID().uuidString)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("1회성 알람 등록 실패: \(error)")
                }
            }

        } else {
            // ✅ 반복 알람 처리 (요일별)
            for weekday in selectedWeekdays {
                var dateComponents = DateComponents()
                dateComponents.weekday = weekday
                dateComponents.hour = components.hour
                dateComponents.minute = components.minute

                var triggerCalendar = Calendar.current
                if let timeZone = TimeZone(identifier: city.timeZoneIdentifier) {
                    triggerCalendar.timeZone = timeZone
                }

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

                let id = "alarm_repeat_\(city.name)_\(weekday)_\(components.hour ?? 0)_\(components.minute ?? 0)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("반복 알람 등록 실패: \(error)")
                    }
                }
            }
        }

        showAlert("알람이 등록되었습니다.") {
            self.dismiss(animated: true)
        }
    }

    private func showAlert(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "확인", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}
