import CoreData
import Foundation

final class CoreDataEventRepository: EventRepository {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func event(id: Identifier<Event>) async throws -> Event? {
        try await container.performBackground(failure: .fetchFailed) { context in
            try context.fetchOne(EventEntity.self, id: id.rawValue)?.toDomain()
        }
    }

    func events(acceptingPickupsAt date: Date) async throws -> [Event] {
        try await container.performBackground(failure: .fetchFailed) { context in
            // Same rule as Event.acceptsPickups(at:), expressed as a store query.
            let latestAcceptedEnd = date.addingTimeInterval(-Event.pickupGracePeriod)
            let request = NSFetchRequest<EventEntity>(entityName: "EventEntity")
            request.predicate = NSPredicate(
                format: "startsAt <= %@ AND endsAt >= %@",
                date as NSDate, latestAcceptedEnd as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startsAt", ascending: true)]
            return try context.fetch(request).map { try $0.toDomain() }
        }
    }
}
