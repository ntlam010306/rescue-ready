import CoreData
import Foundation
import Testing
@testable import rescue_ready

struct CoreDataBatchRepositoryTests {
    let controller = PersistenceController(inMemory: true)
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let hour: TimeInterval = 60 * 60

    var repository: CoreDataBatchRepository {
        CoreDataBatchRepository(container: controller.container)
    }

    /// Seeds the sample data, then saves a pickup with three batches whose hold windows
    /// start at different times. Returns the new batches and the seeded drop points.
    private func makeFixture() async throws -> (early: FoodBatch, late: FoodBatch, discarded: FoodBatch,
                                                dropPoints: [DropPoint]) {
        try await CoreDataSeeder.seedIfEmpty(controller.container, now: now)

        let activeEvents = try await CoreDataEventRepository(container: controller.container)
            .events(acceptingPickupsAt: now)
        let event = try #require(activeEvents.first)
        let pickup = Pickup(id: Identifier(), eventID: event.id,
                            volunteerID: SampleData.volunteer.id, collectedAt: now)

        let early = try makeBatch("Beef lasagne", pickupID: pickup.id,
                                  startedAt: now.addingTimeInterval(-3 * hour), status: .awaitingCheck)
        let late = try makeBatch("Fruit platter", pickupID: pickup.id,
                                 startedAt: now.addingTimeInterval(-0.25 * hour), status: .cleared)
        let discarded = try makeBatch("Prawn rolls", pickupID: pickup.id,
                                      startedAt: now.addingTimeInterval(-2 * hour), status: .discarded)

        try await CoreDataPickupRepository(container: controller.container)
            .save(pickup, batches: [early, late, discarded])

        let dropPoints = try await CoreDataDropPointRepository(container: controller.container).all()
        return (early, late, discarded, dropPoints)
    }

    private func makeBatch(_ description: String, pickupID: Identifier<Pickup>,
                           startedAt: Date, status: BatchStatus) throws -> FoodBatch {
        FoodBatch(id: Identifier(), pickupID: pickupID, foodDescription: description,
                  weight: try Weight(kilograms: 4), allergens: [], allergensDeclared: true,
                  holdWindow: HoldWindow(startedAt: startedAt), status: status)
    }

    private func storedBatch(_ id: Identifier<FoodBatch>) async throws -> FoodBatch {
        let batch = try await repository.batch(id: id)
        return try #require(batch)
    }

    // MARK: - Fetching

    @Test func openBatchesExcludeClosedBatchesAndSortBySoonestExpiry() async throws {
        let fixture = try await makeFixture()

        let open = try await repository.openBatches()

        #expect(!open.isEmpty)
        #expect(open.allSatisfy { $0.status.isOpen })
        #expect(!open.contains { $0.id == fixture.discarded.id })
        #expect(open.map(\.holdWindow.expiresAt) == open.map(\.holdWindow.expiresAt).sorted())
        #expect(open.first?.id == fixture.early.id)
        #expect(open.last?.id == fixture.late.id)
    }

    @Test func batchesWithStatusReturnOnlyThatStatus() async throws {
        _ = try await makeFixture()

        let failed = try await repository.batches(withStatus: .failedCheck)

        #expect(!failed.isEmpty)
        #expect(failed.allSatisfy { $0.status == .failedCheck })
    }

    @Test func unknownBatchIDReturnsNil() async throws {
        _ = try await makeFixture()

        let missing = try await repository.batch(id: Identifier())

        #expect(missing == nil)
    }

    // MARK: - Updating

    @Test func handoverIsSavedWithItsDropPoint() async throws {
        let fixture = try await makeFixture()
        let dropPoint = try #require(fixture.dropPoints.first)

        var handedOver = fixture.late
        handedOver.status = .handedOver
        handedOver.dropPointID = dropPoint.id
        try await repository.update(handedOver)

        let stored = try await storedBatch(handedOver.id)
        #expect(stored.status == .handedOver)
        #expect(stored.dropPointID == dropPoint.id)
    }

    @Test func discardIsSavedWithItsReason() async throws {
        let fixture = try await makeFixture()

        var discarded = fixture.early
        discarded.status = .discarded
        discarded.discardReason = "Lid missing during transport"
        try await repository.update(discarded)

        let stored = try await storedBatch(discarded.id)
        #expect(stored.status == .discarded)
        #expect(stored.discardReason == "Lid missing during transport")
    }

    @Test func updatingUnknownBatchThrowsNotFound() async throws {
        let fixture = try await makeFixture()
        let stranger = try makeBatch("Not in the store", pickupID: fixture.late.pickupID,
                                     startedAt: now, status: .cleared)

        await #expect(throws: RepositoryError.notFound) {
            try await repository.update(stranger)
        }
    }

    @Test func unknownDropPointThrowsNotFoundAndLeavesBatchUnchanged() async throws {
        let fixture = try await makeFixture()

        var handedOver = fixture.late
        handedOver.status = .handedOver
        handedOver.dropPointID = Identifier()

        await #expect(throws: RepositoryError.notFound) {
            try await repository.update(handedOver)
        }
        let stored = try await storedBatch(fixture.late.id)
        #expect(stored.status == .cleared)
        #expect(stored.dropPointID == nil)
    }

    // MARK: - Safety checks

    @Test func recordStoresCheckAndNewBatchStatusTogether() async throws {
        let fixture = try await makeFixture()

        let check = SafetyCheck(id: Identifier(), batchID: fixture.early.id,
                                temperature: try Temperature(celsius: 3.5),
                                checkedAt: now, outcome: .passed)
        var cleared = fixture.early
        cleared.status = .cleared
        try await repository.record(check, updating: cleared)

        let stored = try await storedBatch(fixture.early.id)
        let checks = try await repository.checks(for: fixture.early.id)
        #expect(stored.status == .cleared)
        #expect(checks == [check])
    }

    @Test func checksAreReturnedOldestFirst() async throws {
        let fixture = try await makeFixture()
        let batchID = fixture.early.id

        let failed = SafetyCheck(id: Identifier(), batchID: batchID,
                                 temperature: try Temperature(celsius: 22),
                                 checkedAt: now.addingTimeInterval(-600),
                                 outcome: .failed(reason: "Temperature in danger zone"))
        let passed = SafetyCheck(id: Identifier(), batchID: batchID,
                                 temperature: try Temperature(celsius: 4),
                                 checkedAt: now, outcome: .passed)

        // Recorded newest first to show the repository, not insertion order, sets the order.
        try await repository.record(passed, updating: fixture.early)
        try await repository.record(failed, updating: fixture.early)

        let checks = try await repository.checks(for: batchID)
        #expect(checks.map(\.id) == [failed.id, passed.id])
        #expect(checks.first?.outcome == .failed(reason: "Temperature in danger zone"))
    }
}
