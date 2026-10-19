import Foundation

/// Storage for pickups and the batches collected in them.
/// Implementations throw `RepositoryError` on storage failures.
protocol PickupRepository {
    /// Saves a pickup together with its batches in one operation.
    func save(_ pickup: Pickup, batches: [FoodBatch]) async throws

    func pickup(id: Identifier<Pickup>) async throws -> Pickup?

    /// Pickups for an event, most recent first.
    func pickups(for eventID: Identifier<Event>) async throws -> [Pickup]
}
