//
//  AlertSound+CDClass.swift
//  WakyZzz
//
//  Created by Eric Stein on 4/7/20.
//  Copyright © 2020 Olga Volkova OC. All rights reserved.
//

import UIKit
import CoreData

class ManagingData {
    // This class will follow the singleton code design pattern to allow us to use a single instance of CoreDataManager object to provide data throughout the whole application.
    static let shared = ManagingData()
    
    private init() {
    }
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var fetchedRC: NSFetchedResultsController<AlertRing>!
    // Configure CoreData data store
    func refresh() {
        let request = AlertRing.fetchRequest() as NSFetchRequest<AlertRing>
        // Ascending stored alarms based on their time
        let sort = NSSortDescriptor(key: #keyPath(AlertRing.time), ascending: true)
        request.sortDescriptors = [sort]
        fetchedRC = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedRC.performFetch()
        } catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
        }
    }
    
}

extension ManagingData {
    // This method used to fetch a particular stored alarm using its creationDateID attribute
    func fetchAlarm(with alarmCreationDateID: String) -> AlertRing? {
        let request = AlertRing.fetchRequest() as NSFetchRequest<AlertRing>

            request.predicate = NSPredicate(format: "creationDateID == %@", alarmCreationDateID)
        do {
            return try context.fetch(request).first
        } catch let error as NSError {
            print("could not fetch. \(error), \(error.userInfo)")
        }
        return nil
    }
}
