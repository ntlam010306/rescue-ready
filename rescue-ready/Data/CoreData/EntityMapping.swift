import CoreData
import Foundation

// Converts between Core Data entities and domain models.
// `toDomain()` throws `RepositoryError.fetchFailed` when stored data is incomplete or invalid.
// `update(from:)` copies attributes only; repositories set relationships.

extension EventEntity {
    func toDomain() throws -> Event {
        guard let id, let name, let venue, let startsAt, let endsAt else {
            throw RepositoryError.fetchFailed
        }
        return Event(id: Identifier(id), name: name, venue: venue, startsAt: startsAt, endsAt: endsAt)
    }

    func update(from event: Event) {
        id = event.id.rawValue
        name = event.name
        venue = event.venue
        startsAt = event.startsAt
        endsAt = event.endsAt
    }
}

extension VolunteerEntity {
    func toDomain() throws -> Volunteer {
        guard let id, let name else { throw RepositoryError.fetchFailed }
        return Volunteer(id: Identifier(id), name: name)
    }

    func update(from volunteer: Volunteer) {
        id = volunteer.id.rawValue
        name = volunteer.name
    }
}

extension PickupEntity {
    func toDomain() throws -> Pickup {
        guard let id, let collectedAt, let eventID = event?.id, let volunteerID = volunteer?.id else {
            throw RepositoryError.fetchFailed
        }
        return Pickup(id: Identifier(id), eventID: Identifier(eventID),
                      volunteerID: Identifier(volunteerID), collectedAt: collectedAt)
    }

    func update(from pickup: Pickup) {
        id = pickup.id.rawValue
        collectedAt = pickup.collectedAt
    }
}

extension FoodBatchEntity {
    func toDomain() throws -> FoodBatch {
        guard let id, let pickupID = pickup?.id, let foodDescription, let holdStartedAt,
              let statusRaw, let status = BatchStatus(rawValue: statusRaw) else {
            throw RepositoryError.fetchFailed
        }
        let weight: Weight
        do {
            weight = try Weight(kilograms: weightKg)
        } catch {
            throw RepositoryError.fetchFailed
        }
        return FoodBatch(
            id: Identifier(id),
            pickupID: Identifier(pickupID),
            foodDescription: foodDescription,
            weight: weight,
            allergens: Self.decodeAllergens(allergensRaw),
            allergensDeclared: allergensDeclared,
            holdWindow: HoldWindow(startedAt: holdStartedAt),
            status: status,
            dropPointID: dropPoint?.id.map { Identifier($0) },
            discardReason: discardReason
        )
    }

    func update(from batch: FoodBatch) {
        id = batch.id.rawValue
        foodDescription = batch.foodDescription
        weightKg = batch.weight.kilograms
        allergensRaw = Self.encodeAllergens(batch.allergens)
        allergensDeclared = batch.allergensDeclared
        holdStartedAt = batch.holdWindow.startedAt
        statusRaw = batch.status.rawValue
        discardReason = batch.discardReason
    }

    /// Stored as a sorted, comma-separated list of raw values, for example "egg,soy".
    static func encodeAllergens(_ allergens: Set<Allergen>) -> String {
        allergens.map(\.rawValue).sorted().joined(separator: ",")
    }

    static func decodeAllergens(_ raw: String?) -> Set<Allergen> {
        Set((raw ?? "").split(separator: ",").compactMap { Allergen(rawValue: String($0)) })
    }
}

extension SafetyCheckEntity {
    func toDomain() throws -> SafetyCheck {
        guard let id, let checkedAt, let batchID = batch?.id else {
            throw RepositoryError.fetchFailed
        }
        let temperature: Temperature
        do {
            temperature = try Temperature(celsius: temperatureC)
        } catch {
            throw RepositoryError.fetchFailed
        }
        let outcome: SafetyOutcome = passed ? .passed : .failed(reason: failureReason ?? "")
        return SafetyCheck(id: Identifier(id), batchID: Identifier(batchID),
                           temperature: temperature, checkedAt: checkedAt, outcome: outcome)
    }

    func update(from check: SafetyCheck) {
        id = check.id.rawValue
        checkedAt = check.checkedAt
        temperatureC = check.temperature.celsius
        switch check.outcome {
        case .passed:
            passed = true
            failureReason = nil
        case .failed(let reason):
            passed = false
            failureReason = reason
        }
    }
}

extension DropPointEntity {
    func toDomain() throws -> DropPoint {
        guard let id, let name, let address, openHour <= closeHour else {
            throw RepositoryError.fetchFailed
        }
        return DropPoint(id: Identifier(id), name: name, address: address,
                         openingHours: Int(openHour)...Int(closeHour))
    }

    func update(from dropPoint: DropPoint) {
        id = dropPoint.id.rawValue
        name = dropPoint.name
        address = dropPoint.address
        openHour = Int16(dropPoint.openingHours.lowerBound)
        closeHour = Int16(dropPoint.openingHours.upperBound)
    }
}
