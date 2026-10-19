import CoreData
import Foundation
import Testing
@testable import rescue_ready

struct CoreDataPickupRepositoryTests {
    let controller = PersistenceController(inMemory: true)
    let now = Date()

    @Test func storeLoadsInMemory() {
        #expect(controller.isAvailable)
    }

    @Test func savesPickupAndReadsItBackForItsEvent() async throws {
        try await CoreDataSeeder.seedIfEmpty(controller.container, now: now)
        let events = CoreDataEventRepository(container: controller.container)
        let activeEvents = try await events.events(acceptingPickupsAt: now)
        let event = try #require(activeEvents.first)

        let pickup = Pickup(id: Identifier(), eventID: event.id,
                            volunteerID: SampleData.volunteer.id, collectedAt: now)
        let batch = FoodBatch(id: Identifier(), pickupID: pickup.id, foodDescription: "Lamb curry",
                              weight: try Weight(kilograms: 6), allergens: [.milk], allergensDeclared: true,
                              holdWindow: HoldWindow(startedAt: now), status: .awaitingCheck)

        let repository = CoreDataPickupRepository(container: controller.container)
        try await repository.save(pickup, batches: [batch])

        let fetched = try await repository.pickup(id: pickup.id)
        let saved = try #require(fetched)
        #expect(saved.id == pickup.id)
        #expect(saved.eventID == event.id)

        let eventPickups = try await repository.pickups(for: event.id)
        #expect(eventPickups.contains { $0.id == pickup.id })
    }

    @Test func saveThrowsNotFoundWhenEventDoesNotExist() async {
        let repository = CoreDataPickupRepository(container: controller.container)
        let pickup = Pickup(id: Identifier(), eventID: Identifier(),
                            volunteerID: Identifier(), collectedAt: now)

        await #expect(throws: RepositoryError.notFound) {
            try await repository.save(pickup, batches: [])
        }
    }

    @Test func seedingRunsOnlyOnce() async throws {
        let first = try await CoreDataSeeder.seedIfEmpty(controller.container, now: now)
        let second = try await CoreDataSeeder.seedIfEmpty(controller.container, now: now)
        #expect(first)
        #expect(!second)
    }
}
