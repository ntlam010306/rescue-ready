import Foundation

final class InMemoryPickupRepository: PickupRepository {
    private let store: InMemoryDataStore
    /// Set to true to make every call throw, for testing error handling.
    var shouldFail = false

    init(store: InMemoryDataStore = InMemoryDataStore()) {
        self.store = store
    }

    func save(_ pickup: Pickup, batches: [FoodBatch]) async throws {
        if shouldFail { throw RepositoryError.saveFailed }
        store.pickups[pickup.id] = pickup
        for batch in batches {
            store.batches[batch.id] = batch
        }
    }

    func pickup(id: Identifier<Pickup>) async throws -> Pickup? {
        if shouldFail { throw RepositoryError.fetchFailed }
        return store.pickups[id]
    }

    func pickups(for eventID: Identifier<Event>) async throws -> [Pickup] {
        if shouldFail { throw RepositoryError.fetchFailed }
        return store.pickups.values
            .filter { $0.eventID == eventID }
            .sorted { $0.collectedAt > $1.collectedAt }
    }
}
