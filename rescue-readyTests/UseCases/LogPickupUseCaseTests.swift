import Foundation
import Testing
@testable import rescue_ready

struct LogPickupUseCaseTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let store = InMemoryDataStore()
    let event: Event
    let rice = NewBatch(foodDescription: "Vegetable fried rice", weightKg: 8,
                        allergens: [.soy], allergensDeclared: true)

    init() {
        event = Event(id: Identifier(), name: "Test Match", venue: "Test Stadium",
                      startsAt: now.addingTimeInterval(-3600), endsAt: now.addingTimeInterval(3600))
        store.events[event.id] = event
    }

    private func makeUseCase(pickupsFail: Bool = false) -> LogPickupUseCase {
        let pickups = InMemoryPickupRepository(store: store)
        pickups.shouldFail = pickupsFail
        let fixedNow = now
        return LogPickupUseCase(events: InMemoryEventRepository(store: store), pickups: pickups, now: { fixedNow })
    }

    @Test func savesBatchesAwaitingCheckWithHoldWindowStartingAtPickup() async throws {
        let pickup = try await makeUseCase().execute(eventID: event.id, volunteerID: Identifier(), batches: [rice])

        let saved = Array(store.batches.values)
        #expect(store.pickups[pickup.id] == pickup)
        #expect(saved.count == 1)
        #expect(saved.first?.status == .awaitingCheck)
        #expect(saved.first?.holdWindow.startedAt == now)
        #expect(saved.first?.pickupID == pickup.id)
    }

    @Test func trimsWhitespaceFromFoodDescription() async throws {
        var draft = rice
        draft.foodDescription = "  Pasta bake \n"
        _ = try await makeUseCase().execute(eventID: event.id, volunteerID: Identifier(), batches: [draft])

        #expect(store.batches.values.first?.foodDescription == "Pasta bake")
    }

    @Test func rejectsEmptyBatchList() async {
        await #expect(throws: DomainError.noBatches) {
            try await makeUseCase().execute(eventID: event.id, volunteerID: Identifier(), batches: [])
        }
    }

    @Test func rejectsUnknownEvent() async {
        await #expect(throws: DomainError.eventNotFound) {
            try await makeUseCase().execute(eventID: Identifier(), volunteerID: Identifier(), batches: [rice])
        }
    }

    @Test func rejectsEventMoreThanThreeHoursAfterItEnded() async {
        let finished = Event(id: Identifier(), name: "Old Gala", venue: "Hotel",
                             startsAt: now.addingTimeInterval(-8 * 3600), endsAt: now.addingTimeInterval(-4 * 3600))
        store.events[finished.id] = finished

        await #expect(throws: DomainError.eventNotActive) {
            try await makeUseCase().execute(eventID: finished.id, volunteerID: Identifier(), batches: [rice])
        }
    }

    @Test func rejectsBlankFoodDescription() async {
        var draft = rice
        draft.foodDescription = "   "
        await #expect(throws: DomainError.missingFoodDescription) {
            try await makeUseCase().execute(eventID: event.id, volunteerID: Identifier(), batches: [draft])
        }
    }

    @Test func rejectsZeroWeight() async {
        var draft = rice
        draft.weightKg = 0
        await #expect(throws: DomainError.invalidWeight) {
            try await makeUseCase().execute(eventID: event.id, volunteerID: Identifier(), batches: [draft])
        }
    }

    @Test func savesNothingWhenAnyBatchIsInvalid() async {
        var invalid = rice
        invalid.weightKg = -1
        _ = try? await makeUseCase().execute(eventID: event.id, volunteerID: Identifier(), batches: [rice, invalid])

        #expect(store.pickups.isEmpty)
        #expect(store.batches.isEmpty)
    }

    @Test func mapsRepositoryFailureToStorageFailure() async {
        await #expect(throws: DomainError.storageFailure) {
            try await makeUseCase(pickupsFail: true).execute(eventID: event.id, volunteerID: Identifier(), batches: [rice])
        }
    }
}
