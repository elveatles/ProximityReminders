//
//  ReminderNonGenerated.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

extension Reminder {
    /**
     Fetch all active reminders.
     
     - Parameter context: The managed object context to fetch from.
     - Returns: All active reminders.
    */
    static func fetchActive(context: NSManagedObjectContext) -> [Reminder] {
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        do {
            let reminders = try context.fetch(fetchRequest)
            return reminders
        } catch {
            print("Reminder.fetchActive error: \(error.localizedDescription)")
            return []
        }
    }
    
    /**
     Convenience function for fetching a reminder by its address which is also used as the geofence region identifier.
     
     - Parameter address: The address of the reminder to fetch.
     - Parameter context: The managed object context to fetch from.
     - Returns: The reminder with the matching address. nil if not found or a fetch error occurred.
    */
    static func fetchByAddress(_ address: String, context: NSManagedObjectContext) -> Reminder? {
        let request: NSFetchRequest<Reminder> = fetchRequest()
        request.predicate = NSPredicate(format: "locationAddress == %@", address)
        do {
            let reminders = try context.fetch(request)
            return reminders.first
        } catch {
            print("Reminder.fetchByAddress error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Convenient way to get/set locationLatitude and locationLongitude as a CLLocation.
    var location: CLLocation {
        get {
            return CLLocation(latitude: locationLatitude, longitude: locationLongitude)
        }
        
        set {
            locationLatitude = newValue.coordinate.latitude
            locationLongitude = newValue.coordinate.longitude
        }
    }
    
    /// Update the section base on the state of isActive.
    func updateSection() {
        if isActive {
            section = "Active Reminders"
        } else {
            section = "Inactive Reminders"
        }
    }
}
