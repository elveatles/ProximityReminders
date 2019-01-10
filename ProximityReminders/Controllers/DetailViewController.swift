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
    /// The map item chosen for the reminder location.
    var mapItem: MKMapItem? {
        didSet {
            updateLocationUI()
        }
    }
    /// Renders overlays.
    lazy var mapDelegate = MapDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = mapDelegate
        
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppDelegate.locationManager.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocationSearch" {
            // Pass the current location to the location search view controller.
            let controller = segue.destination as! LocationSearchController
            controller.delegate = self
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
            reminderToSave.locationAddress = LocationManager.address(from: mapItem.placemark)
        }
        
        AppDelegate.coreDataManager.save()
        
        if reminderToSave.isActive {
            AppDelegate.locationManager.startMonitoring(reminder: reminderToSave)
        } else {
            AppDelegate.locationManager.stopMonitoring(reminder: reminderToSave)
        }
        
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
    
    /// Update the location button text and the map annotation.
    func updateLocationUI() {
        // Need either a mapItem or a reminder to get location information.
        guard mapItem != nil || reminder != nil else {
            locationButton.setTitle("Tap here to set location", for: .normal)
            
            mapView.removeOverlays(mapView.overlays)
            mapView.removeAnnotations(mapView.annotations)
            return
        }
        
        // Use either the current map item or the saved Reminder data.
        if let mapItem = mapItem {
            let address = LocationManager.address(from: mapItem.placemark)
            locationButton.setTitle(address, for: .normal)
            
            MapHelpers.addAnnotation(to: mapView, with: mapItem.placemark)
        } else if let reminder = reminder {
            locationButton.setTitle(reminder.locationAddress, for: .normal)
            
            MapHelpers.addAnnotation(to: mapView, with: reminder)
        }
    }
    
    /// Configure the view for a new reminder.
    private func configureViewNew() {
        noteLabel.text = ""
        extraNoteLabel.text = ""
        isEnterReminderControl.selectedSegmentIndex = isEnterTrueIndex
        isRecurringControl.selectedSegmentIndex = isRecurringTrueIndex
        isActiveSwitch.isOn = true
        mapItem = nil
        
        updateLocationUI()
        
        // Request location then show it on the map.
        if let location = AppDelegate.locationManager.locManager.location {
            MapHelpers.showLocation(with: mapView, coordinate: location.coordinate)
        }
        AppDelegate.locationManager.locManager.requestLocation()
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
        
        updateLocationUI()
    }
}


extension DetailViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        MapHelpers.showLocation(with: mapView, coordinate: location.coordinate)
    }
}


extension DetailViewController: LocationSearchResultsDelegate {
    func selectedMapItem(_ mapItem: MKMapItem) {
        self.mapItem = mapItem
    }
}
