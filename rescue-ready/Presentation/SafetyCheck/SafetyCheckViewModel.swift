//
//  SafetyCheckViewModel.swift
//  rescue-ready
//
//  Created by Lam Nguyen on 21/10/2026.
//


import Foundation
import Observation

/// State and actions for the Safety Check screen.
@MainActor
@Observable
final class SafetyCheckViewModel {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case requiresReview(String)
        case failed(String)
    }

    private(set) var batch: FoodBatch?
    private(set) var loadState: LoadState = .idle
    private(set) var saveState: SaveState = .idle

    // User inputs
    var temperatureInput: String = ""
    var allergensConfirmed: Bool = false

    private let recordSafetyCheck: RecordSafetyCheckUseCase
    private let batchID: Identifier<FoodBatch>

    init(
        recordSafetyCheck: RecordSafetyCheckUseCase,
        batchID: Identifier<FoodBatch>
    ) {
        self.recordSafetyCheck = recordSafetyCheck
        self.batchID = batchID
    }

    var canSubmit: Bool {

        // The batch must be loaded successfully.
        guard loadState == .loaded,
              let batch else {
            return false
        }

        // Only batches awaiting their first check are eligible.
        guard batch.status == .awaitingCheck else {
            return false
        }

        // Allergen information must be declared and confirmed.
        guard batch.allergensDeclared,
              allergensConfirmed else {
            return false
        }

        // Never enable recording without an assessor.
        guard recordSafetyCheck.assessor != nil else {
            return false
        }

        // Prevent submissions while saving or after recording.
        guard saveState != .saving,
              saveState != .saved else {
            return false
        }

        // Validate the temperature input.
        let text = temperatureInput.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let temperature = Double(text) else {
            return false
        }

        return Temperature.plausibleRange.contains(temperature)
    }

    func load() async {
        loadState = .loading

        do {
            batch = try await recordSafetyCheck.loadBatch(id: batchID)

            // Restore existing allergen declaration information.
            allergensConfirmed = false
            
            loadState = .loaded
        } catch {
            loadState = .failed(Self.message(for: error))
        }
    }

    func submit() async {

        // Prevent duplicate submissions.
        guard saveState != .saving else {
            return
        }

        // Ensure a batch has been loaded.
        guard let batch else {
            saveState = .failed(
                "Food batch has not been loaded."
            )
            return
        }

        // Convert temperature input into a number.
        let temperatureText = temperatureInput
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let temperature = Double(temperatureText) else {
            saveState = .failed(
                "Enter a valid temperature in °C."
            )
            return
        }

        saveState = .saving

        do {
            let input = SafetyCheckInput(
                batchID: batch.id,
                temperatureCelsius: temperature,
                allergensConfirmed: allergensConfirmed
            )

            let result = try await recordSafetyCheck.execute(input)

            switch result {

            case .recorded(let check):
                // Repository has already saved the result.
                var updatedBatch = batch

                updatedBatch.status = check.outcome.isPassed
                    ? .cleared
                    : .failedCheck

                self.batch = updatedBatch
                saveState = .saved

            case .requiresReview(let reason):
                // Do not mark the batch as cleared.
                saveState = .requiresReview(reason)
            }

        } catch {
            saveState = .failed(
                Self.message(for: error)
            )
        }
    }
    
    func dismissSaveResult() {
        saveState = .idle
    }

    private static func message(for error: Error) -> String {

        if let domainError = error as? DomainError {
            return domainError.errorDescription
                ?? "An unexpected error occurred."
        }

        if let eligibilityError = error as? SafetyCheckEligibilityError {
            return eligibilityError.errorDescription
                ?? "This batch cannot be checked again."
        }

        return "An unexpected error occurred."
    }
}
