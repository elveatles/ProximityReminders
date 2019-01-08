//
//  CoreDataManager.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import Foundation
import CoreData

/// Managest a core data stack and provides convenience functions for creating, saving, deleting, etc.
class CoreDataManager {
    let persistentContainer: NSPersistentContainer
    
    /// Convenience to get the managed object context from the persistent container.
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// Initialize with a given persistent container.
    /// - Parameter persistentContainer: The container that will be used for all CoreData changes.
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    /// Create a new NSManagedObject of a certain type.
    /// Uses the type name for the model name.
    /// Uses the persistentContainer context.
    func insertNewObject<T: NSManagedObject>() -> T {
        let name = String(describing: T.self)
        return NSEntityDescription.insertNewObject(forEntityName: name, into: context) as! T
    }
    
    /// Convenience for fetching objects.
    /// - Parameter request: The fetch request.
    func fetch<T>(_ request: NSFetchRequest<T>) throws -> [T] where T: NSFetchRequestResult {
        return try context.fetch(request)
    }
    
    /// Delete an NSManaged object.
    /// - Parameter object: The object to delete.
    func delete(_ object: NSManagedObject) {
        context.delete(object)
    }
    
    /// Save any CoreData changes.
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
