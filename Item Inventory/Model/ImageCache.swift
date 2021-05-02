//
//  ImageCache.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 02/05/2021.
//

import UIKit
import Combine

class ImageCache: ObservableObject {

    typealias Identifier = ImageStore.Identifier

    
    /// Used image store
    private let store: ImageStore

    /// Operations in progress
    private var operations = Set<AnyCancellable>()

    /// Initial images - already saved on disk
    private let initialImages: Set<Identifier>

    /// All images
    @Published private(set) var images: Set<Identifier>

    /// Remaining operations in progress
    @Published private(set) var inProgress = 0

    init(_ storage: ImageStore, initial images: [Identifier]) {
        self.store = storage
        self.initialImages = Set(images)
        self.images = Set(images)
    }

    /// Add a new image
    func add(_ image: UIImage) {
        inProgress += 1
        store.save(image)
            .sink { [weak self] identifier in
                self?.images.insert(identifier)
                self?.inProgress -= 1
            }
            .store(in: &operations)
    }

    /// Delete an existing image
    func delete(_ identifier: Identifier) {

        // If the old image is in initial images - don't remove (yet)
        if initialImages.contains(identifier) {

            // Remove just from the list of current images
            images.remove(identifier)

        } else {
            inProgress += 1
            store.delete(identifier)
                .sink { [weak self] in
                    self?.images.insert(identifier)
                    self?.inProgress -= 1
                }
                .store(in: &operations)
        }
    }

    /// Replace an image with new one
    func replace(_ oldIdentifier: Identifier, with newImage: UIImage) {

        // Add the new image
        add(newImage)

        // Remove the old image
        delete(oldIdentifier)
        
    }


    /// Save the changes
    ///
    /// Changes will be confirmed:
    /// - deleted initial images will be **deleted** from disk
    /// - added images will **remain** on disk
    func save() {

        let toDelete = initialImages.subtracting(images)

        if !toDelete.isEmpty {
            inProgress += 1
            store.delete(Array(toDelete))
                .sink { [weak self] in
                    self?.inProgress -= 1
                }
                .store(in: &operations)
        }

    }

    /// Cancel the changes
    ///
    /// Changes will be cancelled:
    /// - deleted initial images will **remain** on disk
    /// - added images will be **deleted**
    func cancel() {

        let toDelete = images.subtracting(initialImages)

        if !toDelete.isEmpty {
            inProgress += 1
            store.delete(Array(toDelete))
                .sink { [weak self] in
                    self?.inProgress -= 1
                }
                .store(in: &operations)
        }

    }

}
