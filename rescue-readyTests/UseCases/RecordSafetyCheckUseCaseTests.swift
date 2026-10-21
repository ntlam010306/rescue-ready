//
//  Untitled.swift
//  rescue-ready
//
//  Created by Lam Nguyen on 21/10/2026.
//

import Foundation
import Testing
@testable import rescue_ready

struct RecordSafetyCheckUseCaseTests {

    let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeBatch(
        allergensDeclared: Bool = true,
        elapsedSeconds: TimeInterval = 0
    ) throws -> FoodBatch {
        FoodBatch(
            id: Identifier(),
            pickupID: Identifier(),
            foodDescription: "Vegetable fried rice",
            weight: try Weight(kilograms: 8),
            allergens: [.soy],
            allergensDeclared: allergensDeclared,
            holdWindow: HoldWindow(
                startedAt: now.addingTimeInterval(-elapsedSeconds)
            ),
            status: .awaitingCheck,
            dropPointID: nil,
            discardReason: nil
        )
    }

    @Test
    func fixtureCreatesBatchAwaitingCheck() throws {
        let batch = try makeBatch()

        #expect(batch.status == .awaitingCheck)
        #expect(batch.allergensDeclared)
        #expect(batch.holdWindow.startedAt == now)
    }

    @Test
    func fixtureSupportsMissingAllergenDeclaration() throws {
        let batch = try makeBatch(allergensDeclared: false)

        #expect(batch.allergensDeclared == false)
    }

    @Test
    func fixtureSupportsHoldTimeScenarios() throws {
        let batch = try makeBatch(elapsedSeconds: 3600)

        #expect(
            batch.holdWindow.startedAt ==
            now.addingTimeInterval(-3600)
        )
    }
    
    // MARK: - Repository Tests

    @Test
    func loadsExistingBatchSuccessfully() async throws {
        let batch = try makeBatch()

        let store = InMemoryDataStore()
        store.batches[batch.id] = batch

        let repository = InMemoryBatchRepository(store: store)

        let useCase = RecordSafetyCheckUseCase(
            batches: repository,
            now: { now }
        )

        let result = try await useCase.loadBatch(id: batch.id)

        #expect(result == batch)
    }

    @Test
    func rejectsUnknownBatch() async {
        let repository = InMemoryBatchRepository()

        let useCase = RecordSafetyCheckUseCase(
            batches: repository,
            now: { now }
        )

        await #expect(throws: DomainError.batchNotFound) {
            try await useCase.loadBatch(id: Identifier<FoodBatch>())
        }
    }

    @Test
    func mapsRepositoryFailureToDomainError() async {
        let repository = InMemoryBatchRepository()
        repository.shouldFail = true

        let useCase = RecordSafetyCheckUseCase(
            batches: repository,
            now: { now }
        )

        await #expect(throws: DomainError.storageFailure) {
            try await useCase.loadBatch(id: Identifier<FoodBatch>())
        }
    }
}

