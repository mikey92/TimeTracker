//
//  BaseADViewController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 5/12/25.
//

import UIKit
import GoogleMobileAds
import SnapKit

class BaseAdViewController: UIViewController {

    private var bannerView: BannerView?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func setupAdBanner() {
        guard bannerView == nil else { return }
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = ""
        banner.rootViewController = self
        banner.load(Request())

        view.addSubview(banner)

        banner.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(50)
        }
        bannerView = banner
    }
}
