//
//  TimeConverterViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 4/11/25.
//

import UIKit
import SnapKit

final class TimeConverterViewController: UIViewController {
    
    private let baseCityLabel = UILabel()
    private let targetCityLabel = UILabel()
    private let datePicker = UIDatePicker()
    
    private let dividerView = UIView()
    
    private let convertButton = UIButton(type: .system)
    private let resultContainerView = UIView()
    private let resultLabel = UILabel()

    private var baseCity: City = City(
        name: "Seoul",
        lng: "126.9780",
        lat: "37.5665",
        country: "South Korea",
        timeZoneIdentifier: "Asia/Seoul"
    )
    
    private var targetCity: City = City(
        name: "London",
        lng: "-0.1276",
        lat: "51.5072",
        country: "United Kingdom",
        timeZoneIdentifier: "Europe/London"
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "시간 변환기"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        baseCityLabel.text = "기준 도시: \(baseCity.name)"
        targetCityLabel.text = "변환 도시: \(targetCity.name)"
        baseCityLabel.textAlignment = .center
        targetCityLabel.textAlignment = .center
        baseCityLabel.font = .systemFont(ofSize: 18)
        targetCityLabel.font = .systemFont(ofSize: 18)

        datePicker.datePickerMode = .dateAndTime
        datePicker.timeZone = TimeZone(identifier: baseCity.timeZoneIdentifier)

        convertButton.setTitle("변환하기", for: .normal)
        convertButton.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)

        [baseCityLabel, datePicker, targetCityLabel, convertButton, dividerView, resultContainerView].forEach {
            view.addSubview($0)
        }

        baseCityLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.left.right.equalToSuperview().inset(24)
        }

        datePicker.snp.makeConstraints { make in
            make.top.equalTo(baseCityLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        targetCityLabel.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(24)
        }

        dividerView.backgroundColor = .systemGray4
        dividerView.snp.makeConstraints { make in
            make.top.equalTo(targetCityLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(1) // 얇은 선
        }
        
        convertButton.snp.makeConstraints { make in
            make.top.equalTo(dividerView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }

        resultContainerView.backgroundColor = UIColor.systemGray6
        resultContainerView.layer.cornerRadius = 12
        resultContainerView.layer.masksToBounds = true

        resultLabel.text = "결과가 여기에 표시됩니다"
        resultLabel.font = .systemFont(ofSize: 20, weight: .regular)
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0

        resultContainerView.addSubview(resultLabel)
        resultContainerView.snp.makeConstraints { make in
            make.top.equalTo(convertButton.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(24)
        }

        resultLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    @objc private func convertTapped() {
        let baseDate = datePicker.date

        guard
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

        // 7. 결과 표시
        resultLabel.text = "\(targetCity.name)의 시간:\n\(formatted)\n\(diffText)"
    }
}
