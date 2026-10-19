import CoreData
import Foundation

extension NSPersistentContainer {
    /// Runs `work` on a fresh background context.
    ///
    /// Any error that is not already a `RepositoryError` is rolled back and replaced
    /// with `failure`, so Core Data details never leak past the repository layer.
    func performBackground<T>(
        failure: RepositoryError,
        _ work: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return try await context.perform {
            do {
                return try work(context)
            } catch let error as RepositoryError {
                context.rollback()
                throw error
            } catch {
                context.rollback()
                throw failure
            }
        }
    }
}

extension NSManagedObjectContext {
    /// Fetches the single object of `type` whose `id` attribute matches.
    func fetchOne<T: NSManagedObject>(_ type: T.Type, id: UUID) throws -> T? {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try fetch(request).first
    }
}
