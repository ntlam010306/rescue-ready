import Foundation

/// Details of one batch entered by the volunteer, before it is validated.
struct NewBatch: Identifiable, Equatable {
    var id = UUID()
    var foodDescription: String
    var weightKg: Double
    var allergens: Set<Allergen>
    var allergensDeclared: Bool
}

/// Records a pickup at an event and creates its batches, ready for safety checks.
///
/// Rules:
/// - at least one batch
/// - the event must exist and be accepting pickups
/// - every batch needs a description and a valid weight
/// - each batch's hold window starts at the moment of pickup
struct LogPickupUseCase {
    let events: EventRepository
    let pickups: PickupRepository
    /// Injected so tests control time. Never call `Date()` directly in a use case.
    let now: () -> Date

    func execute(
        eventID: Identifier<Event>,
        volunteerID: Identifier<Volunteer>,
        batches drafts: [NewBatch]
    ) async throws -> Pickup {
        guard !drafts.isEmpty else { throw DomainError.noBatches }

        let event: Event?
        do {
            event = try await events.event(id: eventID)
        } catch {
            throw DomainError.storageFailure
        }
        guard let event else { throw DomainError.eventNotFound }

        let timestamp = now()
        guard event.acceptsPickups(at: timestamp) else { throw DomainError.eventNotActive }

        let pickup = Pickup(id: Identifier(), eventID: event.id, volunteerID: volunteerID, collectedAt: timestamp)
        let batches = try drafts.map { try makeBatch(from: $0, pickupID: pickup.id, collectedAt: timestamp) }

        do {
            try await pickups.save(pickup, batches: batches)
        } catch {
            throw DomainError.storageFailure
        }
        return pickup
    }

    private func makeBatch(from draft: NewBatch, pickupID: Identifier<Pickup>, collectedAt: Date) throws -> FoodBatch {
        let description = draft.foodDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !description.isEmpty else { throw DomainError.missingFoodDescription }

        return FoodBatch(
            id: Identifier(),
            pickupID: pickupID,
            foodDescription: description,
            weight: try Weight(kilograms: draft.weightKg),
            allergens: draft.allergens,
            allergensDeclared: draft.allergensDeclared,
            holdWindow: HoldWindow(startedAt: collectedAt),
            status: .awaitingCheck
        )
    }
}
