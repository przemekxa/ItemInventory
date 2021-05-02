//
//  ImageStorage.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 02/05/2021.
//

import UIKit
import Combine
import OSLog

class ImageStore {

    typealias Identifier = String

    private let url: URL

    private let queue: DispatchQueue

    private let logger = Logger.imageStore


    init() {

        // Create a background queue
        queue = DispatchQueue(label: "com.przambrozy.iteminventory.imagestorage.queue", qos: .userInitiated)

        // Create images URL
        url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("images", isDirectory: true)

        // Create images path (if necessary)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                logger.error("Cannot create directory")
            }
        }

        if let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path) {
            print("Contents: ", contents)
        }
    }

    /// Generate a new, unique identifier
    private func uniqueIdentifier() -> Identifier {
        var identifier: Identifier
        var path: URL
        repeat {
            identifier = UUID().uuidString
            path = imageURL(for: identifier)
        } while FileManager.default.fileExists(atPath: path.path)

        return identifier
    }

    func imageURL(for identifier: Identifier) -> URL {
        url.appendingPathComponent(identifier + ".jpg")
    }

    /// Save an image
    func save(_ image: UIImage) -> Future<Identifier, Never> {
        Future { promise in
            self.queue.async {
                let identifier = self.uniqueIdentifier()
                let filepath = self.imageURL(for: identifier)
                if let data = image.jpegData(compressionQuality: 0.7) {
                    do {
                        try data.write(to: filepath, options: .atomic)
                    } catch {
                        self.logger.error("Cannot save file")
                    }
                } else {
                    self.logger.error("Cannot convert image to JPG")
                }
                DispatchQueue.main.async {
                    promise(.success(identifier))
                }
            }
        }
    }

    /// Delete an image
    func delete(_ identifier: Identifier) -> Future<Void, Never> {
        Future { promise in
            self.queue.async {
                let filepath = self.imageURL(for: identifier)
                do {
                    try FileManager.default.removeItem(at: filepath)
                } catch {
                    self.logger.error("Cannot delete file")
                }
                DispatchQueue.main.async {
                    promise(.success(()))
                }
            }
        }
    }

    /// Delete multiple images
    func delete(_ identifiers: [Identifier]) -> Future<Void, Never> {
        Future { promise in
            self.queue.async {
                let filepaths = identifiers.map {
                    self.imageURL(for: $0)
                }
                do {
                    for filepath in filepaths {
                        try FileManager.default.removeItem(at: filepath)
                    }
                } catch {
                    self.logger.error("Cannot delete file")
                }
                DispatchQueue.main.async {
                    promise(.success(()))
                }
            }
        }
    }
    
}
