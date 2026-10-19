import Foundation

/// Realistic demo data for previews, screenshots and running the app without Core Data.
enum SampleData {
    /// The volunteer the sample data is recorded against.
    /// Uses a fixed ID so the seeded volunteer still matches after the app relaunches.
    static let volunteer = Volunteer(
        id: Identifier(UUID(uuidString: "6F2C8A4E-3B1D-4C7A-9E55-2D8F1A0B7C31") ?? UUID()),
        name: "Priya Sharma"
    )

    /// A store filled with sample events, drop points, a pickup and batches.
    /// Times are relative to `now` so batches always show realistic time left.
    static func makeStore(now: Date = Date()) -> InMemoryDataStore {
        let store = InMemoryDataStore()
        do {
            try populate(store, now: now)
        } catch {
            // Sample values are fixed and valid; an empty store is a safe fallback.
        }
        return store
    }

    private static func populate(_ store: InMemoryDataStore, now: Date) throws {
        let hour: TimeInterval = 60 * 60

        store.volunteers[volunteer.id] = volunteer

        let match = Event(id: Identifier(), name: "Rugby League Semi-final",
                          venue: "Sydney Olympic Park",
                          startsAt: now.addingTimeInterval(-4 * hour),
                          endsAt: now.addingTimeInterval(-1 * hour))
        let summit = Event(id: Identifier(), name: "Harbour Tech Summit",
                           venue: "Darling Harbour Convention Centre",
                           startsAt: now.addingTimeInterval(-2 * hour),
                           endsAt: now.addingTimeInterval(3 * hour))
        for event in [match, summit] { store.events[event.id] = event }

        let redfern = DropPoint(id: Identifier(), name: "Redfern Community Kitchen",
                                address: "12 Regent St, Redfern NSW 2016", openingHours: 7...21)
        let parramatta = DropPoint(id: Identifier(), name: "Parramatta Neighbourhood Pantry",
                                   address: "48 Church St, Parramatta NSW 2150", openingHours: 9...17)
        for dropPoint in [redfern, parramatta] { store.dropPoints[dropPoint.id] = dropPoint }

        let pickup = Pickup(id: Identifier(), eventID: match.id, volunteerID: volunteer.id,
                            collectedAt: now.addingTimeInterval(-1.5 * hour))
        store.pickups[pickup.id] = pickup

        let collected = HoldWindow(startedAt: pickup.collectedAt)
        let batches = [
            FoodBatch(id: Identifier(), pickupID: pickup.id, foodDescription: "Vegetable fried rice",
                      weight: try Weight(kilograms: 8), allergens: [.soy, .egg], allergensDeclared: true,
                      holdWindow: collected, status: .cleared),
            FoodBatch(id: Identifier(), pickupID: pickup.id, foodDescription: "Chicken skewers",
                      weight: try Weight(kilograms: 5.5), allergens: [], allergensDeclared: false,
                      holdWindow: collected, status: .awaitingCheck),
            FoodBatch(id: Identifier(), pickupID: pickup.id, foodDescription: "Garden salad",
                      weight: try Weight(kilograms: 3), allergens: [], allergensDeclared: true,
                      holdWindow: collected, status: .failedCheck),
            FoodBatch(id: Identifier(), pickupID: pickup.id, foodDescription: "Pasta bake",
                      weight: try Weight(kilograms: 12), allergens: [.wheat, .milk], allergensDeclared: true,
                      holdWindow: collected, status: .handedOver, dropPointID: redfern.id)
        ]
        for batch in batches { store.batches[batch.id] = batch }
    }
}
