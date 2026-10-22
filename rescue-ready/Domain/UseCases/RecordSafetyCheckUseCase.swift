//
//  RecordSafetyCheckUseCase.swift
//  rescue-ready
//
//  Created by Lam Nguyen on 21/10/2026.
//

import Foundation

/// Handles the domain workflow for recording a food batch safety check.
/// Safety validation rules will be implemented after
/// the team confirms the food handling requirements.
/// Input submitted by a volunteer for a safety check.
struct SafetyCheckInput {
    let batchID: Identifier<FoodBatch>
    let temperatureCelsius: Double
    let allergensConfirmed: Bool
}

enum SafetyCheckEligibilityError: LocalizedError, Equatable {
    case alreadyChecked

    var errorDescription: String? {
        switch self {
        case .alreadyChecked:
            return "This batch has already been checked."
        }
    }
}

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
    
    /// Loads a batch and rejects batches that are already closed.
    func loadOpenBatch(
        id: Identifier<FoodBatch>
    ) async throws -> FoodBatch {

        let batch = try await loadBatch(id: id)

        guard batch.status.isOpen else {
            throw DomainError.batchAlreadyClosed
        }

        return batch
    }
    
    /// Validates a temperature reading before recording a safety check.
    ///
    /// This checks input plausibility only.
    /// It does not determine whether food is safe.
    func validateTemperature(
        from input: SafetyCheckInput
    ) throws -> Temperature {

        try Temperature(celsius: input.temperatureCelsius)
    }
    
    /// Only batches awaiting their first safety check
    /// are eligible for validation.
    func loadCheckableBatch(
        id: Identifier<FoodBatch>
    ) async throws -> FoodBatch {

        let batch = try await loadOpenBatch(id: id)

        guard batch.status == .awaitingCheck else {
            throw SafetyCheckEligibilityError.alreadyChecked
        }

        return batch
    }
    
    /// Ensures allergen information has been declared
    /// and reviewed by the volunteer.
    ///
    /// Missing confirmation blocks submission but does
    /// not permanently fail the batch.
    func validateAllergens(
        for batch: FoodBatch,
        input: SafetyCheckInput
    ) throws {

        guard batch.allergensDeclared,
              input.allergensConfirmed else {
            throw DomainError.allergensUndeclared
        }
    }
    
    /// Prepares a batch for safety evaluation.
    ///
    /// Validates batch eligibility, temperature input,
    /// and allergen confirmation.
    ///
    /// Does not determine food safety or save a check.
    func prepareCheck(
        _ input: SafetyCheckInput
    ) async throws -> (
        batch: FoodBatch,
        temperature: Temperature
    ) {

        // 1. Ensure the batch exists and can be checked.
        let batch = try await loadCheckableBatch(
            id: input.batchID
        )

        // 2. Validate the temperature reading.
        let temperature = try validateTemperature(
            from: input
        )

        // 3. Confirm the allergen information.
        try validateAllergens(
            for: batch,
            input: input
        )

        return (batch, temperature)
    }
}
