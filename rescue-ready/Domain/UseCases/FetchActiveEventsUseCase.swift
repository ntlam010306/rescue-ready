import Foundation

/// Lists the events a volunteer can log a pickup against right now.
struct FetchActiveEventsUseCase {
    let events: EventRepository
    let now: () -> Date

    func execute() async throws -> [Event] {
        do {
            return try await events.events(acceptingPickupsAt: now())
        } catch {
            throw DomainError.storageFailure
        }
    }
}
