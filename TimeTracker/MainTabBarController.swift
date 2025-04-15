//
//  MainTabBarController.swift
//  TimeTracker
//
//  Created by Hye Ri Kim on 4/11/25.
//

import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.tintColor = .black
        tabBar.unselectedItemTintColor = .gray

        viewControllers = [
            makeTab(viewController: ListViewController(), title: "도시", icon: "globe"),
            makeTab(viewController: AlarmListViewController(), title: "알람", icon: "alarm"),
            makeTab(viewController: TimeConverterViewController(), title: "변환", icon: "clock.arrow.2.circlepath")
        ]
    }
    
    private func makeTab(viewController: UIViewController, title: String, icon: String) -> UINavigationController {
        let nav = UINavigationController(rootViewController: viewController)
        nav.tabBarItem.title = title
        nav.tabBarItem.image = UIImage(systemName: icon)
        return nav
    }
}
