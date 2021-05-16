//
//  ImportExportManager.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 15/05/2021.
//

import Foundation
import OSLog
import CoreData
import ZIPFoundation
import Combine

class ImportExportManager: ObservableObject {

    enum ExportError: Error {
        case fetchLocations
    }

    enum ImportError: Error {
        case generalLocation
        case location
    }

    static private let generalLocationFilename = "general_location"
    static private let locationFilenamePrefix = "location_"

    private let logger = Logger.importExport
    private let storage: Storage
    private let imageStore: ImageStore
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "com.przambrozy.iteminventory.importExportManager.queue", qos: .userInitiated)

    // URLs

    private let documentsURL: URL
    private let exportURL: URL
    private let importURL: URL
    private let imagesURL: URL

    // State

    /// True if the export process in in progress
    @Published private(set) var isExporting = false

    /// Exported file URL
    @Published var exportFileURL: URL?

    /// Error message during export
    @Published private(set) var exportError: String?

    /// True if the import process in in progress
    @Published private(set) var isImporting = false

    /// Error message during import
    @Published private(set) var importError: String?

    private var exportWork: DispatchWorkItem?

    init(_ storage: Storage) {
        self.storage = storage
        self.imageStore = storage.imageStore
        self.fileManager = FileManager.default
        self.imagesURL = storage.imageStore.url

        self.documentsURL = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask).first!

        self.exportURL = documentsURL.appendingPathComponent("export", isDirectory: true)
        self.importURL = documentsURL.appendingPathComponent("import", isDirectory: true)

    }

    // MARK: - Export

    /// Prepare for the export
    func prepareExport() throws {
        do {
            // Remove old export directory
            if fileManager.fileExists(atPath: exportURL.path) {
                try fileManager.removeItem(at: exportURL)
            }
            // Remove old exported ZIPs
            let oldExportFiles = try fileManager.contentsOfDirectory(atPath: documentsURL.path)
                .filter { $0.hasPrefix("export_") && $0.hasSuffix(".zip") }
            for file in oldExportFiles {
                try fileManager.removeItem(at: documentsURL.appendingPathComponent(file))
            }
        } catch {
            logger.error("Cannot prepare export: \(error.localizedDescription)")
            throw error
        }
    }

    /// Copy photos to temporary export directory
    private func exportPhotos() throws {
        do {
            try fileManager.copyItem(at: imagesURL, to: exportURL)
        } catch {
            logger.error("Cannot export photos: \(error.localizedDescription)")
            throw error
        }
    }

    /// Export the database
    private func exportDatabase() throws {
        
        let backgroundContext = storage.newBackgroundContext()
        let encoder = JSONEncoder()

        // General location
        do {
            let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "box == nil")
            let items = (try backgroundContext.fetch(fetchRequest)).map { CodableItem($0) }
            let encoded = try encoder.encode(items)
            try encoded.write(to: exportURL.appendingPathComponent(Self.generalLocationFilename + ".json"))
        } catch {
            logger.error("Cannot export general location: \(error.localizedDescription)")
            throw error
        }

        // Named locations
        do {
            let locations: [Location] = try backgroundContext.fetch(Location.fetchRequest())

            for (index, location) in locations.enumerated() {
                let codableLocation = CodableLocation(location)
                let encoded = try encoder.encode(codableLocation)
                let locationURL = exportURL.appendingPathComponent(Self.locationFilenamePrefix + "\(index).json")
                try encoded.write(to: locationURL)
            }
        } catch {
            logger.error("Cannot export some locations: \(error.localizedDescription)")
            throw error
        }

    }

    private func exportZip() throws -> URL {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "export_" + df.string(from: Date()) + ".zip"
        let fileURL = documentsURL.appendingPathComponent(filename)

        do {
            // Prepare ZIP
            try fileManager.zipItem(at: exportURL,
                                    to: fileURL,
                                    shouldKeepParent: false,
                                    compressionMethod: .deflate)

            // Delete export directory
            try fileManager.removeItem(at: exportURL)

            return fileURL
        } catch {
            logger.error("Cannot prepare ZIP: \(error.localizedDescription)")
            throw error
        }
    }

    /// Export the data
    func exportData() {
        guard !isExporting else { return }
        isExporting = true
        exportFileURL = nil
        exportError = nil

        let work = DispatchWorkItem {
            do {
                try self.prepareExport()
                try self.exportPhotos()
                try self.exportDatabase()
                let zip = try self.exportZip()
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.exportFileURL = zip
                    self.exportError = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.exportFileURL = nil
                    self.exportError = "Error during export"
                }
            }
        }

        queue.async(execute: work)
        exportWork = work
    }

    /// Clean up after the export
    func didExport() {
        logger.debug("Did export, cleaning up")
        isExporting = false
        exportError = nil
        exportFileURL = nil
        queue.async {
            do {
                // Remove old export directory
                if self.fileManager.fileExists(atPath: self.exportURL.path) {
                    try self.fileManager.removeItem(at: self.exportURL)
                }
                // Remove all exported ZIPs
                let exportZips = try self.fileManager.contentsOfDirectory(atPath: self.documentsURL.path)
                    .filter { $0.hasPrefix("export_") && $0.hasSuffix(".zip") }
                for file in exportZips {
                    try self.fileManager.removeItem(at: self.documentsURL.appendingPathComponent(file))
                }
            } catch {
                self.logger.error("Cannot clean up after the export: \(error.localizedDescription)")
            }
        }
    }


    /// Cancel the export process
    func cancelExport() {
        exportWork?.cancel()
        isExporting = false
        exportFileURL = nil
        exportError = nil
        didExport()
    }

    // MARK: - Import

    private func updateImageIdentifiers(_ items: inout [CodableItem], in dictionary: inout [String:String]) {

        // Get old identifiers
        let oldIdentifiers = items.flatMap { $0.imageIdentifiers }

        // Create new identifiers
        let newIdentifiers = imageStore.uniqueIdentifiers(count: oldIdentifiers.count)

        for index in oldIdentifiers.indices {
            dictionary[oldIdentifiers[index]] = newIdentifiers[index]
        }

        for index in items.indices {
            items[index].imageIdentifiers = items[index].imageIdentifiers.map { dictionary[$0]! }
        }
    }

    private func updateImageIdentifiers(_ boxes: inout [CodableBox], in dictionary: inout [String:String]) {

        // Get old identifiers
        let oldIdentifiers = boxes.compactMap { $0.imageUUID }

        // Create new identifiers
        let newIdentifiers = imageStore.uniqueIdentifiers(count: oldIdentifiers.count)

        for index in oldIdentifiers.indices {
            dictionary[oldIdentifiers[index]] = newIdentifiers[index]
        }

        for index in boxes.indices {
            if let oldIdentifier = boxes[index].imageUUID {
                boxes[index].imageUUID = dictionary[oldIdentifier]
            }
        }
    }

    /// Import General Location items
    private func importGeneralLocation(decoder: JSONDecoder,
                                       context: NSManagedObjectContext,
                                       imageIdentifiers: inout [String:String]) throws {

        // Decode items
        let data = try Data(contentsOf: importURL.appendingPathComponent(Self.generalLocationFilename + ".json"))
        var items = try decoder.decode([CodableItem].self, from: data)

        if !items.isEmpty {

            // Create new identifiers
            updateImageIdentifiers(&items, in: &imageIdentifiers)

            // Insert
            for codableItem in items {
                let item = Item(context: context)
                codableItem.populate(item: item)
            }
            
            try? context.save()
        }
    }

    private func importLocation(url: URL,
                                decoder: JSONDecoder,
                                context: NSManagedObjectContext,
                                imageIdentifiers: inout [String:String]) throws {

        // Decode location
        let data = try Data(contentsOf: url)
        var codableLocation = try decoder.decode(CodableLocation.self, from: data)

        // Create location
        let location = Location(context: context)
        location.name = codableLocation.name

        // Change images
        updateImageIdentifiers(&codableLocation.boxes, in: &imageIdentifiers)
        for index in codableLocation.boxes.indices {
            updateImageIdentifiers(&codableLocation.boxes[index].items, in: &imageIdentifiers)
        }

        for codableBox in codableLocation.boxes {

            // Create box
            let box = Box(context: context)
            codableBox.populate(box: box)
            box.location = location

            // Add items
            for codableItem in codableBox.items {

                // Create item
                let item = Item(context: context)
                codableItem.populate(item: item)
                item.box = box
            }

        }

        try context.save()

    }

    /// Import the images
    private func importImages(_ dictionary: [ImageStore.Identifier:ImageStore.Identifier]) throws {

        for (source, destination) in dictionary {
            let sourceURL = importURL.appendingPathComponent(source + ".jpg")
            let destinationURL = imagesURL.appendingPathComponent(destination + ".jpg")
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }

    }

    /// Import data from a given URL
    func importData(from url: URL) {
        guard !isImporting else { return }
        isImporting = true
        importError = nil

        queue.async {
            do {

                //let url = self.documentsURL.appendingPathComponent("test.zip")
                let decoder = JSONDecoder()
                let backgroundContext = self.storage.newBackgroundContext()

                // Unzip
                try self.fileManager.unzipItem(at: url,
                                               to: self.documentsURL.appendingPathComponent("import", isDirectory: true))


                // Keep track of image identifiers
                var imageIdentifiers = [ImageStore.Identifier:ImageStore.Identifier]()

                // Import General location
                try self.importGeneralLocation(decoder: decoder,
                                          context: backgroundContext,
                                          imageIdentifiers: &imageIdentifiers)


                // Import Locations
                let locations = try self.fileManager.contentsOfDirectory(atPath: self.importURL.path)
                    .filter { $0.hasPrefix(Self.locationFilenamePrefix) && $0.hasSuffix(".json") }

                for location in locations {
                    try self.importLocation(url: self.importURL.appendingPathComponent(location),
                                       decoder: decoder,
                                       context: backgroundContext,
                                       imageIdentifiers: &imageIdentifiers)
                }

                // Import images
                try self.importImages(imageIdentifiers)

                // Delete temporary 'import' directory
                try self.fileManager.removeItem(at: self.importURL)

                // Update last box id
                let boxFetchRequest: NSFetchRequest = Box.fetchRequest()
                boxFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Box.code, ascending: false)]
                boxFetchRequest.fetchLimit = 1
                if let maxCodeBox = (try backgroundContext.fetch(boxFetchRequest)).first {
                    self.storage.lastBoxID = Int(maxCodeBox.code)
                }

                DispatchQueue.main.async {
                    self.isImporting = false
                    self.importError = nil
                }

            } catch {
                self.logger.error("Cannot import data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isImporting = false
                    self.importError = "Error during import"
                }
            }
        }


    }
}
