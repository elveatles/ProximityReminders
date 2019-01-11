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


/// Manages location-related things. Wraps CLLocationManager.
class LocationManager: NSObject {
    /// The radius of a geofenced region.
    static let geofenceRadius: CLLocationDistance = 50
    
    /// The location manger that this class wraps.
    let locManager: CLLocationManager
    /// Delegate for geofencing-related calls.
    weak var geofenceDelegate: CLLocationManagerDelegate?
    /// Forwards delegate method calls from the manager.
    weak var delegate: CLLocationManagerDelegate?
    
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
}


extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        delegate?.locationManager?(manager, didChangeAuthorization: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationManager?(manager, didUpdateLocations: locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        geofenceDelegate?.locationManager?(manager, didEnterRegion: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        geofenceDelegate?.locationManager?(manager, didEnterRegion: region)
    }
    
    // Error handling
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let clError = error as? CLError else {
            print("locationManager didFailWithError: Could not cast error to CLError.")
            return
        }
        
        guard let errorCode = CLError.Code(rawValue: clError.errorCode) else {
            print("locationManager didFailWithError: Could not get errorCode as enum.")
            return
        }
        
        switch errorCode {
        case .denied:
            print("locationManger didFailWithError: denied.")
        case .locationUnknown:
            print("locationManager didFailWithError: locationUnknown.")
        default:
            print("locationManager didFailWithError: error code not handled: \(errorCode)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("locationManager monitoringDidFailFor region: \(error.localizedDescription)")
    }
}
