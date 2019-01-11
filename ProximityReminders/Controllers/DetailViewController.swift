//
//  DetailViewController.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import UIKit
import MapKit
import UserNotifications

/// Allows the user to setup a reminder and save it.
class DetailViewController: UIViewController {
    /// Fields that must be filled out for a reminder to be saved.
    enum RequiredFields: String {
        case note
        case location
    }
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var noteLabel: UITextField!
    @IBOutlet weak var extraNoteLabel: UITextField!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var isEnterReminderControl: UISegmentedControl!
    @IBOutlet weak var isRecurringControl: UISegmentedControl!
    @IBOutlet weak var isActiveSwitch: UISwitch!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var errorBanner: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
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
        
        noteLabel.delegate = self
        extraNoteLabel.delegate = self
        mapView.delegate = mapDelegate
        AppDelegate.userNotifAuthChanged = userNotifAuthChanged
        
        configureView()
        updateAuthorizationUI()
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
        reminderToSave.isActiveCP = isActiveSwitch.isOn
        
        // Location
        if let mapItem = mapItem, let location = mapItem.placemark.location {
            reminderToSave.location = location
            reminderToSave.locationName = mapItem.name ?? ""
            reminderToSave.locationAddress = LocationManager.address(from: mapItem.placemark)
        }
        
        AppDelegate.coreDataManager.save()
        
        if reminderToSave.isActiveCP {
            AppDelegate.locationManager.startMonitoring(reminder: reminderToSave)
        } else {
            AppDelegate.locationManager.stopMonitoring(reminder: reminderToSave)
        }
        
        let isCollapsed = splitViewController?.isCollapsed ?? true
        if isCollapsed {
            goBackToMaster()
        } else {
            navigationController?.navigationBar.titleTextAttributes = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor(red: 126.0/255.0, green: 155.0/255.0, blue: 94.0/255.0, alpha: 1.0)
            ]
            navigationItem.title = "Saved!"
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (timer) in
                self.navigationItem.title = ""
            }
        }
    }
    
    /// Delete the current reminder.
    @IBAction func deleteReminder(_ sender: UIBarButtonItem) {
        guard let reminder = reminder else { return }
        
        let alert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete this reminder?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { (action) in
            AppDelegate.coreDataManager.delete(reminder)
            AppDelegate.coreDataManager.save()
            
            let isCollapsed = self.splitViewController?.isCollapsed ?? true
            if isCollapsed {
                self.goBackToMaster()
            } else {
                self.reminder = nil
            }
        }
        alert.addAction(yesAction)
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        alert.addAction(noAction)
        present(alert, animated: true, completion: nil)
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
            let name = mapItem.name ?? ""
            let address = LocationManager.address(from: mapItem.placemark)
            let title = "\(name): \(address)"
            locationButton.setTitle(title, for: .normal)
            
            MapHelpers.addAnnotation(to: mapView, with: mapItem.placemark)
        } else if let reminder = reminder {
            let title = "\(reminder.locationName): \(reminder.locationAddress)"
            locationButton.setTitle(title, for: .normal)
            
            MapHelpers.addAnnotation(to: mapView, with: reminder)
        }
    }
    
    /// Show error messages to the user if the app is not authorized to track the user's location or send notifications.
    func updateAuthorizationUI() {
        errorBanner.isHidden = true
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            DispatchQueue.main.async {
                self.errorBanner.isHidden = settings.authorizationStatus == .authorized
                if settings.authorizationStatus != .authorized {
                    self.errorLabel.text = "This app will not work properly without notifications allowed."
                }
            }
        }
        
        let status = CLLocationManager.authorizationStatus()
        if status != .authorizedAlways {
            errorBanner.isHidden = false
            errorLabel.text = "This app will not work properly without 'always' access to location."
        }
    }
    
    /// Configure the view for a new reminder.
    private func configureViewNew() {
        deleteButton.isEnabled = false
        
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
        
        deleteButton.isEnabled = true
        
        noteLabel.text = reminder.note
        extraNoteLabel.text = reminder.extraNote
        isEnterReminderControl.selectedSegmentIndex = reminder.isEnterReminder ? isEnterTrueIndex : isEnterFalseIndex
        isRecurringControl.selectedSegmentIndex = reminder.isRecurring ? isRecurringTrueIndex : isRecurringFalseIndex
        isActiveSwitch.setOn(reminder.isActiveCP, animated: true)
        mapItem = nil
        
        updateLocationUI()
    }
}


extension DetailViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateAuthorizationUI()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        MapHelpers.showLocation(with: mapView, coordinate: location.coordinate)
    }
}

// UserNotifications.
extension DetailViewController {
    func userNotifAuthChanged(success: Bool, error: Error?) {
        updateAuthorizationUI()
    }
}


extension DetailViewController: LocationSearchResultsDelegate {
    func selectedMapItem(_ mapItem: MKMapItem) {
        self.mapItem = mapItem
    }
}


extension DetailViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
