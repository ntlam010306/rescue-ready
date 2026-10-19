import CoreData
import Foundation

final class CoreDataPickupRepository: PickupRepository {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func save(_ pickup: Pickup, batches: [FoodBatch]) async throws {
        try await container.performBackground(failure: .saveFailed) { context in
            guard let event = try context.fetchOne(EventEntity.self, id: pickup.eventID.rawValue),
                  let volunteer = try context.fetchOne(VolunteerEntity.self, id: pickup.volunteerID.rawValue) else {
                throw RepositoryError.notFound
            }

            let pickupEntity = PickupEntity(context: context)
            pickupEntity.update(from: pickup)
            pickupEntity.event = event
            pickupEntity.volunteer = volunteer

            for batch in batches {
                let batchEntity = FoodBatchEntity(context: context)
                batchEntity.update(from: batch)
                batchEntity.pickup = pickupEntity
                if let dropPointID = batch.dropPointID {
                    batchEntity.dropPoint = try context.fetchOne(DropPointEntity.self, id: dropPointID.rawValue)
                }
            }

            try context.save()
        }
    }

    func pickup(id: Identifier<Pickup>) async throws -> Pickup? {
        try await container.performBackground(failure: .fetchFailed) { context in
            try context.fetchOne(PickupEntity.self, id: id.rawValue)?.toDomain()
        }
    }

    func pickups(for eventID: Identifier<Event>) async throws -> [Pickup] {
        try await container.performBackground(failure: .fetchFailed) { context in
            let request = NSFetchRequest<PickupEntity>(entityName: "PickupEntity")
            request.predicate = NSPredicate(format: "event.id == %@", eventID.rawValue as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "collectedAt", ascending: false)]
            return try context.fetch(request).map { try $0.toDomain() }
        }
    }
}
