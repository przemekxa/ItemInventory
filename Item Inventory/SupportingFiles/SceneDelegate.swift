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


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

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

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        /// TODO: Save context
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
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
                                      icon: UIApplicationShortcutIcon(systemImageName: "qrcode.viewfinder")),
        ]
    }

    /// Handle the shortcut action
    private func handleShortcutItem(_ item: UIApplicationShortcutItem?) {
        if let item = item, let index = Int(item.type), index >= 0 && index <= 2 {
            navigation?.tabBar.selectedIndex = index
        }
    }

}

