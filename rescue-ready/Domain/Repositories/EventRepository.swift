import Foundation

/// Read access to events. Implementations throw `RepositoryError` on storage failures.
protocol EventRepository {
    func event(id: Identifier<Event>) async throws -> Event?

    /// Events that accept pickups at `date`, earliest start first.
    func events(acceptingPickupsAt date: Date) async throws -> [Event]
}
