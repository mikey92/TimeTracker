//
//  CitySearchViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 2024/12/22.
//

import UIKit
import SnapKit

class CitySearchViewController: UIViewController {

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SearchCityTableViewCell.self, forCellReuseIdentifier: Const.cellName)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = NSLocalizedString("searchCity", comment: "search bar placeholder message")
        return searchBar
    }()
    
    private var cityList: [City] = []
    private var filteredCityList: [City] = []
    private var isStatusBarHidden = false // 상태 바 숨김 여부를 관리
    var selectionType: CitySelectionType = .none
    var addingAlarm: Bool? = false
    weak var delegate: CitySearchDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupTapGestureToDismissKeyboard()
        registerNotifications()
        setupSearchBar()
        setupTableView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadData()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
    }
    
    private func setupTapGestureToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardFrame.cgRectValue.height
            
            // 키보드 높이만큼 tableView의 하단 inset을 추가
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            tableView.scrollIndicatorInsets = tableView.contentInset
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        // 키보드가 내려가면 원래 상태로 복구
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
    }
    
    private func setupSearchBar() {
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
        }
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func loadData() {
        if let path = Bundle.main.path(forResource: "city_list", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                cityList = try JSONDecoder().decode([City].self, from: data)
                tableView.reloadData()
            } catch {
                print("Error loading JSON: \(error)")
            }
        }
    }
}

extension CitySearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text?.isEmpty == true {
            return cityList.count
        } else {
            return filteredCityList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Const.cellName, for: indexPath)
        let city = searchBar.text?.isEmpty == true ? cityList[indexPath.row] : filteredCityList[indexPath.row]
        cell.textLabel?.text = "\(city.name_kr) (\(city.name))"
        cell.detailTextLabel?.text = "\(city.country_kr) (\(city.country))"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let city = searchBar.text?.isEmpty == true ? cityList[indexPath.row] : filteredCityList[indexPath.row]
        print("\(city.name) was selected")
        if addingAlarm == true {
            delegate?.passSelectedCity(didSelectCity: city)
        } else if selectionType != .none {
            delegate?.passSelectedCity(didSelectCity: city, for: selectionType)
        } else {
            if city.saveCityToUserDefaults() {
                showToast(message: "저장 완료")
                delegate?.passSelectedCity(didSelectCity: city)
            } else {
                showToast(message: "저장 실패")
            }
        }
        self.dismiss(animated: true)
    }
}

extension CitySearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredCityList = cityList
        } else {
            filteredCityList = cityList.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.country.lowercased().contains(searchText.lowercased()) ||
                $0.country_kr.contains(searchText) ||
                $0.name_kr.contains(searchText)
            }
        }
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension CitySearchViewController {
    enum Const {
        static let cellName = "Cell"
    }
}

protocol CitySearchDelegate: AnyObject {
    func passSelectedCity(didSelectCity city: City)
    func passSelectedCity(didSelectCity city: City, for type: CitySelectionType)
}
