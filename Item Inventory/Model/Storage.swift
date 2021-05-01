//
//  Storage.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import Foundation
import CoreData
import OSLog

class Storage {

    private var container: NSPersistentContainer
    
    private(set) var context: NSManagedObjectContext

    private var backgroundContext: NSManagedObjectContext

    static let shared = Storage()

    private let imagesDirectory: URL

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

        imagesDirectory = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("images", isDirectory: true)

        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            } catch {
                Logger.storage.error("Cannot create directory")
            }
        }

        if let contents = try? FileManager.default.contentsOfDirectory(atPath: imagesDirectory.path) {
            print("Contents: ", contents)
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
    func delete(_ id: NSManagedObjectID) {
        if let object = try? context.existingObject(with: id) {
            context.delete(object)
            context.perform {
                self.save()
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

    // MARK: - Box

    private let LAST_BOX_ID_KEY = "lastBoxId"


    /// ID of the last saved box
    var lastBoxID: Int {
        get { UserDefaults.standard.integer(forKey: LAST_BOX_ID_KEY) }
        set { UserDefaults.standard.set(newValue, forKey: LAST_BOX_ID_KEY)}
    }

    /// Check if a box with given id exists
    func hasBox(with id: Int) -> Bool {
        let fetchRequest: NSFetchRequest<Box> = Box.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %i", id)
        let count = (try? context.count(for: fetchRequest)) ?? 0
        return count > 0
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

    func editBox(box: Box,
                 name: String,
                 location: Location,
                 comment: String,
                 code: Int,
                 imageUUID: String?) {


        // Delete old image
        if let oldImageUUID = box.imageUUID, (imageUUID == nil || (imageUUID != nil && imageUUID! != oldImageUUID)) {
            deleteImage(with: oldImageUUID)
        }

        box.name = name
        box.location = location
        box.comment = comment
        box.code = Int64(code)
        box.imageUUID = imageUUID
        save()

    }

    /// Delete a box
    func delete(_ box: Box) {
        if let imageUUID = box.imageUUID {
            deleteImage(with: imageUUID)
        }
        delete(box.objectID)
    }

    // MARK: - Images

    /// Create image path from URL
    func imageURL(for uuid: String) -> URL {
        imagesDirectory.appendingPathComponent(uuid + ".jpg")
    }

    /// Save an image
    func saveImage(_ data: Data) -> String {
        var url: URL
        var uuid: String

        repeat {
            uuid = UUID().uuidString
            url = self.imageURL(for: uuid)
        } while FileManager.default.fileExists(atPath: url.path)

        do {
            try data.write(to: url)
        } catch {
            Logger.storage.error("Cannot save file")
        }

        return uuid
    }

    /// Delete an image from URL
    func deleteImage(with uuid: String) {
        do {
            try FileManager.default.removeItem(at: imageURL(for: uuid))
        } catch {
            Logger.storage.error("Cannot delete file")
        }
    }



}
