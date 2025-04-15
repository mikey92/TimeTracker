//
//  UIViewController+Extension.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 2024/12/23.
//

import Foundation
import UIKit

extension UIViewController {
    func showToast(message: String, duration: TimeInterval = 2.0) {
        // 토스트 레이블 생성
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.numberOfLines = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true

        // 토스트 레이블 크기와 위치 설정
        let maxWidthPercentage: CGFloat = 0.8 // 화면의 80% 너비로 제한
        let maxTitleSize = CGSize(width: view.bounds.size.width * maxWidthPercentage, height: CGFloat.greatestFiniteMagnitude)
        let expectedSize = toastLabel.sizeThatFits(maxTitleSize)
        toastLabel.frame = CGRect(
            x: (view.bounds.size.width - expectedSize.width) / 2,
            y: view.bounds.size.height - 150,
            width: expectedSize.width + 20,
            height: expectedSize.height + 10
        )

        // 토스트 레이블 추가
        view.addSubview(toastLabel)

        // 애니메이션을 통해 사라지게 처리
        UIView.animate(withDuration: 0.5, delay: duration, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }) { _ in
            toastLabel.removeFromSuperview()
        }
    }
}
