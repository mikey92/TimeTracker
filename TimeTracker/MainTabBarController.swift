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
        
        tabBar.tintColor = UIColor.label
        
        tabBar.unselectedItemTintColor = UIColor.secondaryLabel
        
        tabBar.barTintColor = UIColor.systemBackground
        tabBar.isTranslucent = false

        viewControllers = [
            makeTab(viewController: ListViewController(), title: String(localized: "tab_world_clock"), icon: "globe"),
            makeTab(viewController: AlarmListViewController(), title: String(localized: "tab_alarm"), icon: "alarm"),
            makeTab(viewController: TimeConverterViewController(), title: String(localized: "tab_convert"), icon: "clock.arrow.2.circlepath")
        ]
    }
    
    private func makeTab(viewController: UIViewController, title: String, icon: String) -> UINavigationController {
        let nav = UINavigationController(rootViewController: viewController)
        nav.tabBarItem.title = title
        nav.tabBarItem.image = UIImage(systemName: icon)
        return nav
    }
}
