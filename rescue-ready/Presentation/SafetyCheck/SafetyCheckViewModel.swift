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
        // Submission stays disabled until the safety
        // validation contract is agreed and implemented.
        false
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

    func dismissSaveResult() {
        saveState = .idle
    }

    private static func message(for error: Error) -> String {
        let domainError = (error as? DomainError) ?? .storageFailure
        return domainError.errorDescription ?? "An unexpected error occurred."
    }
}
