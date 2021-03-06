//
//  Reminder+CoreDataProperties.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//
//

import Foundation
import CoreData


extension Reminder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reminder> {
        return NSFetchRequest<Reminder>(entityName: "Reminder")
    }

    @NSManaged public var timestamp: Date
    @NSManaged public var isEnterReminder: Bool
    @NSManaged public var locationLatitude: Double
    @NSManaged public var locationLongitude: Double
    @NSManaged public var locationName: String
    @NSManaged public var locationAddress: String
    @NSManaged public var note: String
    @NSManaged public var extraNote: String
    @NSManaged public var isActive: Bool
    @NSManaged public var isRecurring: Bool
    @NSManaged public var section: String

}
