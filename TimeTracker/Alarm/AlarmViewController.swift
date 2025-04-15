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
    
    var city: City! // 전달받은 도시 정보
    
    private let titleLabel = UILabel()
    private let datePicker = UIDatePicker()
    private let saveButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "알람 설정"
        
        setupUI()
        requestNotificationPermission()
    }
    
    private func setupUI() {
        titleLabel.text = "\(city.name)의 알람 시간"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        view.addSubview(datePicker)
        view.addSubview(saveButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.left.right.equalToSuperview().inset(24)
        }
        
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }
        
        if let timeZone = TimeZone(identifier: city.timeZoneIdentifier) {
            datePicker.timeZone = timeZone
        }
        datePicker.datePickerMode = .time
        
        saveButton.setTitle("알람 저장", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            print("알림 권한: \(granted)")
        }
    }

    @objc private func saveButtonTapped() {
        scheduleNotification()
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "\(city.name) 알람"
        content.body = "\(city.name)의 알람 시간입니다!"
        content.sound = .default

        var calendar = Calendar.current
        if let timeZone = TimeZone(identifier: city.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }

        let components = calendar.dateComponents([.hour, .minute], from: datePicker.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "alarm_\(city.name)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("알람 등록 실패: \(error)")
                } else {
                    let alert = UIAlertController(title: "알람 등록됨", message: "\(self?.city.name ?? "") 기준으로 알람이 저장되었습니다.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
}
