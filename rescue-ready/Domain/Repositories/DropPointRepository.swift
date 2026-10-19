import Foundation

/// Read access to drop points. Implementations throw `RepositoryError` on storage failures.
protocol DropPointRepository {
    /// All drop points, sorted by name.
    func all() async throws -> [DropPoint]

    func dropPoint(id: Identifier<DropPoint>) async throws -> DropPoint?
}
