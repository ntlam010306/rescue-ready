//
//  SafetyCheckViewModelTests.swift
//  rescue-ready
//
//  Created by Lam Nguyen on 21/10/2026.
//


import Foundation
import Testing
@testable import rescue_ready

@MainActor
struct SafetyCheckViewModelTests {

    @Test
    func loadBatchResetsAllergenConfirmation() async throws {

        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let batch = FoodBatch(
            id: Identifier(),
            pickupID: Identifier(),
            foodDescription: "Vegetable fried rice",
            weight: try Weight(kilograms: 8),
            allergens: [.soy],
            allergensDeclared: true,
            holdWindow: HoldWindow(startedAt: now),
            status: .awaitingCheck,
            dropPointID: nil,
            discardReason: nil
        )

        let store = InMemoryDataStore()
        store.batches[batch.id] = batch

        let repository = InMemoryBatchRepository(store: store)

        let useCase = RecordSafetyCheckUseCase(
            batches: repository,
            now: { now }
        )

        let viewModel = SafetyCheckViewModel(
            recordSafetyCheck: useCase,
            batchID: batch.id
        )

        // Simulate an earlier user confirmation.
        viewModel.allergensConfirmed = true

        await viewModel.load()

        // Verify the correct batch was loaded.
        #expect(viewModel.batch == batch)

        // Verify loading completed successfully.
        #expect(viewModel.loadState == .loaded)

        // A new check requires fresh confirmation.
        #expect(viewModel.allergensConfirmed == false)

        // Submission must remain disabled for now.
        #expect(viewModel.canSubmit == false)
    }
    
    
    @Test
    func loadNonexistentBatchShowsError() async {

        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let repository = InMemoryBatchRepository()

        let useCase = RecordSafetyCheckUseCase(
            batches: repository,
            now: { now }
        )

        let viewModel = SafetyCheckViewModel(
            recordSafetyCheck: useCase,
            batchID: Identifier<FoodBatch>()
        )

        await viewModel.load()

        // No batch should be loaded.
        #expect(viewModel.batch == nil)

        // ViewModel should display the correct error.
        #expect(
            viewModel.loadState == .failed(
                DomainError.batchNotFound.errorDescription ?? ""
            )
        )

        // Safety check must remain unavailable.
        #expect(viewModel.canSubmit == false)
    }
    
    @Test
    func repositoryFailureShowsStorageError() async {

        let now = Date(timeIntervalSince1970: 1_800_000_000)

        // Simulate a repository failure.
        let repository = InMemoryBatchRepository()
        repository.shouldFail = true

        let useCase = RecordSafetyCheckUseCase(
            batches: repository,
            now: { now }
        )

        let viewModel = SafetyCheckViewModel(
            recordSafetyCheck: useCase,
            batchID: Identifier<FoodBatch>()
        )

        await viewModel.load()

        // No batch should be available.
        #expect(viewModel.batch == nil)

        // The storage error should reach the UI state.
        #expect(
            viewModel.loadState == .failed(
                DomainError.storageFailure.errorDescription ?? ""
            )
        )

        // Submission must remain disabled.
        #expect(viewModel.canSubmit == false)
    }

}
