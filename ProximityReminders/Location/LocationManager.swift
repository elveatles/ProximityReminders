//
//  LocationManager.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/9/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import UserNotifications


/// Used as a delegate to get reminders.
protocol ReminderDataSource: class {
    /// Get a reminder given an identfier (probably the location address).
    /// - Parameter identifier: The identifier to use to fetch a reminder.
    /// - Returns: The reminder found with the given identifier. nil if a matching reminder was not found.
    func reminderForIdentifier(_ identifier: String) -> Reminder?
}

/// Manages location-related things. Wraps CLLocationManager.
class LocationManager: NSObject {
    /// The radius of a geofenced region.
    static let geofenceRadius: CLLocationDistance = 50
    
    /// The location manger that this class wraps.
    let locManager: CLLocationManager
    /// Forwards delegate method calls from the manager.
    weak var delegate: CLLocationManagerDelegate?
    /// Get reminders when needed.
    weak var reminderDataSource: ReminderDataSource?
    
    /**
     Get a full address name from a placemark.
     
     - Parameter placemark: The placemark to get the address from.
     - Returns: The full address name from the placemark.
     */
    static func address(from placemark: CLPlacemark) -> String {
        let subThoroughfare = placemark.subThoroughfare ?? "" // street number
        let thoroughfare = placemark.thoroughfare ?? "" // street name
        let locality = placemark.locality ?? "" // city
        let administrativeArea = placemark.administrativeArea ?? "" // state
        return "\(subThoroughfare) \(thoroughfare), \(locality) \(administrativeArea)"
    }
    
    override init() {
        locManager = CLLocationManager()
        
        super.init()
        
        locManager.delegate = self
    }
    
    /**
     Start monitoring an array of reminders.
     
     Stops monitoring all current regions being monitored.
     
     - Parameter reminders: The reminders to monitor.
    */
    func startMonitoring(reminders: [Reminder]) {
        // Stop monitoring all regions
        for region in locManager.monitoredRegions {
            locManager.stopMonitoring(for: region)
        }
        
        for reminder in reminders {
            startMonitoring(reminder: reminder)
        }
    }
    
    /**
     Start monitoring reminder using geofencing.
     
     - Parameter reminder: The reminder to monitor.
    */
    func startMonitoring(reminder: Reminder) {
        print("start monitoring: \(reminder.locationAddress)")
        // Not sure if address is the best thing to use as an identifier.
        let region = CLCircularRegion(center: reminder.location.coordinate, radius: LocationManager.geofenceRadius, identifier: reminder.locationAddress)
        region.notifyOnEntry = reminder.isEnterReminder
        region.notifyOnExit = !reminder.isEnterReminder
        locManager.startMonitoring(for: region)
    }
    
    /**
     Stop monitoring a reminder.
     
     - Parameter reminder: The reminder to stop monitoring.
    */
    func stopMonitoring(reminder: Reminder) {
        print("stop monitoring: \(reminder.locationAddress)")
        // Find the region that matches the reminder.
        let region = locManager.monitoredRegions.first { $0.identifier == reminder.locationAddress }
        guard let theRegion = region else { return }
        locManager.stopMonitoring(for: theRegion)
    }
    
    /**
     Show a notification for a region.
     
     Finds the reminder with the same address as the region identfier and shows a notification with reminder's note.
     
     - Parameter region: The region to show a notification for.
    */
    func showNotification(for region: CLRegion) {
        guard let dataSource = reminderDataSource else {
            print("LocationManager.showNotification: Could not show a notification because reminderDataSource is nil.")
            return
        }
        
        guard let reminder = dataSource.reminderForIdentifier(region.identifier) else {
            print("LocationManager.showNotification: Could not find reminder with identifier: \(region.identifier)")
            return
        }
        
        if UIApplication.shared.applicationState == .active {
            // If application is active, show an alert.
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController?.showAlert(title: reminder.locationName, message: reminder.note)
        } else {
            // If application is not active create a notification.
            let notificationContent = UNMutableNotificationContent()
            notificationContent.body = "\(reminder.locationName): \(reminder.note)"
            notificationContent.sound = UNNotificationSound.default
            notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
            // nil trigger means send notification right away.
            let request = UNNotificationRequest(identifier: region.identifier, content: notificationContent, trigger: nil)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print("Notification error: \(error.localizedDescription)")
                    return
                }
            }
        }
    }
}


extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationManager?(manager, didUpdateLocations: locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion: \(region)")
        showNotification(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("didExitRegion: \(region)")
        showNotification(for: region)
    }
    
    // Error handling
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager didFailWithError: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("locationManager monitoringDidFailFor region: \(error.localizedDescription)")
    }
}


// Doing it this way so that fetching data can easily be decoupled with LocationManger if needed.
// Right now, this is relying on AppDelegate.coreDataManager.
extension LocationManager: ReminderDataSource {
    func reminderForIdentifier(_ identifier: String) -> Reminder? {
        return Reminder.fetchByAddress(identifier, context: AppDelegate.coreDataManager.context)
    }
}
