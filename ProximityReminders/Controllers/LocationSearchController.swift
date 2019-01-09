//
//  LocationSearchController.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import UIKit
import MapKit

/// Search for a location to add to a reminder.
class LocationSearchController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    /// The number of meters to show when a coordinate of a map is focused on.
    let mapRegionMeters: CLLocationDistance = 1000
    /// The current map item chosen.
    var selectedMapItem: MKMapItem?
    
    /// The search bar to find a location by name
    lazy var searchController: UISearchController = {
        let name = String(describing: LocationSearchResultsController.self)
        let searchResultsController = storyboard!.instantiateViewController(withIdentifier: name) as! LocationSearchResultsController
        searchResultsController.mapView = mapView
        searchResultsController.delegate = self
        let result = UISearchController(searchResultsController: searchResultsController)
        result.searchResultsUpdater = searchResultsController
        result.searchBar.placeholder = "Search for places"
        return result
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppDelegate.locationManager.delegate = self
        
        navigationItem.searchController = searchController
        // This is necessary otherwise the search bar will be covered by the search results controller.
        definesPresentationContext = true
        
        AppDelegate.locationManager.requestWhenInUseAuthorization()
        AppDelegate.locationManager.requestLocation()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension LocationSearchController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            AppDelegate.locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: mapRegionMeters, longitudinalMeters: mapRegionMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager didFailWithError: \(error.localizedDescription)")
    }
}


extension LocationSearchController: LocationSearchResultsDelegate {
    func selectedMapItem(_ mapItem: MKMapItem) {
        // Show an annotation on the map for the newly selected map item
        selectedMapItem = mapItem
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        let placemark = mapItem.placemark
        annotation.coordinate = placemark.coordinate
        annotation.title = mapItem.name
        let locality = placemark.locality ?? "" // city
        let administrativeArea = placemark.administrativeArea ?? "" // state
        annotation.subtitle = "\(locality) \(administrativeArea)"
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: mapRegionMeters, longitudinalMeters: mapRegionMeters)
        mapView.setRegion(region, animated: true)
        
        searchController.searchBar.text = ""
    }
}
