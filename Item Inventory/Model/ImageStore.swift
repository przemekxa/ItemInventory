//
//  ImageStorage.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 02/05/2021.
//

import UIKit
import Combine
import OSLog
import func AVFoundation.AVMakeRect

class ImageStore {

    typealias Identifier = String

    let url: URL

    private let queue = DispatchQueue(label: "com.przambrozy.iteminventory.imagestorage.queue", qos: .userInitiated)
    private let fileManager = FileManager.default
    private let logger = Logger.imageStore

    init() {

        // Create images URL
        url = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("images", isDirectory: true)

        // Create images directory (if necessary)
        assureImagesDirectory()

        #if DEBUG
        if let contents = try? fileManager.contentsOfDirectory(atPath: url.path) {
            print("Contents: ", contents)
        }
        #endif
    }

    /// Create 'images' folder if necessary
    private func assureImagesDirectory() {
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                logger.error("Cannot create 'images' directory: \(error.localizedDescription)")
            }
        }
    }

    /// Delete all the photos
    func deleteAllData() {
        queue.async {
            do {
                try self.fileManager.removeItem(at: self.url)
                self.assureImagesDirectory()
            } catch {
                self.logger.error("Cannot delete 'images' directory: \(error.localizedDescription)")
            }
        }
    }

    /// Generate a new, unique identifier
    func uniqueIdentifier() -> Identifier {
        var identifier: Identifier
        var path: URL
        repeat {
            identifier = UUID().uuidString
            path = imageURL(for: identifier)
        } while fileManager.fileExists(atPath: path.path)

        return identifier
    }

    /// Generate multiple unique identifiers
    /// - Parameter count: Number of identifiers to generate
    func uniqueIdentifiers(count: Int) -> [Identifier] {
        var identifiers = [Identifier]()
        identifiers.reserveCapacity(count)

        var identifier: Identifier
        var url: URL

        while identifiers.count < count {
            identifier = UUID().uuidString
            url = imageURL(for: identifier)
            if !fileManager.fileExists(atPath: url.path) {
                identifiers.append(identifier)
            }
        }

        return identifiers
    }

    func imageURL(for identifier: Identifier) -> URL {
        url.appendingPathComponent(identifier + ".jpg")
    }

    /// Return all files saved on disk
    func savedIdentifiers() -> Set<Identifier> {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: url.path)
                .filter { $0.hasSuffix(".jpg") }
                .map { String($0.dropLast(4)) }
            return Set(contents)
        } catch {
            logger.error("Cannot get contents of images directory")
        }

        return Set()
    }

    /// Resize the image to the desired size, keeping the aspect ratio
    private func resize(image: UIImage, maxSize: CGSize = .init(width: 2048, height: 2048)) -> UIImage {
        // Calculate the size
        let size = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: .zero, size: maxSize)).size

        // Set scale to 1x
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0

        // Render new image
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Save an image
    func save(_ image: UIImage) -> Future<Identifier, Never> {
        Future { promise in
            self.queue.async {
                let identifier = self.uniqueIdentifier()
                let filepath = self.imageURL(for: identifier)
                let resized = self.resize(image: image)
                if let data = resized.jpegData(compressionQuality: 0.7) {
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
                    try self.fileManager.removeItem(at: filepath)
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
                        try self.fileManager.removeItem(at: filepath)
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
