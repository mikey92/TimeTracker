//
//  TimeConverterViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 4/11/25.
//

import UIKit
import SnapKit

final class TimeConverterViewController: UIViewController {
    
    private let datePicker = UIDatePicker()
    private let dividerView = UIView()
    
    private let convertButton = UIButton(type: .system)
    private let resultContainerView = UIView()
    private let resultLabel = UILabel()

    private let baseCityButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("기준 도시 선택", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        return button
    }()

    private let targetCityButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("변환 도시 선택", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        return button
    }()

    private var baseCity: City?
    private var targetCity: City?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "시간 변환기"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        // 1. 서브뷰 추가
        [resultContainerView, baseCityButton, datePicker, targetCityButton, dividerView, convertButton].forEach {
            view.addSubview($0)
        }

        // 2. 스타일 설정
        datePicker.datePickerMode = .dateAndTime

        baseCityButton.addTarget(self, action: #selector(baseCityTapped), for: .touchUpInside)
        targetCityButton.addTarget(self, action: #selector(targetCityTapped), for: .touchUpInside)

        convertButton.setTitle("변환하기", for: .normal)
        convertButton.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)

        // 3. 제약 설정
        resultContainerView.backgroundColor = UIColor.systemGray6
        resultContainerView.layer.cornerRadius = 12
        resultContainerView.layer.masksToBounds = true

        resultContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.left.right.equalToSuperview().inset(24)
        }

        baseCityButton.snp.makeConstraints { make in
            make.top.equalTo(resultContainerView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }

        datePicker.snp.makeConstraints { make in
            make.top.equalTo(baseCityButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        targetCityButton.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }

        dividerView.backgroundColor = .systemGray4
        dividerView.snp.makeConstraints { make in
            make.top.equalTo(targetCityButton.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(1)
        }

        convertButton.backgroundColor = UIColor.systemGray6
        convertButton.layer.cornerRadius = 12
        convertButton.layer.masksToBounds = true
        convertButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
            make.left.right.equalToSuperview().inset(48)
        }

        resultLabel.text = ""
        resultLabel.font = .systemFont(ofSize: 20, weight: .regular)
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
        let baseDate = datePicker.date

        guard let baseCity = baseCity,
                let targetCity = targetCity,
            let baseTZ = TimeZone(identifier: baseCity.timeZoneIdentifier),
            let targetTZ = TimeZone(identifier: targetCity.timeZoneIdentifier)
        else {
            resultLabel.text = "타임존 정보가 잘못되었습니다."
            return
        }

        // 1. 기준 도시 시간 → UTC
        let baseOffset = TimeInterval(baseTZ.secondsFromGMT(for: baseDate))
        let utcDate = baseDate - baseOffset

        // 2. UTC → 대상 도시 시간
        let targetOffset = TimeInterval(targetTZ.secondsFromGMT(for: baseDate))
        let targetDate = utcDate + targetOffset

        // 3. 포맷 출력
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = targetTZ
        let formatted = formatter.string(from: targetDate)

        // 4. 시차 계산 (단위: 시간)
        let hourDifference = (targetTZ.secondsFromGMT(for: baseDate) - baseTZ.secondsFromGMT(for: baseDate)) / 3600

        // 5. 날짜 차이 계산
        let baseDay = Calendar.current.startOfDay(for: baseDate)
        let targetDay = Calendar.current.startOfDay(for: targetDate)
        let dayDiff = Calendar.current.dateComponents([.day], from: baseDay, to: targetDay).day ?? 0

        // 6. 시차 텍스트 만들기
        var diffText = ""
        if hourDifference == 0 {
            diffText = "(동일 시간대)"
        } else if hourDifference > 0 {
            diffText = "(+\(hourDifference)시간)"
        } else {
            diffText = "(\(hourDifference)시간)"
        }

        if dayDiff == 1 {
            diffText += ", 하루 뒤"
        } else if dayDiff == -1 {
            diffText += ", 하루 전"
        }

        resultLabel.text = "\(targetCity.name)의 시간:\n\(formatted)\n\(diffText)"
    }
}

extension TimeConverterViewController: CitySearchDelegate {
    func passSelectedCity(didSelectCity city: City) {
        // nothing to do
    }
    
    func citySearch(_ controller: CitySearchViewController, didSelect city: City, for type: CitySelectionType) {
        switch type {
        case .base:
            baseCity = city
            baseCityButton.setTitle("기준 도시: \(city.name)", for: .normal)
        case .target:
            targetCity = city
            targetCityButton.setTitle("변환 도시: \(city.name)", for: .normal)
        }
        
        // datePicker 타임존도 변경
        guard let baseCity = baseCity,
              let baseTZ = TimeZone(identifier: baseCity.timeZoneIdentifier) else { return }

        datePicker.timeZone = baseTZ
    }
}

enum CitySelectionType {
    case base
    case target
}
