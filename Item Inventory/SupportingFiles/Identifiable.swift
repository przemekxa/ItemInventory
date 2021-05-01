//
//  Identifiable.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import Foundation

extension String: Identifiable {
    public var id: String { self }
}
