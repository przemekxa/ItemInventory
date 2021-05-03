//
//  CoreData+Extension.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 04/05/2021.
//

import CoreData

extension Box {

    /// Formatted QR code
    ///
    /// The format: `S-00000000`
    var qrCode: String {
        "S-" + String(format: "%08d", code)
    }
}
