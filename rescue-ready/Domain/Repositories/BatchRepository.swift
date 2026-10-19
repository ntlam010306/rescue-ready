import Foundation

/// Storage for food batches and their safety checks.
/// Implementations throw `RepositoryError` on storage failures.
protocol BatchRepository {
    func batch(id: Identifier<FoodBatch>) async throws -> FoodBatch?

    /// Batches that still need action, soonest hold-window expiry first.
    func openBatches() async throws -> [FoodBatch]

    /// Batches in a given status, soonest hold-window expiry first.
    func batches(withStatus status: BatchStatus) async throws -> [FoodBatch]

    /// Replaces a stored batch. Throws `RepositoryError.notFound` if it does not exist.
    func update(_ batch: FoodBatch) async throws

    /// Stores a safety check and the batch's resulting state in one operation.
    func record(_ check: SafetyCheck, updating batch: FoodBatch) async throws

    /// Safety checks for a batch, oldest first.
    func checks(for batchID: Identifier<FoodBatch>) async throws -> [SafetyCheck]
}
