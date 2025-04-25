//
//  CityTableViewCell.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 2024/12/22.
//

import UIKit
import SnapKit
import CoreLocation

class CityTableViewCell: UITableViewCell {
    
    var horizontalContainerStackViewLeftMargin: Constraint? // 제약 조건 저장 변수

    lazy var horizontalContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()
    
    lazy var leftVerticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        return stackView
    }()
    
    lazy var timeHorizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .firstBaseline
        stackView.spacing = 4
        return stackView
    }()
    
    lazy var rightHorizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .firstBaseline
        stackView.spacing = 12
        return stackView
    }()
    
    lazy var gapLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .center
        return label
    }()
    
    lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    lazy var amPmLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    lazy var weatherLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var amPmFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a" // 오전 / 오후만
        return f
    }()

    private lazy var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "hh:mm" // 시간만
        return f
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        gapLabel.text = nil
        cityLabel.text = nil
        amPmLabel.text = nil
        timeLabel.text = nil
        weatherLabel.text = nil
    }
    
    func configure(city: City) {
        cityLabel.text = city.name
        
        // 1. 현재 시간 표시
        updateTime(for: city)
        
        // 2. 시차 표시
        if let timeZone = TimeZone(identifier: city.timeZoneIdentifier) {
            let now = Date()
            let currentOffset = timeZone.secondsFromGMT(for: now)
            let localOffset = TimeZone.current.secondsFromGMT(for: now)
            let hourDiff = (currentOffset - localOffset) / 3600

            let calendar = Calendar.current
            let cityDay = calendar.component(.day, from: now.addingTimeInterval(TimeInterval(hourDiff * 3600)))
            let localDay = calendar.component(.day, from: now)

            var gapText = ""
            if hourDiff == 0 {
                gapText = "오늘, ±0"
            } else {
                let dayChange = cityDay - localDay
                let dayText = dayChange == 1 ? "내일" : (dayChange == -1 ? "어제" : "오늘")
                gapText = "\(dayText), \(hourDiff >= 0 ? "+" : "")\(hourDiff)"
            }
            gapLabel.text = gapText
        }
    }

    func updateTime(for city: City) {
        guard let timeZone = TimeZone(identifier: city.timeZoneIdentifier) else { return }
        let now = Date()

        amPmFormatter.timeZone = timeZone
        timeFormatter.timeZone = timeZone

        amPmLabel.text = amPmFormatter.string(from: now)
        timeLabel.text = timeFormatter.string(from: now)
    }
    
    private func setupLayouts() {
        addSubview(horizontalContainerStackView)
        
        horizontalContainerStackView.snp.makeConstraints { make in
            horizontalContainerStackViewLeftMargin = make.left.equalToSuperview().offset(Const.margin).constraint
            make.top.equalToSuperview().offset(Const.margin)
            make.bottom.right.equalToSuperview().offset(-Const.margin)
        }
        
        horizontalContainerStackView.addArrangedSubviews([leftVerticalStackView, timeHorizontalStackView, rightHorizontalStackView])
        
        leftVerticalStackView.addArrangedSubviews([gapLabel, cityLabel])
        timeHorizontalStackView.addArrangedSubviews([amPmLabel, timeLabel])
        rightHorizontalStackView.addArrangedSubviews([timeHorizontalStackView, weatherLabel])
    }
}

enum Const {
    static let margin = 16
}
