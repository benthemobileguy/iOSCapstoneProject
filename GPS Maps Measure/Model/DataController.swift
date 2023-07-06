//
//  DataController.swift
//  Created by Ben on July 06, 2023.
//

import Foundation
import CoreData

class DataController {

    let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    let backgroundContext: NSManagedObjectContext!

    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)

        backgroundContext = persistentContainer.newBackgroundContext()
    }

    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true

        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }

    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.configureContexts()
            completion?()
        }
    }
}
