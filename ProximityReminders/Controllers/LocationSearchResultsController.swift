//
//  LocationSearchResultsController.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import UIKit
import MapKit

/// Delegate for map searches.
protocol LocationSearchResultsDelegate: class {
    /// A map item was selected from the search results.
    func selectedMapItem(_ mapItem: MKMapItem);
}

/// A table view controller that shows location search results.
class LocationSearchResultsController: UITableViewController {
    /// The data used to populate the tableview
    var matchingItems: [MKMapItem] = []
    /// The map view used to help give the search some context of the area we are interested in.
    var mapView: MKMapView?
    /// Delegate for when selections are made.
    weak var delegate: LocationSearchResultsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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


// MARK: - Table view data source

extension LocationSearchResultsController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let selectedItem = matchingItems[indexPath.row]
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = LocationManager.address(from: selectedItem.placemark)
        return cell
    }
}

// MARK: - Table view delegate

extension LocationSearchResultsController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Call the delegate method to inform that an item was selected.
        let selectedItem = matchingItems[indexPath.row]
        delegate?.selectedMapItem(selectedItem)
        dismiss(animated: true, completion: nil)
    }
}


extension LocationSearchResultsController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView else { return }
        guard let searchText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                return
            }
            
            guard let response = response else { return }
            
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}
