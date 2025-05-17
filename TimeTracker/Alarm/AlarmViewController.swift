//
//  AlarmViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 4/11/25.

import UIKit
import UserNotifications
import SnapKit

final class AlarmViewController: UIViewController {

    var city: City? {
        didSet {
            navigationItem.rightBarButtonItem?.isEnabled = city != nil
            cityButton.setTitle("기준 도시: \(city?.name ?? "")", for: .normal)
        }
    }
    var alarmMeta: AlarmMeta?
    weak var delegate: AlarmSettingDelegate?

    private let cityButton = UIButton(type: .system)
    private let timePicker = UIDatePicker()

    private lazy var repeatStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        return stackView
    }()

    private var selectedWeekdays: Set<Int> = [] // 일(1) ~ 토(7)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        if let meta = alarmMeta {
            configureForEdit(meta)
        }
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    private func setupUI() {
        navigationController?.navigationBar.tintColor = .label
        
        title = alarmMeta == nil ? "알람 추가" : "알람 수정"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissSelf)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveAlarm)
        )
        navigationItem.rightBarButtonItem?.isEnabled = city != nil

        cityButton.setTitle("기준 도시 선택", for: .normal)
        cityButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cityButton.contentHorizontalAlignment = .center
        cityButton.addTarget(self, action: #selector(selectCityTapped), for: .touchUpInside)
        view.addSubview(cityButton)
        cityButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }

        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.locale = Locale(identifier: "ko_KR")
        view.addSubview(timePicker)
        timePicker.snp.makeConstraints { make in
            make.top.equalTo(cityButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        let days = ["일", "월", "화", "수", "목", "금", "토"]
        for (index, day) in days.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(day, for: .normal)
            button.tag = index + 1
            button.addTarget(self, action: #selector(toggleWeekday(_:)), for: .touchUpInside)
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray3.cgColor
            repeatStack.addArrangedSubview(button)
        }

        view.addSubview(repeatStack)
        repeatStack.snp.makeConstraints { make in
            make.top.equalTo(timePicker.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(40)
        }
    }

    private func configureForEdit(_ meta: AlarmMeta) {
        city = City(name: meta.cityName, lng: "", lat: "", country: "", timeZoneIdentifier: meta.timeZoneIdentifier)
        selectedWeekdays = Set(meta.weekdays)

        if let timeZone = TimeZone(identifier: meta.timeZoneIdentifier) {
            var calendar = Calendar.current
            calendar.timeZone = timeZone

            var components = DateComponents()
            components.hour = meta.hour
            components.minute = meta.minute

            if let date = calendar.date(from: components) {
                timePicker.timeZone = timeZone
                timePicker.setDate(date, animated: false)
            }
        }

        for button in repeatStack.arrangedSubviews.compactMap({ $0 as? UIButton }) {
            let weekday = button.tag
            if selectedWeekdays.contains(weekday) {
                button.backgroundColor = .systemBlue.withAlphaComponent(0.2)
            }
        }
    }

    @objc private func selectCityTapped() {
        let citySearchVC = CitySearchViewController()
        citySearchVC.delegate = self
        citySearchVC.addingAlarm = true
        present(citySearchVC, animated: true)
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
        guard let selectedCity = city else {
            showToast(message: "기준 도시를 선택해주세요")
            return
        }
        
        let calendar: Calendar = {
            var cal = Calendar.current
            if let timeZone = TimeZone(identifier: selectedCity.timeZoneIdentifier) {
                cal.timeZone = timeZone
            }
            return cal
        }()

        let components = calendar.dateComponents([.hour, .minute], from: timePicker.date)
        guard let hour = components.hour, let minute = components.minute else {
            showToast(message: "시간을 선택해주세요")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "\(selectedCity.name) 알람"
        content.body = "\(selectedCity.name)의 알람 시간이 되었습니다!"
        content.sound = .default

        // ✅ 기존 알람 삭제
        if let oldMeta = alarmMeta {
            if oldMeta.weekdays.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [oldMeta.id])
            } else {
                let ids = oldMeta.weekdays.map { "\(oldMeta.id)_\($0)" }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
            }
        }

        // ✅ 새 알람 ID 생성
        var id = alarmMeta?.id ?? ""
        if id.isEmpty {
            id = selectedWeekdays.isEmpty ? "alarm_once_\(UUID().uuidString)" : "alarm_repeat_\(UUID().uuidString)"
        }

        if selectedWeekdays.isEmpty {
            // ✅ 1회성 알람
            var finalDate = timePicker.date
            if let timeZone = TimeZone(identifier: selectedCity.timeZoneIdentifier) {
                let pickedDate = timePicker.date
                let localOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: pickedDate))
                let targetOffset = TimeInterval(timeZone.secondsFromGMT(for: pickedDate))
                finalDate = pickedDate - (targetOffset - localOffset)
            }

            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        } else {
            // ✅ 반복 알람 (기준 도시 시간 → 로컬 시간으로 변환)
            for weekday in selectedWeekdays {
                var cityCalendar = Calendar.current
                if let timeZone = TimeZone(identifier: selectedCity.timeZoneIdentifier) {
                    cityCalendar.timeZone = timeZone
                }

                // 1. 기준 도시 기준의 요일 + 시간으로 Date 만들기
                var cityComponents = DateComponents()
                cityComponents.weekday = weekday
                cityComponents.hour = hour
                cityComponents.minute = minute

                guard let cityDate = cityCalendar.nextDate(after: Date(), matching: cityComponents, matchingPolicy: .nextTime) else {
                    continue
                }

                // 2. 해당 Date를 디바이스 시간대로 변환한 DateComponents 만들기
                let localComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: cityDate)

                // 3. 트리거 및 요청 생성
                let trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "\(id)_\(weekday)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }

        // ✅ AlarmMeta 갱신 및 저장
        let meta = AlarmMeta(
            id: id,
            cityName: selectedCity.name,
            timeZoneIdentifier: selectedCity.timeZoneIdentifier,
            hour: hour,
            minute: minute,
            weekdays: selectedWeekdays.sorted(),
            isOn: true
        )

        if alarmMeta != nil {
            AlarmStorage.update(meta)
        } else {
            AlarmStorage.add(meta)
        }

        showAlert("알람이 저장되었습니다.") { [weak self] in
            self?.delegate?.passAlarmMetaInfo(alarm: meta)
            self?.dismiss(animated: true)
        }
    }

    private func showAlert(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "확인", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}

extension AlarmViewController: CitySearchDelegate {
    func passSelectedCity(didSelectCity selectedCity: City) {
        self.city = selectedCity
    }

    func passSelectedCity(didSelectCity city: City, for type: CitySelectionType) {}
}

protocol AlarmSettingDelegate: AnyObject {
    func passAlarmMetaInfo(alarm: AlarmMeta)
}
