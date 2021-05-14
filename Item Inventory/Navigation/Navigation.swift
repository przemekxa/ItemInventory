//
//  Navigation.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import UIKit
import SwiftUI

class Navigation: NSObject, UITabBarControllerDelegate {

    private(set) var tabBar: UITabBarController

    private(set) var storage: Storage

    override init() {
        tabBar = UITabBarController()
        storage = .shared
        super.init()

        tabBar.delegate = self

        setupViews()

    }

    /// Setup views and add them to the tab bar
    private func setupViews() {

        // Locations
        let locationsView =  LocationsView()
            .environment(\.managedObjectContext, storage.context)
            .environment(\.storage, storage)

        let locationsViewHosting = UIHostingController(rootView: locationsView)

        locationsViewHosting.tabBarItem = UITabBarItem(title: "Locations",
                                                     image: UIImage(systemName: "map"),
                                                     selectedImage: UIImage(systemName: "map.fill"))

        // Second view
        let searchVC =  SearchVC(storage)
        let searchNavigationController = UINavigationController(rootViewController: searchVC)
        searchNavigationController.navigationBar.prefersLargeTitles = true

        searchNavigationController.tabBarItem = UITabBarItem(title: "Items",
                                                             image: UIImage(systemName: "magnifyingglass.circle"),
                                                             selectedImage: UIImage(systemName: "magnifyingglass.circle.fill"))


        tabBar.setViewControllers([locationsViewHosting, searchNavigationController], animated: false)
        tabBar.selectedIndex = 1
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Focus on search bar if clicked on items again
        if
            viewController == tabBarController.selectedViewController,
            let navigationVC = viewController as? UINavigationController,
            let searchVC = navigationVC.visibleViewController as? SearchVC,
            let searchBar = searchVC.navigationItem.searchController?.searchBar,
            !searchBar.isFirstResponder
            {
            searchBar.becomeFirstResponder()
        }

        return true
    }

}
