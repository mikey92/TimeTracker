//
//  AlarmListViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 4/11/25.
//

import UIKit
import UserNotifications
import SnapKit

final class AlarmListViewController: UIViewController {
    private var alarms: [AlarmMeta] = []
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "알람 목록"
        view.backgroundColor = .systemBackground
        setupTableView()
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .label
    }
    
    @objc func addButtonTapped() {
        // 알람 추가하기
        let alarmViewController = AlarmViewController()
        navigationController?.present(alarmViewController, animated: true)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        alarms = AlarmStorage.load()
        tableView.reloadData()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AlarmCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension AlarmListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let alarm = alarms[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmCell", for: indexPath)

        let timeStr = String(format: "%02d:%02d", alarm.hour, alarm.minute)
        let repeatStr = alarm.weekdays.isEmpty ? "1회성" : "반복: \(alarm.weekdays.map { weekdaySymbol(for: $0) }.joined(separator: ", "))"
        cell.textLabel?.text = "\(alarm.cityName) - \(timeStr) (\(repeatStr))"
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        let alarm = alarms[indexPath.row]
        if editingStyle == .delete {
            // 1. Notification 제거
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id])
            // 2. 메타 데이터 삭제
            AlarmStorage.remove(id: alarm.id)
            // 3. UI 업데이트
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
