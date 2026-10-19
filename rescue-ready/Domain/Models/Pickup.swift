import Foundation

/// One collection run by a volunteer at an event. A pickup contains one or more batches.
struct Pickup: Identifiable, Equatable {
    let id: Identifier<Pickup>
    let eventID: Identifier<Event>
    let volunteerID: Identifier<Volunteer>
    let collectedAt: Date
}
