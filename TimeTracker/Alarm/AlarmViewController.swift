//  AlarmViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 4/11/25.

import UIKit
import SnapKit

final class AlarmViewController: UIViewController {

    var city: City? {
        didSet {
            navigationItem.rightBarButtonItem?.isEnabled = city != nil
            if let city = city {
                if LocalizationManager.isKorean {
                    cityButton.setTitle("\(String(localized: "base_city_label")): \(city.name_kr)(\(city.name))", for: .normal)
                } else {
                    cityButton.setTitle("\(String(localized: "base_city_label")): \(city.name)", for: .normal)
                }
            }
            if let timeZone = city?.timeZoneIdentifier {
                timePicker.timeZone = TimeZone(identifier: timeZone)
            }
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

        title = alarmMeta == nil ? String(localized: "addAlarm") : String(localized: "editAlarm")

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

        cityButton.setTitle(String(localized: "select_base_city"), for: .normal)
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
        timePicker.locale = Locale.current
        view.addSubview(timePicker)
        timePicker.snp.makeConstraints { make in
            make.top.equalTo(cityButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        let days: [String] = {
            if LocalizationManager.isKorean {
                return ["일", "월", "화", "수", "목", "금", "토"]
            } else if LocalizationManager.isJapanese {
                return ["日", "月", "火", "水", "木", "金", "土"]
            } else if LocalizationManager.isChinese {
                return ["日", "一", "二", "三", "四", "五", "六"]
            } else {
                return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            }
        }()
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
        city = City(name: meta.cityName,
                    lng: "",
                    lat: "",
                    country: "",
                    timeZoneIdentifier: meta.timeZoneIdentifier,
                    name_kr: meta.cityNameKR,
                    country_kr: "")
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
        guard let selectedCity = city,
              let timeZone = TimeZone(identifier: selectedCity.timeZoneIdentifier) else {
            showToast(message: String(localized: "select_base_city_msg"))
            return
        }

        // 기준 도시 시간대 기준으로 선택된 시간 추출
        var cityCalendar = Calendar.current
        cityCalendar.timeZone = timeZone

        let pickedDate = timePicker.date
        let pickedComponents = cityCalendar.dateComponents([.hour, .minute], from: pickedDate)
        guard let hour = pickedComponents.hour, let minute = pickedComponents.minute else {
            showToast(message: String(localized: "select_time_msg"))
            return
        }

        let content = NotificationService.makeAlarmContent(
            cityName: selectedCity.name,
            cityNameKR: selectedCity.name_kr,
            hour: hour,
            minute: minute
        )

        if let oldMeta = alarmMeta {
            AlarmStorage.remove(id: oldMeta.id)
        }

        let id = alarmMeta?.id ?? UUID().uuidString

        if selectedWeekdays.isEmpty {
            NotificationService.scheduleOneTimeAlarm(
                id: id,
                content: content,
                hour: hour,
                minute: minute,
                timeZoneIdentifier: selectedCity.timeZoneIdentifier
            )
        } else {
            NotificationService.scheduleRepeatingAlarm(
                id: id,
                content: content,
                hour: hour,
                minute: minute,
                weekdays: selectedWeekdays.sorted(),
                timeZoneIdentifier: selectedCity.timeZoneIdentifier
            )
        }

        let meta = AlarmMeta(
            id: id,
            cityName: selectedCity.name,
            cityNameKR: selectedCity.name_kr,
            timeZoneIdentifier: selectedCity.timeZoneIdentifier,
            hour: hour,
            minute: minute,
            weekdays: selectedWeekdays.sorted(),
            isOn: true
        )

        AlarmStorage.update(meta)

        showAlert(String(localized: "alarm_saved")) { [weak self] in
            self?.delegate?.passAlarmMetaInfo(alarm: meta)
            self?.dismiss(animated: true)
        }
    }

    private func showAlert(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: String(localized: "confirm"), style: .default) { _ in completion?() })
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
