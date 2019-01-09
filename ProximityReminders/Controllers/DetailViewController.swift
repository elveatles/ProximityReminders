//
//  DetailViewController.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import UIKit
import MapKit

/// Allows the user to setup a reminder and save it.
class DetailViewController: UIViewController {
    /// Fields that must be filled out for a reminder to be saved.
    enum RequiredFields: String {
        case note
        case location
    }
    
    @IBOutlet weak var noteLabel: UITextField!
    @IBOutlet weak var extraNoteLabel: UITextField!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var isEnterReminderControl: UISegmentedControl!
    @IBOutlet weak var isRecurringControl: UISegmentedControl!
    @IBOutlet weak var isActiveSwitch: UISwitch!
    @IBOutlet weak var mapView: MKMapView!
    
    /// The number of meters to show when a coordinate of a map is focused on.
    let mapRegionMeters: CLLocationDistance = 1000
    /// The index of the segmented control that means isEnterReminder is true.
    let isEnterTrueIndex = 0
    /// The index of the segmented control that means isEnterReminder is false.
    let isEnterFalseIndex = 1
    /// The index of the segmented control that means isRecurring is true.
    let isRecurringTrueIndex = 0
    /// The index of the segmented control that means isRecurring is false.
    let isRecurringFalseIndex = 1
    /// The reminder to edit. If nil, a new reminder will be created.
    var reminder: Reminder? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }
    /// The location the device is currently at.
    var currentLocation: CLLocation?
    /// The map item chosen for the reminder location.
    var mapItem: MKMapItem? {
        didSet {
            guard let theMapItem = mapItem else { return }
            
            let address = AppDelegate.address(from: theMapItem.placemark)
            
            // Set the location button title to be the location address.
            locationButton.setTitle(address, for: .normal)
            
            // Show location on the map.
            mapView.removeAnnotations(mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = theMapItem.placemark.coordinate
            annotation.title = theMapItem.name
            annotation.subtitle = address
            mapView.addAnnotation(annotation)
            let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: mapRegionMeters, longitudinalMeters: mapRegionMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppDelegate.locationManager.delegate = self
        AppDelegate.locationManager.requestWhenInUseAuthorization()
        
        configureView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocationSearch" {
            // Pass the current location to the location search view controller.
            let controller = segue.destination as! LocationSearchController
            controller.delegate = self
            controller.currentLocation = currentLocation
        }
    }
    
    // Save the reminder.
    @IBAction func saveReminder(_ sender: UIBarButtonItem) {
        // Check for missing required fields.
        let missingFields = checkRequiredFields()
        // If fields are missing show an alert.
        guard missingFields.isEmpty else {
            let fieldStrings = missingFields.map { $0.rawValue }
            let details = fieldStrings.joined(separator: "\n")
            let message = "You are missing some required fields.\n\n\(details)"
            showAlert(title: "Missing Fields", message: message)
            return
        }
        
        // Create or edit Reminder.
        let reminderToSave = reminder ?? Reminder(context: AppDelegate.coreDataManager.context)
        reminderToSave.note = noteLabel.text ?? ""
        reminderToSave.extraNote = extraNoteLabel.text ?? ""
        reminderToSave.isEnterReminder = isEnterReminderControl.selectedSegmentIndex == isEnterTrueIndex
        reminderToSave.isRecurring = isRecurringControl.selectedSegmentIndex == isRecurringTrueIndex
        reminderToSave.isActive = isActiveSwitch.isOn
        reminderToSave.updateSection()
        // Location
        if let mapItem = mapItem, let location = mapItem.placemark.location {
            reminderToSave.location = location
            reminderToSave.locationName = mapItem.name ?? ""
            reminderToSave.locationAddress = AppDelegate.address(from: mapItem.placemark)
        }
        
        AppDelegate.coreDataManager.save()
        
        goBackToMaster()
    }
    
    /// Configure the view with `reminder`.
    func configureView() {
        if reminder == nil {
            configureViewNew()
        } else {
            configureViewEdit()
        }
    }
    
    /// Makes checks to make sure the user filled out all the required information needed to save a reminder.
    /// - Returns: Any required fields that were not filled out.
    func checkRequiredFields() -> Set<RequiredFields> {
        var result = Set<RequiredFields>()
        
        // note
        let note = noteLabel.text ?? ""
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.insert(.note)
        }
        
        // location
        if reminder == nil && mapItem == nil {
            result.insert(.location)
        }
        
        return result
    }
    
    // Because this is a master/detail view. We can't simply dismiss this view controller.
    func goBackToMaster() {
        navigationController?.navigationController?.popViewController(animated: true)
    }
    
    /// Configure the view for a new reminder.
    private func configureViewNew() {
        noteLabel.text = ""
        extraNoteLabel.text = ""
        isEnterReminderControl.selectedSegmentIndex = isEnterTrueIndex
        isRecurringControl.selectedSegmentIndex = isRecurringTrueIndex
        isActiveSwitch.isOn = true
        mapItem = nil
        // Requesting the location will show the current location on the map.
        AppDelegate.locationManager.requestLocation()
    }
    
    /// Configure the view for an edit reminder.
    private func configureViewEdit() {
        guard let reminder = reminder else {
            print("Could not configure view for edit because reminder is nil.")
            return
        }
        
        noteLabel.text = reminder.note
        extraNoteLabel.text = reminder.extraNote
        isEnterReminderControl.selectedSegmentIndex = reminder.isEnterReminder ? isEnterTrueIndex : isEnterFalseIndex
        isRecurringControl.selectedSegmentIndex = reminder.isRecurring ? isRecurringTrueIndex : isRecurringFalseIndex
        isActiveSwitch.isOn = reminder.isActive
        mapItem = nil
        
        locationButton.setTitle(reminder.locationAddress, for: .normal)
        
        // Show location on the map.
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = reminder.location.coordinate
        annotation.title = reminder.locationName
        annotation.subtitle = reminder.locationAddress
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: mapRegionMeters, longitudinalMeters: mapRegionMeters)
        mapView.setRegion(region, animated: true)
    }
}


extension DetailViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            AppDelegate.locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        currentLocation = location
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: mapRegionMeters, longitudinalMeters: mapRegionMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager didFailWithError: \(error.localizedDescription)")
    }
}


extension DetailViewController: LocationSearchResultsDelegate {
    func selectedMapItem(_ mapItem: MKMapItem) {
        self.mapItem = mapItem
    }
}
