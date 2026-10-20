import CoreData
import Foundation
import Testing
@testable import rescue_ready

struct CoreDataDropPointRepositoryTests {
    let controller = PersistenceController(inMemory: true)
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    var repository: CoreDataDropPointRepository {
        CoreDataDropPointRepository(container: controller.container)
    }

    @Test func allReturnsDropPointsSortedByName() async throws {
        try await CoreDataSeeder.seedIfEmpty(controller.container, now: now)

        let dropPoints = try await repository.all()

        #expect(dropPoints.count == 2)
        #expect(dropPoints.map(\.name) == dropPoints.map(\.name).sorted())
    }

    @Test func dropPointKeepsItsOpeningHours() async throws {
        try await CoreDataSeeder.seedIfEmpty(controller.container, now: now)
        let all = try await repository.all()
        let first = try #require(all.first)

        let fetched = try await repository.dropPoint(id: first.id)
        let stored = try #require(fetched)

        #expect(stored == first)
        #expect(stored.openingHours == first.openingHours)
    }

    @Test func unknownDropPointReturnsNil() async throws {
        try await CoreDataSeeder.seedIfEmpty(controller.container, now: now)

        let missing = try await repository.dropPoint(id: Identifier())

        #expect(missing == nil)
    }
}
