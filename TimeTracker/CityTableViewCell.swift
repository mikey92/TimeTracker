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
    
    lazy var rightHorizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .bottom
        stackView.spacing = 12
        return stackView
    }()
    
    lazy var gapLabel: UILabel = {
        let label = UILabel()
        label.text = "today, +0"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .center
        return label
    }()
    
    lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.text = "San Jose"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.text = "오전 11:00"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    lazy var weatherLabel: UILabel = {
        let label = UILabel()
        label.text = "맑음"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        return label
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
        timeLabel.text = nil
        weatherLabel.text = nil
    }
    
    func configure(city: City) {
        cityLabel.text = city.name
        
    }
    
    private func setupLayouts() {
        addSubview(horizontalContainerStackView)
        
        horizontalContainerStackView.snp.makeConstraints { make in
            horizontalContainerStackViewLeftMargin = make.left.equalToSuperview().offset(16).constraint
            make.top.equalToSuperview().offset(16)
            make.bottom.right.equalToSuperview().offset(-16)
        }
        
        horizontalContainerStackView.addArrangedSubviews([leftVerticalStackView, rightHorizontalStackView])
        
        leftVerticalStackView.addArrangedSubviews([gapLabel, cityLabel])
        rightHorizontalStackView.addArrangedSubviews([timeLabel, weatherLabel])
    }
}


extension CityTableViewCell {
    func getCurrentTime(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        // CLLocation을 생성
        let location = CLLocation(latitude: latitude, longitude: longitude)

        // CLGeocoder를 사용해 위치 정보 가져오기
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("에러 발생: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first,
                  let timeZone = placemark.timeZone else {
                print("시간대를 찾을 수 없습니다.")
                return
            }
            
            // 현재 디바이스의 시간대 가져오기
            let currentDeviceTimeZone = TimeZone.current
            
            // 시간 차이를 초 단위로 계산
            let secondsDifference = timeZone.secondsFromGMT() - currentDeviceTimeZone.secondsFromGMT()
            let hoursDifference = secondsDifference / 3600
            
            print("해당 위치와 디바이스의 시간 차이: \(hoursDifference)시간")
            
            // 현재 시간 가져오기
            let currentDate = Date()
            let formatter = DateFormatter()
            formatter.timeZone = timeZone
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let localTime = formatter.string(from: currentDate)
            print("현재 시간: \(localTime)")
        }
    }
}
