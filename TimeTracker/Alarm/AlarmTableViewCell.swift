//
//  AlarmTableViewCell.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 5/9/25.
//

import UIKit
import SnapKit

final class AlarmTableViewCell: UITableViewCell {
    
    static let identifier = "AlarmTableViewCell"

    var switchChanged: ((Bool) -> Void)?

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        return label
    }()
    
    private let cityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        return label
    }()
    
    private lazy var toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .systemGreen
        toggle.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        return toggle
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        timeLabel.text = nil
        descriptionLabel.text = nil
        cityLabel.text = nil
        toggleSwitch.isOn = false
        switchChanged = nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBackground
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(timeLabel)
        contentView.addSubview(cityLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(toggleSwitch)
        
        timeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
        }
        
        cityLabel.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(4)
            make.left.equalTo(timeLabel.snp.left)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(cityLabel.snp.bottom).offset(4)
            make.left.equalTo(timeLabel.snp.left)
            make.bottom.equalToSuperview().inset(12)
        }
        
        toggleSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
    }

    func configure(time: String, city: String, description: String, isOn: Bool) {
        let splitedTime = time.split(separator: " ").map{String($0)}
        timeLabel.attributedText = attributedTime(ampm: splitedTime.first ?? "", time: splitedTime.last ?? "")
        cityLabel.text = city
        descriptionLabel.text = description
        toggleSwitch.isOn = isOn

        self.isAccessibilityElement = false
        self.accessibilityElements = [timeLabel, cityLabel, descriptionLabel, toggleSwitch]
        timeLabel.accessibilityLabel = time
        cityLabel.accessibilityLabel = city
        descriptionLabel.accessibilityLabel = description
        toggleSwitch.accessibilityLabel = "Alarm toggle"
        toggleSwitch.accessibilityHint = isOn ? "Alarm is on" : "Alarm is off"
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        switchChanged?(sender.isOn)
    }
    
    func attributedTime(ampm: String, time: String) -> NSAttributedString {
        let amAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .title3),
            .foregroundColor: UIColor.label
        ]
        let timeAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .title1),
            .foregroundColor: UIColor.label
        ]
        let result: NSMutableAttributedString
        if LocalizationManager.isKorean {
            result = NSMutableAttributedString(string: ampm + " ", attributes: amAttr)
            result.append(NSAttributedString(string: time, attributes: timeAttr))
        } else {
            result = NSMutableAttributedString(string: time, attributes: timeAttr)
            result.append(NSAttributedString(string: " " + ampm, attributes: amAttr))
        }
        return result
    }
}
