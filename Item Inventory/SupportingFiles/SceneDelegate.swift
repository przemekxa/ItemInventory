//
//  SceneDelegate.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var navigation: Navigation?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        // Setup the shortcut items
        setupShortcutItems()

        navigation = Navigation()

        // Handle the shortcut items
        handleShortcutItem(connectionOptions.shortcutItem)

        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        self.window?.rootViewController = navigation?.tabBar
        self.window?.makeKeyAndVisible()

    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        navigation?.storage.save()
    }

    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        if let index = Int(shortcutItem.type), index >= 0 && index <= 2 {
            navigation?.tabBar.selectedIndex = index
        }
    }

    // MARK: - Shortcut actions

    /// Setup the shortcut items
    private func setupShortcutItems() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(type: "0",
                                      localizedTitle: "Locations",
                                      localizedSubtitle: nil,
                                      icon: UIApplicationShortcutIcon(systemImageName: "map")),
            UIApplicationShortcutItem(type: "1",
                                      localizedTitle: "Items",
                                      localizedSubtitle: nil,
                                      icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass.circle")),
            UIApplicationShortcutItem(type: "2",
                                      localizedTitle: "Scanner",
                                      localizedSubtitle: nil,
                                      icon: UIApplicationShortcutIcon(systemImageName: "qrcode.viewfinder"))
        ]
    }

    /// Handle the shortcut action
    private func handleShortcutItem(_ item: UIApplicationShortcutItem?) {
        if let item = item, let index = Int(item.type), index >= 0 && index <= 2 {
            navigation?.tabBar.selectedIndex = index
        }
    }

}
