import Foundation

extension Double {
    /// Formats kilograms for display, for example "8 kg" or "5.5 kg".
    var kilogramsText: String {
        "\(formatted(.number.precision(.fractionLength(0...1)))) kg"
    }
}
