//
//  Navigation.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import UIKit
import SwiftUI
import Combine

class Navigation: NSObject, UITabBarControllerDelegate {

    private(set) var tabBar: UITabBarController

    // View controllers
    private var searchNavigation: UINavigationController!
    private var scannerNavigation: UINavigationController!

    private(set) var storage: Storage
    private var importExportManager: ImportExportManager
    private var cancellables = Set<AnyCancellable>()

    override init() {
        tabBar = UITabBarController()
        storage = .shared
        importExportManager = ImportExportManager(storage)
        super.init()

        tabBar.delegate = self

        setupViews()

        // SwiftUI tab bar title bug workaround
        NotificationCenter.default.publisher(for: Self.updateTabBar)
            .sink { [weak self] _ in
                self?.tabBar.viewControllers?[2].tabBarItem.title = "Scanner"
            }
            .store(in: &cancellables)

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

        // Settings
        let settingsView = SettingsView(manager: importExportManager)
            .environment(\.managedObjectContext, storage.context)
            .environment(\.storage, storage)
        let settingsViewHosting = UIHostingController(rootView: settingsView)
        settingsViewHosting.tabBarItem = UITabBarItem(title: "Settings",
                                                      image: UIImage(systemName: "gearshape"),
                                                      selectedImage: UIImage(systemName: "gearshape.fill"))

        tabBar.setViewControllers([locationsViewHosting, searchNavigation, scannerNavigation, settingsViewHosting],
                                  animated: false)
        tabBar.selectedIndex = 0
    }

    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
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
            boxViewHosting.navigationItem.title = box.name
            scannerNavigation.pushViewController(boxViewHosting, animated: true)
        }
    }

    func showItem(_ item: Item) {
        if let scannerNavigation = tabBar.viewControllers?[2] as? UINavigationController {
            let itemView = ItemView(item, allowsOpeningBoxAndLocation: true)
                .environment(\.managedObjectContext, storage.context)
                .environment(\.storage, storage)
            let itemViewHosting = UIHostingController(rootView: itemView)
            itemViewHosting.navigationItem.title = item.name
            scannerNavigation.pushViewController(itemViewHosting, animated: true)
        }
    }

}

extension Navigation {

    static let updateTabBar = NSNotification.Name("com.przambrozy.iteminventory.updateTabrBar")
}
