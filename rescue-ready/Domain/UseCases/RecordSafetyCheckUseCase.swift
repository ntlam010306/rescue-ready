//
//  RecordSafetyCheckUseCase.swift
//  rescue-ready
//
//  Created by Lam Nguyen on 21/10/2026.
//

import Foundation

/// Handles the domain workflow for recording a food batch safety check.
///
/// Safety validation rules will be implemented after
/// the team confirms the food handling requirements.
struct RecordSafetyCheckUseCase {

    let batches: any BatchRepository

    /// Injected to make time-dependent behaviour testable.
    let now: () -> Date

    /// Loads a batch before performing its safety check.
    func loadBatch(
        id: Identifier<FoodBatch>
    ) async throws -> FoodBatch {

        let batch: FoodBatch?

        do {
            batch = try await batches.batch(id: id)
        } catch {
            throw DomainError.storageFailure
        }

        guard let batch else {
            throw DomainError.batchNotFound
        }

        return batch
    }
}
