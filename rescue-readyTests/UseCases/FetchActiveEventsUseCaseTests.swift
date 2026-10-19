import Foundation
import Testing
@testable import rescue_ready

struct FetchActiveEventsUseCaseTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func returnsOnlyEventsAcceptingPickups() async throws {
        let store = InMemoryDataStore()
        let live = Event(id: Identifier(), name: "Live Concert", venue: "Arena",
                         startsAt: now.addingTimeInterval(-3600), endsAt: now.addingTimeInterval(3600))
        let upcoming = Event(id: Identifier(), name: "Tomorrow's Match", venue: "Stadium",
                             startsAt: now.addingTimeInterval(86_400), endsAt: now.addingTimeInterval(90_000))
        store.events = [live.id: live, upcoming.id: upcoming]

        let fixedNow = now
        let events = try await FetchActiveEventsUseCase(events: InMemoryEventRepository(store: store),
                                                        now: { fixedNow }).execute()

        #expect(events == [live])
    }

    @Test func mapsRepositoryFailureToStorageFailure() async {
        let repository = InMemoryEventRepository()
        repository.shouldFail = true
        let fixedNow = now

        await #expect(throws: DomainError.storageFailure) {
            try await FetchActiveEventsUseCase(events: repository, now: { fixedNow }).execute()
        }
    }
}
