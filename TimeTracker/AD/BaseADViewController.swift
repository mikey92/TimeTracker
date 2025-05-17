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
    
    var bannerView: BannerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAdBanner()
    }

    func setupAdBanner() {
        bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = ""
        bannerView.rootViewController = self
        bannerView.load(Request())
        
        view.addSubview(bannerView)
        
        bannerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(50)
        }
    }
}
