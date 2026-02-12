//
//  CityTableViewCell.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 2024/12/22.
//

import UIKit
import SnapKit

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
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()
    
    lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()
    
    lazy var amPmLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()
    
    lazy var weatherLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .right
        return label
    }()
    
    private lazy var amPmFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.autoupdatingCurrent // ✅ 사용자의 언어 설정을 따름
        f.dateFormat = "a" // 오전 / 오후
        return f
    }()

    private lazy var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.autoupdatingCurrent // ✅ 사용자의 언어 설정을 따름
        f.dateFormat = "hh:mm" // 12시간제 시간
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
        super.prepareForReuse()
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
            gapLabel.text = TimeZoneHelper.gapText(for: timeZone)
        }

        self.isAccessibilityElement = true
        self.accessibilityLabel = "\(city.name), \(gapLabel.text ?? ""), \(amPmLabel.text ?? "") \(timeLabel.text ?? "")"
    }

    func updateTime(for city: City) {
        guard let timeZone = TimeZone(identifier: city.timeZoneIdentifier) else { return }
        let now = Date()

        amPmFormatter.timeZone = timeZone
        timeFormatter.timeZone = timeZone

        amPmLabel.text = amPmFormatter.string(from: now)
        timeLabel.text = timeFormatter.string(from: now)

        self.accessibilityLabel = "\(city.name), \(gapLabel.text ?? ""), \(amPmLabel.text ?? "") \(timeLabel.text ?? "")"
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
        if LocalizationManager.isKorean {
            timeHorizontalStackView.addArrangedSubviews([amPmLabel, timeLabel])
        } else {
            timeHorizontalStackView.addArrangedSubviews([timeLabel, amPmLabel])
        }
        rightHorizontalStackView.addArrangedSubviews([timeHorizontalStackView, weatherLabel])
    }
}

enum Const {
    static let margin = 16
}
