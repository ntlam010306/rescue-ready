import Foundation

final class InMemoryBatchRepository: BatchRepository {
    private let store: InMemoryDataStore
    /// Set to true to make every call throw, for testing error handling.
    var shouldFail = false

    init(store: InMemoryDataStore = InMemoryDataStore()) {
        self.store = store
    }

    func batch(id: Identifier<FoodBatch>) async throws -> FoodBatch? {
        if shouldFail { throw RepositoryError.fetchFailed }
        return store.batches[id]
    }

    func openBatches() async throws -> [FoodBatch] {
        if shouldFail { throw RepositoryError.fetchFailed }
        return store.batches.values
            .filter { $0.status.isOpen }
            .sorted { $0.holdWindow.expiresAt < $1.holdWindow.expiresAt }
    }

    func batches(withStatus status: BatchStatus) async throws -> [FoodBatch] {
        if shouldFail { throw RepositoryError.fetchFailed }
        return store.batches.values
            .filter { $0.status == status }
            .sorted { $0.holdWindow.expiresAt < $1.holdWindow.expiresAt }
    }

    func update(_ batch: FoodBatch) async throws {
        if shouldFail { throw RepositoryError.saveFailed }
        guard store.batches[batch.id] != nil else { throw RepositoryError.notFound }
        store.batches[batch.id] = batch
    }

    func record(_ check: SafetyCheck, updating batch: FoodBatch) async throws {
        if shouldFail { throw RepositoryError.saveFailed }
        guard store.batches[batch.id] != nil else { throw RepositoryError.notFound }
        store.checks.append(check)
        store.batches[batch.id] = batch
    }

    func checks(for batchID: Identifier<FoodBatch>) async throws -> [SafetyCheck] {
        if shouldFail { throw RepositoryError.fetchFailed }
        return store.checks
            .filter { $0.batchID == batchID }
            .sorted { $0.checkedAt < $1.checkedAt }
    }
}
