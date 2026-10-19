import Foundation

/// A person collecting and delivering food.
struct Volunteer: Identifiable, Equatable {
    let id: Identifier<Volunteer>
    var name: String
}
