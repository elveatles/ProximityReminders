//
//  AppDelegate.swift
//  ProximityReminders
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    /// Location manager that should be used throughout the app.
    static let locationManager = LocationManager()
    /// Core data manager that should be used throughout the app for saving, editing, deleting managed objects.
    static let coreDataManager = CoreDataManager(persistentContainer: persistentContainer)
    /// Called when user notification authorization status changes.
    /// Parameters are the same as completion handler for `UNUserNotificationCenter.requestAuthorization`.
    static var userNotifAuthChanged: ((Bool, Error?) -> Void)?
    
    /// The persistent container that will be used in coreDataManager.
    static var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "ProximityReminders")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        
        AppDelegate.locationManager.geofenceDelegate = self
        UNUserNotificationCenter.current().delegate = self
        // Request authorization for location.
        AppDelegate.locationManager.locManager.requestAlwaysAuthorization()
        // Request authorization for notifications.
        let notificationOptions: UNAuthorizationOptions = [.badge, .sound, .alert]
        UNUserNotificationCenter.current().requestAuthorization(options: notificationOptions) { (success, error) in
            DispatchQueue.main.async {
                AppDelegate.userNotifAuthChanged?(success, error)
            }
        }
        
        // Start monitoring saved active reminders.
        let activeReminders = Reminder.fetchActive(context: AppDelegate.coreDataManager.context)
        AppDelegate.locationManager.startMonitoring(reminders: activeReminders)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // Clear notifications
        application.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.reminder == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    
    /**
     Show a notification for a region.
     
     Finds the reminder with the same address as the region identfier and shows a notification with reminder's note.
     
     - Parameter region: The region to show a notification for.
     */
    func showNotification(for region: CLRegion) {
        guard let reminder = Reminder.fetchByAddress(region.identifier, context: AppDelegate.coreDataManager.context) else {
            print("AppDelegate.showNotification: Could not find reminder with identifier: \(region.identifier)")
            return
        }
        
        if UIApplication.shared.applicationState == .active {
            // If application is active, show an alert.
            window?.rootViewController?.showAlert(title: reminder.locationName, message: reminder.note)
            handleNotification(for: reminder)
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
    
    /**
     Handle a notification given a reminder.
     
     If the reminder is not recurring, set the reminder to inactive.
     
     - Parameter reminder: The reminder to handle.
    */
    func handleNotification(for reminder: Reminder) {
        // If the reminder is not recurring, change it to inactive and stop monitoring for it.
        if !reminder.isRecurring {
            print("reminder inactive")
            reminder.isActiveCP = false
            AppDelegate.coreDataManager.save()
            AppDelegate.locationManager.stopMonitoring(reminder: reminder)
        }
    }
}


extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        showNotification(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        showNotification(for: region)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Find the reminder associated with the notification
        let request = response.notification.request
        guard let reminder = Reminder.fetchByAddress(request.identifier, context: AppDelegate.coreDataManager.context) else {
            print("userNotificationCenter didReceive response: Could not find reminder with identifier: \(request.identifier)")
            completionHandler()
            return
        }
        
        handleNotification(for: reminder)
        completionHandler()
    }
}
