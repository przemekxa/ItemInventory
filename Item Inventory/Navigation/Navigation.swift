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

    // View controllers
    private var searchNavigation: UINavigationController!
    private var scannerNavigation: UINavigationController!

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

        // Items
        let searchVC = SearchVC(storage)
        searchNavigation = UINavigationController(rootViewController: searchVC)
        searchNavigation.navigationBar.prefersLargeTitles = true
        searchNavigation.tabBarItem = UITabBarItem(title: "Items",
                                                   image: UIImage(systemName: "magnifyingglass.circle"),
                                                   selectedImage: UIImage(systemName: "magnifyingglass.circle.fill"))

        // Scanner
        var scannerView =  ScannerView()
        scannerView.delegate = self

        let scannerViewEnvironment = scannerView
            .environment(\.managedObjectContext, storage.context)
            .environment(\.storage, storage)
        

        let scannerViewHosting = UIHostingController(rootView: scannerViewEnvironment)

        scannerNavigation = UINavigationController(rootViewController: scannerViewHosting)
        scannerNavigation.navigationBar.prefersLargeTitles = true
        scannerNavigation.tabBarItem = UITabBarItem(title: "Scanner",
                                                    image: UIImage(systemName: "qrcode.viewfinder"),
                                                    selectedImage: nil)
        // Make white background
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        scannerNavigation.navigationBar.scrollEdgeAppearance = navigationBarAppearance


        tabBar.setViewControllers([locationsViewHosting, searchNavigation, scannerNavigation], animated: false)
        tabBar.selectedIndex = 2
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

extension Navigation: ScannerViewDelegate {
    func showBox(_ box: Box) {
        if let scannerNavigation = tabBar.viewControllers?[2] as? UINavigationController {
            let boxView = BoxView(box)
                .environment(\.managedObjectContext, storage.context)
                .environment(\.storage, storage)
            let boxViewHosting = UIHostingController(rootView: boxView)
            boxViewHosting.title = box.name
            scannerNavigation.pushViewController(boxViewHosting, animated: true)
        }
    }

    func showItem(_ item: Item) {
        if let scannerNavigation = tabBar.viewControllers?[2] as? UINavigationController {
            let itemView = ItemView(item, allowsOpeningBoxAndLocation: true)
                .environment(\.managedObjectContext, storage.context)
                .environment(\.storage, storage)
            let itemViewHosting = UIHostingController(rootView: itemView)
            itemViewHosting.title = item.name
            scannerNavigation.pushViewController(itemViewHosting, animated: true)
        }
    }


}
