//
//  MapHelpers.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/9/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import MapKit

/// App-specific helpers relating to map views.
class MapHelpers {
    /// The meters to show when mapView.setRegion is used.
    static var regionMeters: CLLocationDistance = 500
    
    /**
     Show a location on the map view.
     
     - Parameter mapView: The map view to show the location in.
    */
    static func showLocation(with mapView: MKMapView, coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
        mapView.setRegion(region, animated: true)
    }
    
    /**
     Convenience function for adding an annotation with a circle around it to a map view.
     
     - Parameter mapView: The map view to add the annotation to.
     - Parameter placemark: The placemark to add to the map view as an annotation.
     */
    static func addAnnotation(to mapView: MKMapView, with placemark: CLPlacemark) {
        guard let location = placemark.location else {
            print("MapHelpers.addAnnotation placemark location is nil!")
            return
        }
        let title = placemark.name ?? ""
        let address = LocationManager.address(from: placemark)
        MapHelpers.addAnnotation(to: mapView, coordinate: location.coordinate, title: title, subtitle: address)
    }
    
    /**
     Convenience function for adding an annotation with a circle around it to a map view.
     
     - Parameter mapView: The map view to add the annotation to.
     - Parameter reminder: The reminder to add to the map view as an annotation.
     */
    static func addAnnotation(to mapView: MKMapView, with reminder: Reminder) {
        MapHelpers.addAnnotation(to: mapView, coordinate: reminder.location.coordinate, title: reminder.locationName, subtitle: reminder.locationAddress)
    }
    
    /**
     Convenience function for adding an annotation with a circle around it to a map view.
     
     - Parameter mapView: The map view to add the annotation to.
     - Parameter coordinate: The coordinate for the annotation.
     - Parameter title: The title of the annotation.
     - Parameter subtitle: The subtitle of the annotation.
    */
    static func addAnnotation(to mapView: MKMapView, coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // Add a circle showing the radius of the geofenced area.
        let circle = MKCircle(center: coordinate, radius: LocationManager.geofenceRadius)
        mapView.addOverlay(circle)
        
        // Add annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        mapView.addAnnotation(annotation)
        
        // Show the new placemark.
        showLocation(with: mapView, coordinate: annotation.coordinate)
    }
}
