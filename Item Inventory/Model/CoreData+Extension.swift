//
//  CoreData+Extension.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 04/05/2021.
//

import CoreData

extension Location {

    var hasBoxes: Bool {
        if let boxes = boxes {
            return boxes.count > 0
        }
        return false
    }
}

extension Box {

    /// Formatted QR code
    ///
    /// The format: `S-00000000`
    var qrCode: String {
        "S-" + String(format: "%08d", code)
    }

    /// Convert QR code to Int
    static func qrCodeToInt(_ code: String) -> Int? {
        if let regex = try? NSRegularExpression(pattern: #"^S-\d{8}$"#),
           regex.firstMatch(in: code,
                            options: [],
                            range: NSRange(location: 0, length: code.utf16.count)) != nil {
            let startIndex = code.index(code.startIndex, offsetBy: 2)
            let endIndex = code.index(code.startIndex, offsetBy: 9)
            let id = Int(code[startIndex...endIndex])!
            return id
        }
        return nil
    }

    /// Convert ID to QR code
    static func intToQrCode(_ integer: Int) -> String {
        "S-" + String(format: "%08d", integer)
    }
}

extension Item {

    /// Image identifiers
    var imageIdentifiers: [String] {
        get {
            if let uuids = imageUUIDs {
                return uuids
                    .split(separator: ",")
                    .filter { $0.count == 36 }
                    .map { String($0) }

            }
            return []
        }
        set {
            imageUUIDs = newValue.joined(separator: ",")
        }
    }
}
