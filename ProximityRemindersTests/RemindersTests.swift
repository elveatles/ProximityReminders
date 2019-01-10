//
//  RemindersTests.swift
//  ProximityRemindersTests
//
//  Created by Erik Carlson on 1/8/19.
//  Copyright © 2019 Round and Rhombus. All rights reserved.
//

import XCTest
import CoreData
@testable import ProximityReminders

class RemindersTests: XCTestCase {
    /// The CoreDataManager to test with.
    var coreDataManager: CoreDataManager!
    /// This is used to fetch a reminder by its note.
    let reminderNote = "TestReminder"
    let reminderAddress = "6801 Hollywood Blvd, Hollywood, CA"
    
    /// Create an in-memory persistent container.
    func createMockContainer() -> NSPersistentContainer {
        let result = NSPersistentContainer(name: "ProximityReminders")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        result.persistentStoreDescriptions = [description]
        result.loadPersistentStores(completionHandler: { (theDescription, error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            precondition(theDescription.type == NSInMemoryStoreType)
        })
        return result
    }
    
    /// Delete all reminder objects that were created.
    func flushData() {
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        let reminders = try! coreDataManager.fetch(fetchRequest)
        for reminder in reminders {
            coreDataManager.delete(reminder)
        }
        coreDataManager.save()
    }
    
    /// Creates a reminder
    /// - Returns: The reminder that is created.
    @discardableResult func createReminder() -> Reminder {
        let result = Reminder(context: coreDataManager.context)
        result.timestamp = Date()
        result.locationLatitude = 50
        result.locationLongitude = 120
        result.locationName = "TCL Chinese Theater"
        result.locationAddress = reminderAddress
        result.note = reminderNote
        result.extraNote = "Extra"
        result.isEnterReminder = true
        result.isActive = true
        result.updateSection()
        return result
    }
    
    /// Fetch the reminder that was created with `createReminder`.
    /// - Returns: The fetched reminder. nil if the reminder was not created.
    func fetchReminder() -> Reminder? {
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        request.predicate = NSPredicate(format: "note = %@", reminderNote)
        do {
            let reminders = try coreDataManager.fetch(request)
            return reminders.first
        } catch {
            return nil
        }
    }
    
    override func setUp() {
        let mockContainer = createMockContainer()
        coreDataManager = CoreDataManager(persistentContainer: mockContainer)
    }

    override func tearDown() {
        flushData()
    }
    
    func testCreate() {
        createReminder()
        coreDataManager.save()
        let fetchedReminder = fetchReminder()
        XCTAssertNotNil(fetchedReminder)
    }
    
    func testEdit() {
        createReminder()
        coreDataManager.save()
        guard let fetchedReminder = fetchReminder() else {
            XCTFail("fetchedReminder could not be fetched.")
            return
        }
        fetchedReminder.locationName = "Hobbiton"
        coreDataManager.save()
        guard let changedReminder = fetchReminder() else {
            XCTFail("changedReminder could not be fetched.")
            return
        }
        XCTAssertEqual(changedReminder.locationName, "Hobbiton")
    }
    
    func testDelete() {
        let reminder = createReminder()
        coreDataManager.save()
        coreDataManager.delete(reminder)
        coreDataManager.save()
        let fetchedReminder = fetchReminder()
        XCTAssertNil(fetchedReminder)
    }
    
    func testFetchActive() {
        createReminder()
        let inactiveReminder = createReminder()
        inactiveReminder.isActive = false
        coreDataManager.save()
        let reminders = Reminder.fetchActive(context: coreDataManager.context)
        XCTAssertEqual(reminders.count, 1)
    }
    
    func testFetchByAddress() {
        createReminder()
        coreDataManager.save()
        let fetchedReminder = Reminder.fetchByAddress(reminderAddress, context: coreDataManager.context)
        XCTAssertNotNil(fetchedReminder)
    }
}
