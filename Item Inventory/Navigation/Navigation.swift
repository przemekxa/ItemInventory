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
        let second =  SearchVC(storage)

        second.tabBarItem = UITabBarItem(title: "Second",
                                         image: UIImage(systemName: "map"),
                                         selectedImage: UIImage(systemName: "map.fill"))

        // QR View
//        let qra = QRBarcodeView(objectTypes: [.qr, .ean8, .ean13, .upc]) { result in
//            print("Result:", result)
//        }
        let qrhost = UIHostingController(rootView: BoxSearchView(box: Box()))

        tabBar.setViewControllers([locationsViewHosting, second, qrhost], animated: false)
    }

//    // Future - detect subsequent clicks
//    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
//        print("Selected", viewController.tabBarItem.title, "previous", tabBarController.selectedViewController?.tabBarItem.title)
//        return true
//    }

}
