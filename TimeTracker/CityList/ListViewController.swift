//
//  ListViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 2024/12/22.
//

import UIKit
import SnapKit
import UserNotifications
import GoogleMobileAds
import WidgetKit

class ListViewController: BaseAdViewController {
    private var timer: Timer?
        
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CityTableViewCell.self, forCellReuseIdentifier: Const.cellName)
        return tableView
    }()
    
    lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "select_city_prompt")
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()
    
    private var cityList: [City] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCityList()
        setupNavigationBar()
        setupView()
        setupTableView()
        startClockTimer()
        requestNotificationPermission()
        setupAdBanner()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appWillEnterForeground() {
        startClockTimer() // 현재 구현된 타이머 재시작 메서드 재사용
        updateVisibleCellTimes() // 혹시 타이머 시작 전에 한 번 즉시 갱신하고 싶다면
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
    }
    
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        addButton.accessibilityLabel = "Add city"
        addButton.accessibilityHint = "Opens city search to add a new city"
        navigationItem.rightBarButtonItem = addButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: String(localized: "edit"),
            style: .plain,
            target: self,
            action: #selector(editTapped)
        )
        navigationItem.leftBarButtonItem?.accessibilityLabel = "Edit"
        navigationItem.leftBarButtonItem?.accessibilityHint = "Toggle edit mode for reordering or deleting cities"
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .label
    }
    
    @objc private func editTapped() {
        isEditing.toggle()
        
    }
        
    @objc func addButtonTapped() {
        let citySearchViewController = CitySearchViewController()
        citySearchViewController.delegate = self
        navigationController?.present(citySearchViewController, animated: true)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        guard cityList.isEmpty == false else {
            showToast(message: String(localized: "no_data_to_update"))
            return
        }
        
        super.setEditing(editing, animated: animated)

        // 편집 모드가 활성화되면 추가 작업 수행
        if editing {
            print("Editing mode enabled")
            tableView.visibleCells.forEach { cell in
                if let customCell = cell as? CityTableViewCell {
                    customCell.rightHorizontalStackView.isHidden = true
                    customCell.horizontalContainerStackViewLeftMargin?.update(offset: 60)
                }
            }
        } else {
            print("Editing mode disabled")
            tableView.visibleCells.forEach { cell in
                if let customCell = cell as? CityTableViewCell {
                    customCell.rightHorizontalStackView.isHidden = false
                    customCell.horizontalContainerStackViewLeftMargin?.update(offset: 16)
                }
            }
        }
        // 테이블 뷰의 편집 상태를 업데이트
        tableView.setEditing(editing, animated: animated)
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-50)
        }
    }
    
    private func startClockTimer() {
        timer?.invalidate()

        let now = Date()
        let calendar = Calendar.current
        let seconds = calendar.component(.second, from: now)
        let delay = Double(60 - seconds)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.updateVisibleCellTimes()

            let newTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                self?.updateVisibleCellTimes()
            }
            RunLoop.main.add(newTimer, forMode: .common)
            self?.timer = newTimer
        }
    }

    private func updateVisibleCellTimes() {
        for cell in tableView.visibleCells {
            guard let indexPath = tableView.indexPath(for: cell),
                  let customCell = cell as? CityTableViewCell else { continue }
            let city = cityList[indexPath.row]
            customCell.updateTime(for: city)
        }
    }
    
    private func loadCityList() {
        cityList = City.loadCitiesFromUserDefaults()
        tableView.reloadData()
        showEmptyLabel(cityList.isEmpty)
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
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 알림 권한 허용됨")
            } else {
                print("❌ 알림 권한 거부됨")
            }
        }
    }
}

extension ListViewController: CitySearchDelegate {
    func passSelectedCity(didSelectCity city: City, for type: CitySelectionType) {
        // nothing to do
    }

    func passSelectedCity(didSelectCity city: City) {
        loadCityList()
        updateTop3CitiesForWidget()
    }
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cityList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Const.cellName, for: indexPath) as? CityTableViewCell else {
            return UITableViewCell()
        }

        cell.selectionStyle = .none

        let city = cityList[indexPath.row]
        cell.configure(city: city)

        WeatherService.fetchWeather(for: city) { weather in
            if let visibleCell = tableView.cellForRow(at: indexPath) as? CityTableViewCell {
                visibleCell.weatherLabel.text = weather
            }
        }

        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCity = cityList[indexPath.row]
        print("selectedCity \(selectedCity)")
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: String(localized: "delete")) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            let city = self.cityList[indexPath.row]

            let alert = UIAlertController(
                title: String(localized: "delete_confirm_title"),
                message: city.name,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: String(localized: "cancel"), style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: String(localized: "delete"), style: .destructive) { _ in
                city.deleteCityFromUserDefaults(cityName: city.name) { [weak self] result in
                    switch result {
                    case .success:
                        guard let self = self else { return }
                        self.cityList.remove(at: indexPath.row)
                        self.showToast(message: "\(city.name) \(String(localized: "delete_success"))")
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        self.updateTop3CitiesForWidget()
                    case .failure(let error):
                        guard let self = self else { return }
                        self.showToast(message: "\(city.name) \(String(localized: "delete_failure"))")
                    }
                }
                completionHandler(true)
            })
            self.present(alert, animated: true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true // 모든 셀 이동 가능
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedCity = cityList.remove(at: sourceIndexPath.row)
        cityList.insert(movedCity, at: destinationIndexPath.row)
        
        if City.saveCityListToUserDefaults(cityList) {
            showToast(message: String(localized: "reorder_success"))
        } else {
            showToast(message: String(localized: "reorder_failure"))
        }
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        print("편집 모드가 시작됩니다: \(indexPath)")
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        print("편집 모드가 종료되었습니다.")
        
        loadCityList()
    }
}

extension ListViewController {
    func updateTop3CitiesForWidget() {
        let top3 = cityList.prefix(3)

        let formattedTop3: [[String: Any]] = top3.map { city in
            [
                "city": city.name,
                "timeZoneIdentifier": city.timeZoneIdentifier
            ]
        }

        let userDefaults = UserDefaults(suiteName: "group.com.hyerikim.TimeTracker")
        userDefaults?.set(formattedTop3, forKey: "Top3Alarms")

        WidgetCenter.shared.reloadTimelines(ofKind: "TimeTrackerWidget")
    }
}

extension ListViewController {
    enum Const {
        static let cellName = "CityTableViewCell"
    }
}
