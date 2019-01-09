//
//  ReminderNonGenerated.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import Foundation
import CoreLocation

extension Reminder {
    /// Convenient way to get locationLatitude and locationLongitude as a CLLocation.
    var location: CLLocation {
        return CLLocation(latitude: locationLatitude, longitude: locationLongitude)
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
