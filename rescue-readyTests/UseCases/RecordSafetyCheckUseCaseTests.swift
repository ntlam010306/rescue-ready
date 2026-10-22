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
    
    @Test
    func rejectsClosedBatches() async throws {

        for status in [BatchStatus.handedOver, .discarded] {

            var batch = try makeBatch()
            batch.status = status

            let store = InMemoryDataStore()
            store.batches[batch.id] = batch

            let repository = InMemoryBatchRepository(store: store)

            let useCase = RecordSafetyCheckUseCase(
                batches: repository,
                now: { now }
            )

            await #expect(throws: DomainError.batchAlreadyClosed) {
                try await useCase.loadOpenBatch(id: batch.id)
            }
        }
    }
    
    @Test
    func acceptsPlausibleTemperatureReading() throws {
        let repository = InMemoryBatchRepository()

        let useCase = RecordSafetyCheckUseCase(
            batches: repository,
            now: { now }
        )

        let input = SafetyCheckInput(
            batchID: Identifier<FoodBatch>(),
            temperatureCelsius: 20,
            allergensConfirmed: true
        )

        let temperature = try useCase.validateTemperature(from: input)

        #expect(temperature.celsius == 20)
    }

    @Test
    func rejectsImplausibleTemperatureReading() {
        let repository = InMemoryBatchRepository()

        let useCase = RecordSafetyCheckUseCase(
            batches: repository,
            now: { now }
        )

        let input = SafetyCheckInput(
            batchID: Identifier<FoodBatch>(),
            temperatureCelsius: 200,
            allergensConfirmed: true
        )

        #expect(throws: DomainError.invalidTemperatureReading) {
            try useCase.validateTemperature(from: input)
        }
    }
    
    @Test
    func allowsBatchAwaitingFirstCheck() async throws {

        let batch = try makeBatch()

        let store = InMemoryDataStore()
        store.batches[batch.id] = batch

        let repository = InMemoryBatchRepository(store: store)

        let useCase = RecordSafetyCheckUseCase(
            batches: repository,
            now: { now }
        )

        let result = try await useCase.loadCheckableBatch(
            id: batch.id
        )

        #expect(result.id == batch.id)
        #expect(result.status == .awaitingCheck)
    }

    @Test
    func rejectsPreviouslyCheckedBatches() async throws {

        for status in [BatchStatus.cleared, .failedCheck] {

            var batch = try makeBatch()
            batch.status = status

            let store = InMemoryDataStore()
            store.batches[batch.id] = batch

            let repository = InMemoryBatchRepository(store: store)

            let useCase = RecordSafetyCheckUseCase(
                batches: repository,
                now: { now }
            )

            await #expect(
                throws: SafetyCheckEligibilityError.alreadyChecked
            ) {
                try await useCase.loadCheckableBatch(id: batch.id)
            }
        }
    }
    
    @Test
    func acceptsConfirmedAllergens() throws {
        let batch = try makeBatch(allergensDeclared: true)

        let useCase = RecordSafetyCheckUseCase(
            batches: InMemoryBatchRepository(),
            now: { now }
        )

        let input = SafetyCheckInput(
            batchID: batch.id,
            temperatureCelsius: 20,
            allergensConfirmed: true
        )

        try useCase.validateAllergens(
            for: batch,
            input: input
        )
    }

    @Test
    func rejectsMissingAllergenConfirmation() throws {
        let useCase = RecordSafetyCheckUseCase(
            batches: InMemoryBatchRepository(),
            now: { now }
        )

        // Test all combinations that lack required confirmation.
        for (declared, confirmed) in [
            (true, false),
            (false, true),
            (false, false)
        ] {
            let batch = try makeBatch(
                allergensDeclared: declared
            )

            let input = SafetyCheckInput(
                batchID: batch.id,
                temperatureCelsius: 20,
                allergensConfirmed: confirmed
            )

            #expect(throws: DomainError.allergensUndeclared) {
                try useCase.validateAllergens(
                    for: batch,
                    input: input
                )
            }
        }
    }
    
    @Test
    func prepareCheckValidatesInputsWithoutSaving() async throws {

        // Arrange: Create an eligible batch.
        let batch = try makeBatch(allergensDeclared: true)

        let store = InMemoryDataStore()
        store.batches[batch.id] = batch

        let repository = InMemoryBatchRepository(store: store)

        let useCase = RecordSafetyCheckUseCase(
            batches: repository,
            now: { now }
        )

        let input = SafetyCheckInput(
            batchID: batch.id,
            temperatureCelsius: 20,
            allergensConfirmed: true
        )

        // Act: Prepare the safety check.
        let result = try await useCase.prepareCheck(input)

        // Assert: Correct batch and temperature returned.
        #expect(result.batch.id == batch.id)
        #expect(result.temperature.celsius == 20)

        // Assert: Batch status remains unchanged.
        let storedBatch = try await repository.batch(id: batch.id)
        #expect(storedBatch?.status == .awaitingCheck)

        // Assert: No safety check has been recorded yet.
        let recordedChecks = try await repository.checks(for: batch.id)
        #expect(recordedChecks.isEmpty)
    }
}

