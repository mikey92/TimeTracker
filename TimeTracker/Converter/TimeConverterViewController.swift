//
//  TimeConverterViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 4/11/25.
//

import UIKit
import SnapKit
import GoogleMobileAds

final class TimeConverterViewController: BaseAdViewController {
    
    private let resultContainerView = UIView()
    private let datePicker = UIDatePicker()
    private let resultLabel = UILabel()

    private let convertButton = UIButton(type: .system)

    private let baseCityButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(String(localized: "select_base_city"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        return button
    }()
    
    private let targetCityButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(String(localized: "select_target_city"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        return button
    }()
    
    private var baseCity: City?
    private var targetCity: City?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAdBanner()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 1. 서브뷰 추가
        [resultContainerView, baseCityButton, datePicker, targetCityButton, convertButton].forEach {
            view.addSubview($0)
        }
        
        // 2. 스타일 설정
        datePicker.datePickerMode = .dateAndTime
        
        baseCityButton.addTarget(self, action: #selector(baseCityTapped), for: .touchUpInside)
        targetCityButton.addTarget(self, action: #selector(targetCityTapped), for: .touchUpInside)
        
        convertButton.setTitle(String(localized: "convert_time"), for: .normal)
        convertButton.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)
        
        // 3. 제약 설정
        resultContainerView.isHidden = true
        resultContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.left.right.equalToSuperview().inset(24)
        }
        
        baseCityButton.snp.makeConstraints { make in
            make.bottom.equalTo(datePicker.snp.top).offset(-24)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }
        
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(baseCityButton.snp.bottom).offset(16)
            make.centerX.centerY.equalToSuperview()
        }
        
        targetCityButton.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }
        
        convertButton.backgroundColor = UIColor.systemGray6
        convertButton.layer.cornerRadius = 12
        convertButton.layer.masksToBounds = true
        convertButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-82)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
            make.left.right.equalToSuperview().inset(24)
        }
        
        resultLabel.text = ""
        resultLabel.font = .systemFont(ofSize: 16, weight: .regular)
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        
        resultContainerView.addSubview(resultLabel)
        resultLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    @objc private func baseCityTapped() {
        let vc = CitySearchViewController()
        vc.delegate = self
        vc.selectionType = .base
        present(vc, animated: true)
    }
    
    @objc private func targetCityTapped() {
        let vc = CitySearchViewController()
        vc.delegate = self
        vc.selectionType = .target
        present(vc, animated: true)
    }
    
    @objc private func convertTapped() {
        guard let baseCity = baseCity,
              let targetCity = targetCity,
              let baseTZ = TimeZone(identifier: baseCity.timeZoneIdentifier),
              let targetTZ = TimeZone(identifier: targetCity.timeZoneIdentifier)
        else {
            resultContainerView.isHidden = false
            resultLabel.text = String(localized: "select_city_prompt")
            return
        }

        let pickedDate = datePicker.date

        // ✅ 타겟 도시 기준 시간으로 출력
        let formatter = DateFormatter()
        formatter.timeZone = targetTZ
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy.MM.dd a h:mm"
        let formatted = formatter.string(from: pickedDate)

        // ✅ 시차 계산
        let pickedBaseOffset = baseTZ.secondsFromGMT(for: pickedDate)
        let pickedTargetOffset = targetTZ.secondsFromGMT(for: pickedDate)
        let hourDifference = (pickedTargetOffset - pickedBaseOffset) / 3600

        // ✅ 날짜 차이 계산
        let baseDay = Calendar.current.startOfDay(for: pickedDate)
        let targetDay = Calendar.current.startOfDay(for: pickedDate.addingTimeInterval(TimeInterval(hourDifference * 3600)))
        let dayDiff = Calendar.current.dateComponents([.day], from: baseDay, to: targetDay).day ?? 0

        // ✅ 차이 텍스트 구성
        var diffText = ""
        if hourDifference == 0 {
            diffText = "(\(String(localized: "same_timezone")))"
        } else if hourDifference > 0 {
            diffText = "(+\(hourDifference)\(String(localized: "hours")))"
        } else {
            diffText = "(\(hourDifference)\(String(localized: "hours")))"
        }

        if dayDiff == 1 {
            diffText += ", \(String(localized: "next_day"))"
        } else if dayDiff == -1 {
            diffText += ", \(String(localized: "previous_day"))"
        }

        // ✅ 결과 표시
        resultContainerView.isHidden = false
        if LocalizationManager.isKorean {
            resultLabel.text = "\(targetCity.name_kr)(\(targetCity.name))의 시간:\n\(formatted)\n\(diffText)"
        } else if LocalizationManager.isJapanese {
            resultLabel.text = "\(targetCity.name)の時間：\n\(formatted)\n\(diffText)"
        } else if LocalizationManager.isSimplifiedChinese {
            resultLabel.text = "\(targetCity.name)的时间：\n\(formatted)\n\(diffText)"
        } else {
            resultLabel.text = "Time in \(targetCity.name):\n\(formatted)\n\(diffText)"
        }
    }
}

extension TimeConverterViewController: CitySearchDelegate {
    func passSelectedCity(didSelectCity city: City, for type: CitySelectionType) {
        switch type {
        case .base:
            baseCity = city
            if LocalizationManager.isKorean {
                baseCityButton.setTitle("\(String(localized: "base_city_label")): \(city.name_kr)(\(city.name))", for: .normal)
            } else {
                baseCityButton.setTitle("\(String(localized: "base_city_label")): \(city.name)", for: .normal)
            }
        case .target:
            targetCity = city
            if LocalizationManager.isKorean {
                targetCityButton.setTitle("\(String(localized: "target_city_label")): \(city.name_kr)(\(city.name))", for: .normal)
            } else {
                targetCityButton.setTitle("\(String(localized: "target_city_label")): \(city.name)", for: .normal)
            }
        case .none:
            break
        }
        
        // datePicker 타임존도 변경
        guard let baseCity = baseCity,
              let baseTZ = TimeZone(identifier: baseCity.timeZoneIdentifier) else { return }

        datePicker.timeZone = baseTZ
    }
    
    func passSelectedCity(didSelectCity city: City) {
        // nothing to do
    }
}

enum CitySelectionType {
    case none
    case base
    case target
}
