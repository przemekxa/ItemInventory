//
//  Storage.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import Foundation
import CoreData
import Combine
import OSLog

class Storage {

    private var container: NSPersistentContainer
    
    private(set) var context: NSManagedObjectContext

    private var backgroundContext: NSManagedObjectContext

    private let logger = Logger.storage

    static let shared = Storage()

    let imageStore = ImageStore()
    private var imageOperations = Set<AnyCancellable>()

    private init() {

        // Init the persistent container
        container = NSPersistentContainer(name: "Item_Inventory")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                Logger.storage.error("Error loading persistent store: \(error.localizedDescription)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        backgroundContext = container.newBackgroundContext()

        deleteOrphanImages()
    }

    /// Delete orphan images (images that are on disk, but not in the database)
    private func deleteOrphanImages() {

        container.performBackgroundTask { [weak self] context in
            guard let self = self else { return }
            // Get all boxes and all items
            let boxFetchRequest: NSFetchRequest<Box> = Box.fetchRequest()
            let itemFetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
            let boxes = (try? context.fetch(boxFetchRequest)) ?? []
            let items = (try? context.fetch(itemFetchRequest)) ?? []

            // Get box and item image identifiers
            let boxImages = Set(boxes.compactMap { $0.imageUUID })
            let itemImages = Set(items.flatMap { $0.imageIdentifiers })
            let inDatabase = boxImages.union(itemImages)

            // Get identifiers on disk
            let onDisk = self.imageStore.savedIdentifiers()

            let orphanImages = onDisk.subtracting(inDatabase)

            // Delete orphan images
            if !orphanImages.isEmpty {
                self.logger.warning("Found orphan images on disk, deleting them")
                self.imageStore.delete(Array(orphanImages))
                    .sink {}
                    .store(in: &self.imageOperations)
            }
        }
    }

    /// Save any changes to the database
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                Logger.storage.error("Error saving managed object context: \(error.localizedDescription)")
            }
        }
    }


    /// Delete an object
    /// - Parameter id: ID of the object
    private func delete(_ id: NSManagedObjectID, save: Bool = true) {
        if let object = try? context.existingObject(with: id) {
            context.delete(object)
            if save {
                context.perform {
                    self.save()
                }
            }
        }
    }

//    func edit<Object: NSManagedObject>(_ object: Object, _ block: (Object) -> ()) {
//        context.performAndWait {
//            block(object)
//            save()
//        }
//    }

    // MARK: - Location

    /// Get all locations
    var locations: [Location] {
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        return (try? context.fetch(fetchRequest)) ?? []
    }

    /// Add a new location
    /// - Parameter name: Name of the location
    func addLocation(named name: String) {
        let location = Location(context: context)
        location.name = name
        save()
    }

    /// Delete a location
    func delete(_ location: Location) {
        delete(location.objectID)
    }

    // MARK: - Box

    private let LAST_BOX_ID_KEY = "lastBoxId"

    /// Get all boxes
//    var boxes: [Box] {
//        let fetchRequest: NSFetchRequest<Box> = Box.fetchRequest()
//        return (try? context.fetch(fetchRequest)) ?? []
//    }


    /// ID of the last saved box
    var lastBoxID: Int {
        get { UserDefaults.standard.integer(forKey: LAST_BOX_ID_KEY) }
        set { UserDefaults.standard.set(newValue, forKey: LAST_BOX_ID_KEY)}
    }

    /// Check if a box with given id exists
    func hasBox(with id: Int) -> Bool {
        let fetchRequest: NSFetchRequest<Box> = Box.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "code == %i", id)
        let count = (try? context.count(for: fetchRequest)) ?? 0
        return count > 0
    }

    /// Search for a box with a given ID
    func box(with id: Int) -> Box? {
        let fetchRequest: NSFetchRequest<Box> = Box.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "code == %i", id)
        return ((try? context.fetch(fetchRequest)) ?? []).first
    }

    /// Add a new box
    func addBox(name: String,
                location: Location,
                comment: String,
                code: Int,
                imageUUID: String?) {
        let box = Box(context: context)
        box.name = name
        box.location = location
        box.comment = comment
        box.code = Int64(code)
        box.imageUUID = imageUUID
        save()

        lastBoxID = code
    }

    func editBoxBG(box: Box,
                 name: String,
                 location: Location,
                 comment: String,
                 code: Int,
                 imageUUID: String,
                 callback: @escaping () -> ()) {

        if
            let box = try? backgroundContext.existingObject(with: box.objectID) as? Box,
            let location = try? backgroundContext.existingObject(with: location.objectID) as? Location {

            backgroundContext.perform { [weak self] in
                box.name = name
                box.location = location
                box.comment = comment
                box.code = Int64(code)
                box.imageUUID = imageUUID
                try? self?.backgroundContext.save()
                DispatchQueue.main.async {
                    callback()
                }
            }
        }

    }

    /// Edit an existing box
    func editBox(box: Box,
                 name: String,
                 location: Location,
                 comment: String,
                 code: Int,
                 imageUUID: String?) {
        box.name = name
        box.location = location
        box.comment = comment
        box.code = Int64(code)
        box.imageUUID = imageUUID
        save()

    }

    /// Delete a box
    /// - Parameter box: Box to be deleted
    /// - Parameter keepItems: If true, items will be kept, having `box` parameter set to nil
    func delete(_ box: Box, keepItems: Bool = false) {
        if let identifier = box.imageUUID {
            imageStore.delete(identifier)
                .sink { }
                .store(in: &imageOperations)
        }
        if let items = box.items?.allObjects as? [Item] {
            if keepItems {
                for item in items {
                    item.box = nil
                }
            } else {
                for item in items {
                    delete(item, save: false)
                }
            }
        }
        delete(box.objectID)
    }


    // MARK: - Item

//    /// Get all items
//    var items: [Item] {
//        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
//        return (try? context.fetch(fetchRequest)) ?? []
//    }

    /// Add a new item
    func addItem(name: String,
                 box: Box?,
                 keywords: String,
                 comment: String,
                 barcode: String?,
                 imageIdentifiers: [ImageStore.Identifier]) {
        let item = Item(context: context)
        item.name = name
        item.box = box
        item.keywords = keywords
        item.comment = comment
        item.barcode = barcode
        item.imageIdentifiers = imageIdentifiers
        save()
    }

    /// Edit an existing item
    func editItem(_ item: Item,
                  name: String,
                  box: Box?,
                  keywords: String,
                  comment: String,
                  barcode: String?,
                  imageIdentifiers: [ImageStore.Identifier]) {
        item.name = name
        item.box = box
        item.keywords = keywords
        item.comment = comment
        item.barcode = barcode
        item.imageIdentifiers = imageIdentifiers
        save()
    }


    /// Delete an item
    func delete(_ item: Item, save: Bool = true) {
        let imageIdentifiers = item.imageIdentifiers
        if !imageIdentifiers.isEmpty {
            imageStore.delete(imageIdentifiers)
                .sink { }
                .store(in: &imageOperations)
        }
        delete(item.objectID, save: save)
    }


    // MARK: - Images

    /// Create a new image cache
    /// - Parameter images: Images to be initailly in cache
    func imageCache(initial images: [ImageStore.Identifier]) -> ImageCache {
        ImageCache(imageStore, initial: images)
    }

}
