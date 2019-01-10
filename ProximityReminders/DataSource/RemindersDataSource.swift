//
//  RemindersDataSource.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/9/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import UIKit
import CoreData

/// Provides data for a table view displaying reminders.
class RemindersDataSource: NSObject, UITableViewDataSource {
    /// The reminders table view this is linked to.
    let remindersTableView: UITableView
    
    /// The fetched results controller the fetches reminders for the table view.
    lazy var fetchedResultsController: NSFetchedResultsController<Reminder> = {
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: AppDelegate.coreDataManager.context, sectionNameKeyPath: "section", cacheName: "Master")
        aFetchedResultsController.delegate = self
        
        do {
            try aFetchedResultsController.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return aFetchedResultsController
    }()
    
    /**
     Initialize with the table view that this is the data source for.
     
     - Parameter reminderTableView: The reminders table view this object is linked to.
    */
    init(remindersTableView: UITableView) {
        self.remindersTableView = remindersTableView
    }
    
    /// Get a reminder object at the specified index path.
    /// - Parameter indexPath: The index path the reminder is at.
    /// - Returns: The reminder at the index path. nil if a bogus index path was used.
    func object(at indexPath: IndexPath) -> Reminder? {
        return fetchedResultsController.object(at: indexPath)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { return nil }
        return sectionInfo.name
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ReminderCell
        let reminder = fetchedResultsController.object(at: indexPath)
        cell.configure(with: reminder)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let reminder = fetchedResultsController.object(at: indexPath)
            AppDelegate.locationManager.stopMonitoring(reminder: reminder)
            
            AppDelegate.coreDataManager.delete(reminder)
            AppDelegate.coreDataManager.save()
        }
    }
}


extension RemindersDataSource: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        remindersTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            remindersTableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            remindersTableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            remindersTableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            remindersTableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            let cell = remindersTableView.cellForRow(at: indexPath!)! as! ReminderCell
            let reminder = anObject as! Reminder
            cell.configure(with: reminder)
        case .move:
            let cell = remindersTableView.cellForRow(at: indexPath!)! as! ReminderCell
            let reminder = anObject as! Reminder
            cell.configure(with: reminder)
            remindersTableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        remindersTableView.endUpdates()
    }
    
    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
     // In the simplest, most efficient, case, reload the table view.
     remindersTableView.reloadData()
     }
     */
}
