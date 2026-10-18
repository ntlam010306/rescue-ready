import Foundation

/// A pantry or meal program that receives rescued food.
struct DropPoint: Identifiable, Equatable {
    let id: Identifier<DropPoint>
    var name: String
    var address: String
    /// Opening hours in 24-hour clock, for example 8...20. Same-day hours only.
    var openingHours: ClosedRange<Int>

    func isOpen(at date: Date, calendar: Calendar = .current) -> Bool {
        openingHours.contains(calendar.component(.hour, from: date))
    }
}
