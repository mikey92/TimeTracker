//
//  AlarmListViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 4/11/25.
//

import UIKit
import UserNotifications
import SnapKit
import GoogleMobileAds

final class AlarmListViewController: BaseAdViewController {
    private var alarms: [AlarmMeta] = [] {
        didSet {
            showEmptyLabel(alarms.isEmpty)
        }
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AlarmTableViewCell.self, forCellReuseIdentifier: Const.cellName)
        return tableView
    }()
    
    lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "알람을 추가해주세요"
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        return label
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        AlarmStorage.deactivateExpiredOneTimeAlarms()
        alarms = AlarmStorage.load()
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
        setupNavigationBar()
        setupAdBanner()
    }

    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .label
    }
    
    private func showEmptyLabel(_ value: Bool) {
        tableView.isHidden = value
        
        if value {
            view.addSubview(emptyLabel)
            emptyLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        } else {
            emptyLabel.removeFromSuperview()
        }
    }
    
    @objc func addButtonTapped() {
        // 알람 추가하기
        presentAlarmViewVC()
    }
    
    func presentAlarmViewVC(withAlaram: AlarmMeta? = nil) {
        let alarmViewController = AlarmViewController()
        alarmViewController.alarmMeta = withAlaram
        alarmViewController.delegate = self
        let navVC = UINavigationController(rootViewController: alarmViewController)
        navVC.modalPresentationStyle = .automatic
        present(navVC, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        alarms = AlarmStorage.load()
        tableView.reloadData()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-50)
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AlarmCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .automatic
    }
}

extension AlarmListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AlarmTableViewCell.identifier, for: indexPath) as? AlarmTableViewCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        let alarm = alarms[indexPath.row]

        // ✅ 도시 타임존 기준으로 오전/오후 시각 생성
        var timeStr = ""
        if let timeZone = TimeZone(identifier: alarm.timeZoneIdentifier) {
            var calendar = Calendar.current
            calendar.timeZone = timeZone

            var components = DateComponents()
            components.hour = alarm.hour
            components.minute = alarm.minute

            if let date = calendar.date(from: components) {
                let formatter = DateFormatter()
                formatter.timeZone = timeZone
                formatter.locale = Locale(identifier: "ko_KR")
                formatter.dateFormat = "a h:mm" // 오전/오후 1:30
                timeStr = formatter.string(from: date)
            }
        }

        let repeatStr = alarm.weekdays.isEmpty
            ? "1회성"
            : "반복: \(alarm.weekdays.map { weekdaySymbol(for: $0) }.joined(separator: ", "))"

        cell.configure(time: timeStr,
                       city: "기준 도시: \(alarm.cityNameKR) (\(alarm.cityName))",
                       description: repeatStr,
                       isOn: alarm.isOn)

        cell.switchChanged = { [weak self] isOn in
            guard let self else { return }

            let alarm = self.alarms[indexPath.row]
            AlarmStorage.update(id: alarm.id, isOn: isOn) { isNextDay in
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }

                    if isOn && isNextDay {
                        self.showToast(message: "선택한 시간이 이미 지나\n알람이 내일로 설정되었어요")
                    }

                    self.alarms = AlarmStorage.load()
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alarm = alarms[indexPath.row]
        presentAlarmViewVC(withAlaram: alarm)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alarm = alarms[indexPath.row]
            
            AlarmStorage.remove(id: alarm.id) // ✅ Notification + 메타 데이터 한 번에 제거
            
            alarms.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    private func weekdaySymbol(for weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.shortWeekdaySymbols[(weekday - 1) % 7]
    }
}

extension AlarmListViewController {
    enum Const {
        static let cellName = "AlarmTableViewCell"
    }
}

extension AlarmListViewController: AlarmSettingDelegate {
    func passAlarmMetaInfo(alarm: AlarmMeta) {
        alarms = AlarmStorage.load()
        tableView.reloadData()
    }
}
