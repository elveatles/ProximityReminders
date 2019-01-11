//
//  MasterViewController.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import UIKit
import CoreData

// Displays a list of saved reminders.
class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    /// Data source for the table view.
    lazy var remindersDataSource: RemindersDataSource = {
        return RemindersDataSource(remindersTableView: tableView)
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        tableView.dataSource = remindersDataSource
        remindersDataSource.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            // Get the destination detail view controller
            let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
            detailViewController = controller
            
            // If a cell was selected, set the detail view controller's reminder to the same reminder as the selected cell.
            if let indexPath = tableView.indexPathForSelectedRow {
                let reminder = remindersDataSource.object(at: indexPath)
                controller.reminder = reminder
            } else {
                // New reminder.
                controller.reminder = nil
            }
            
            // Master/view navigation bar fiddly stuff.
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    @IBAction func addReminder(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showDetail", sender: nil)
    }
}


extension MasterViewController: RemindersDataSourceDelegate {
    func willDeleteReminder(_ reminder: Reminder) {
        // Change to creating a new reminder so that the user
        // won't try to save the old deleted reminder.
        detailViewController?.reminder = nil
    }
}
