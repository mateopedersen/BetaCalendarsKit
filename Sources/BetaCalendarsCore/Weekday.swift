/// A Gregorian weekday using Foundation's stable 1...7 numbering.
public enum Weekday: Int, CaseIterable, Codable, Hashable, Sendable, Comparable, CustomStringConvertible {
    /// Sunday (Foundation weekday number 1).
    case sunday = 1
    /// Monday (Foundation weekday number 2).
    case monday
    /// Tuesday (Foundation weekday number 3).
    case tuesday
    /// Wednesday (Foundation weekday number 4).
    case wednesday
    /// Thursday (Foundation weekday number 5).
    case thursday
    /// Friday (Foundation weekday number 6).
    case friday
    /// Saturday (Foundation weekday number 7).
    case saturday

    /// Lowercase command-line and serialization name.
    public var description: String {
        switch self {
        case .sunday: "sunday"
        case .monday: "monday"
        case .tuesday: "tuesday"
        case .wednesday: "wednesday"
        case .thursday: "thursday"
        case .friday: "friday"
        case .saturday: "saturday"
        }
    }

    /// Whether this weekday is Saturday or Sunday.
    public var isWeekend: Bool { self == .saturday || self == .sunday }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Parses a case-insensitive English weekday name.
    public init?(name: String) {
        self.init(rawValue: Self.allCases.first { $0.description == name.lowercased() }?.rawValue ?? 0)
    }
}
