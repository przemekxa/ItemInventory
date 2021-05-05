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
        let second =  ContentView()
            .environment(\.managedObjectContext, storage.context)

        let secondHost = UIHostingController(rootView: second)

        secondHost.tabBarItem = UITabBarItem(title: "Second",
                                                     image: UIImage(systemName: "map"),
                                                     selectedImage: UIImage(systemName: "map.fill"))

        // QR View
        let qra = QRBarcodeView(objectTypes: [.qr]) { result in
            print("Result:", result)
        }
        let qrhost = UIHostingController(rootView: qra)

        tabBar.setViewControllers([locationsViewHosting, secondHost, qrhost], animated: false)
    }

//    // Future - detect subsequent clicks
//    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
//        print("Selected", viewController.tabBarItem.title, "previous", tabBarController.selectedViewController?.tabBarItem.title)
//        return true
//    }

}
