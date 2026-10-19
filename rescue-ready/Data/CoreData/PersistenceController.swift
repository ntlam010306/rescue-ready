import CoreData
import Foundation

/// Owns the Core Data stack.
///
/// The SQLite store lives in the shared App Group container so the app and the
/// home screen widget read the same data. Loading never crashes: a failure is
/// kept in `loadError` so the UI can show an error state instead.
final class PersistenceController {
    static let modelName = "rescue_ready"
    static let appGroupIdentifier = "group.sam.rao.au.rescue-ready"
    static let storeFileName = "RescueReady.sqlite"

    /// Loaded once and shared by every container. Loading the model more than once
    /// (for example in parallel tests) makes Core Data unable to match entity classes.
    static let model: NSManagedObjectModel = {
        guard let url = Bundle(for: PersistenceController.self).url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url) else {
            return NSManagedObjectModel()
        }
        return model
    }()

    let container: NSPersistentContainer
    private(set) var loadError: Error?

    var isAvailable: Bool { loadError == nil }

    /// - Parameter inMemory: true for tests and previews; nothing is written to disk.
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: Self.modelName, managedObjectModel: Self.model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        } else if let storeURL = Self.sharedStoreURL() {
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        }
        // If the App Group is unavailable, Core Data falls back to the app's own
        // container. The app still works; only the widget loses access to the data.

        container.loadPersistentStores { [weak self] _, error in
            self?.loadError = error
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    static func sharedStoreURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(storeFileName)
    }
}
