//
//  CodableModel.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 15/05/2021.
//

import Foundation

protocol ImageUUIDsAsIdentifiers {
    var imageUUIDs: String? { get set }
    var imageIdentifiers: [String] { get set }
}


extension ImageUUIDsAsIdentifiers {

    // Default implementation
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


struct CodableItem: Codable, ImageUUIDsAsIdentifiers {
    var name: String
    var comment: String?
    var keywords: String?
    var barcode: String?
    var imageUUIDs: String?

    init(_ item: Item) {
        name = item.name ?? ""
        comment = item.comment
        keywords = item.keywords
        barcode = item.barcode
        imageUUIDs = item.imageUUIDs
    }

    func populate(item: Item) {
        item.name = name
        item.comment = comment
        item.keywords = keywords
        item.barcode = barcode
        item.imageIdentifiers = imageIdentifiers
    }
}

struct CodableBox: Codable {
    var name: String
    var code: Int64
    var comment: String?
    var imageUUID: String?
    var items: [CodableItem] = []

    init(_ box: Box) {
        name = box.name ?? ""
        code = box.code
        comment = box.comment
        imageUUID = box.imageUUID
        if let items = box.items?.allObjects as? [Item] {
            self.items = items.map { CodableItem($0) }
        }
    }

    func populate(box: Box) {
        box.name = name
        box.code = code
        box.comment = comment
        box.imageUUID = imageUUID
    }
}

struct CodableLocation: Codable {
    var name: String
    var boxes: [CodableBox] = []

    init(_ location: Location) {
        name = location.name ?? ""
        if let boxes = location.boxes?.allObjects as? [Box] {
            self.boxes = boxes.map { CodableBox($0) }
        }
    }
}



