import Foundation

/// Shared in-memory storage behind the in-memory repositories.
///
/// Repositories built on the same store see each other's writes, so a pickup saved
/// through `InMemoryPickupRepository` shows up in `InMemoryBatchRepository`.
/// Used for SwiftUI previews, unit tests, and running the app before Core Data is wired in.
final class InMemoryDataStore {
    var events: [Identifier<Event>: Event] = [:]
    var volunteers: [Identifier<Volunteer>: Volunteer] = [:]
    var pickups: [Identifier<Pickup>: Pickup] = [:]
    var batches: [Identifier<FoodBatch>: FoodBatch] = [:]
    var checks: [SafetyCheck] = []
    var dropPoints: [Identifier<DropPoint>: DropPoint] = [:]

    init() {}
}
