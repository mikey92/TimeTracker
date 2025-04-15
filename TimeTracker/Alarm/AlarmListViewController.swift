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

    private let tableView = UITableView()
    private var alarms: [UNNotificationRequest] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "알람 목록"
        view.backgroundColor = .systemBackground
        setupTableView()
        setupNavigationBar()
        loadAlarms()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAlarms()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AlarmCell")
    }
    
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .black
    }
    
    @objc func addButtonTapped() {
        // 알람 추가하기
    }

    private func loadAlarms() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.alarms = requests.filter { $0.identifier.hasPrefix("alarm_") }
                self?.tableView.reloadData()
            }
        }
    }
}

extension AlarmListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let alarm = alarms[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmCell", for: indexPath)
        cell.textLabel?.text = alarm.content.title
        cell.detailTextLabel?.text = alarm.content.body
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let identifier = alarms[indexPath.row].identifier
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            alarms.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
