//
//  Environment.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import SwiftUI

private struct StorageKey: EnvironmentKey {
    static let defaultValue: Storage = .shared
}

extension EnvironmentValues {
    var storage: Storage {
        get { self[StorageKey.self] }
        set { self[StorageKey.self] = newValue }
    }
}
