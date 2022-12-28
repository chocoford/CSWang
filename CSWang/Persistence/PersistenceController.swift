//
//  PersistenceController.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/15.
//

import Foundation
import CoreData
import OSLog

struct PersistenceController {
    // A singleton for our entire app to use
    static let shared = PersistenceController()
    
    let logger = Logger(subsystem: "com.chocoford.CSWang", category: "persistence")

    
    // Storage for Core Data
    let container: NSPersistentContainer
    
    // An initializer to load Core Data, optionally able
    // to use an in-memory store.
    init(inMemory: Bool = false) {
        // If you didn't name your model Main you'll need
        // to change this name below.
        container = NSPersistentContainer(name: "Model")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
    
    
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Show some error here
            }
        }
    }
}

private extension PersistenceController {
    /// Creates and configures a private queue context.
    private func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    
    private func newBatchInsertRequest<T: Codable>(with propertyList: [T], entity: NSEntityDescription) -> NSBatchInsertRequest {
        var index = 0
        let total = propertyList.count

        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: entity, dictionaryHandler: { dictionary in
            guard index < total else { return true }
            dictionary.addEntries(from: propertyList[index].dictionary)
            index += 1
            return false
        })
        return batchInsertRequest
    }
}


extension PersistenceController {
    public func importWorkspaces(_ workspaces: [WorkspaceData]) async throws {
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importContext"
        taskContext.transactionAuthor = "importWorkspaces"
        
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            let batchInsertRequest = self.newBatchInsertRequest(with: workspaces, entity: Workspace.entity())
            if let fetchResult = try? taskContext.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                return
            }
            self.logger.debug("Failed to execute batch insert request.")
            throw ModelError.batchInsertError
        }
    }
}

extension PersistenceController {
    public func loadWorkspaces() async throws {
        
    }
}


#if DEBUG
extension PersistenceController {
    // A test configuration for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        
        
        return controller
    }()
}
#endif
