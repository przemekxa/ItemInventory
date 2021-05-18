//
//  Logger.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import Foundation
import OSLog

extension Logger {

    private static var subsystem = Bundle.main.bundleIdentifier!

    static let storage = Logger(subsystem: subsystem, category: "coreData")
    static let imageStore = Logger(subsystem: subsystem, category: "imageStorage")
    static let importExport = Logger(subsystem: subsystem, category: "importExport")
    static let qrGenerator = Logger(subsystem: subsystem, category: "qrGenerator")

    static let searchVC = Logger(subsystem: subsystem, category: "searchVC")

}
