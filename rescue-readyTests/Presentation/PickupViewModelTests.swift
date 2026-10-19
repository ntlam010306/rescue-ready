import Foundation
import Testing
@testable import rescue_ready

@MainActor
struct PickupViewModelTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let store = InMemoryDataStore()
    let pickups: InMemoryPickupRepository
    let event: Event
    let rice = NewBatch(foodDescription: "Vegetable fried rice", weightKg: 8,
                        allergens: [.soy], allergensDeclared: true)

    init() {
        event = Event(id: Identifier(), name: "Test Match", venue: "Test Stadium",
                      startsAt: now.addingTimeInterval(-3600), endsAt: now.addingTimeInterval(3600))
        store.events[event.id] = event
        pickups = InMemoryPickupRepository(store: store)
    }

    private func makeViewModel() -> PickupViewModel {
        let events = InMemoryEventRepository(store: store)
        let fixedNow = now
        return PickupViewModel(
            logPickup: LogPickupUseCase(events: events, pickups: pickups, now: { fixedNow }),
            fetchActiveEvents: FetchActiveEventsUseCase(events: events, now: { fixedNow }),
            volunteerID: Identifier()
        )
    }

    @Test func loadSelectsFirstActiveEvent() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.selectedEventID == event.id)
    }

    @Test func cannotSaveWithoutBatches() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        #expect(!viewModel.canSave)
    }

    @Test func successfulSaveClearsBatches() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.addBatch(rice)

        await viewModel.save()

        #expect(viewModel.saveState == .saved)
        #expect(viewModel.batches.isEmpty)
        #expect(store.pickups.count == 1)
    }

    @Test func failedSaveKeepsBatchesAndShowsMessage() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.addBatch(rice)
        pickups.shouldFail = true

        await viewModel.save()

        #expect(viewModel.saveState == .failed(DomainError.storageFailure.errorDescription ?? ""))
        #expect(viewModel.batches.count == 1)
    }
}
