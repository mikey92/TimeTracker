//
//  UIStackView+Extension.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 2024/12/23.
//

import UIKit

extension UIStackView {
    func addArrangedSubviews(_ views: [UIView]) {
        for view in views {
            self.addArrangedSubview(view)
        }
    }
}
