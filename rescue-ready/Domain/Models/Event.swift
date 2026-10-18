import Foundation

/// An event that produces surplus food, such as a concert, match or hotel function.
struct Event: Identifiable, Equatable {
    /// Pickups are accepted up to this long after an event ends.
    static let pickupGracePeriod: TimeInterval = 3 * 60 * 60

    let id: Identifier<Event>
    var name: String
    var venue: String
    var startsAt: Date
    var endsAt: Date

    func acceptsPickups(at now: Date) -> Bool {
        now >= startsAt && now <= endsAt.addingTimeInterval(Self.pickupGracePeriod)
    }
}
