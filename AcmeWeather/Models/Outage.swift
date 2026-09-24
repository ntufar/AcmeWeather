import SwiftUI

enum Utility: String, CaseIterable, Codable, Identifiable {
    case georgiaPower = "Georgia Power"
    case emc = "Electric Membership Cooperative (EMC)"
    case municipal = "City / Municipal Utility"
    case notSure = "Not sure"

    var id: String { rawValue }
}

enum OutageCause: String, CaseIterable, Codable, Identifiable {
    case unknown = "Not sure"
    case storm = "Storm damage"
    case treeOnLine = "Tree on a line"
    case downedLine = "Downed power line"
    case transformer = "Transformer / loud bang"
    case partial = "Flickering / partial power"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .unknown: "questionmark.circle.fill"
        case .storm: "cloud.bolt.rain.fill"
        case .treeOnLine: "tree.fill"
        case .downedLine: "exclamationmark.triangle.fill"
        case .transformer: "bolt.trianglebadge.exclamationmark.fill"
        case .partial: "lightbulb.min.fill"
        }
    }

    var isHazard: Bool { self == .downedLine }
}

enum OutageStage: Int, CaseIterable, Comparable {
    case received, assessing, crewAssigned, restoring, restored

    static func < (lhs: OutageStage, rhs: OutageStage) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .received: "Report received"
        case .assessing: "Assessing damage"
        case .crewAssigned: "Crew assigned"
        case .restoring: "Restoration in progress"
        case .restored: "Power restored"
        }
    }

    var symbol: String {
        switch self {
        case .received: "tray.and.arrow.down.fill"
        case .assessing: "magnifyingglass"
        case .crewAssigned: "person.2.fill"
        case .restoring: "wrench.and.screwdriver.fill"
        case .restored: "checkmark.seal.fill"
        }
    }

    /// Simulated progression. Real status would come from the utility's outage API.
    static func simulated(elapsed: TimeInterval) -> OutageStage {
        switch elapsed {
        case ..<(10 * 60): .received
        case ..<(60 * 60): .assessing
        case ..<(3 * 3600): .crewAssigned
        case ..<(6 * 3600): .restoring
        default: .restored
        }
    }
}

struct OutageReport: Identifiable, Codable, Hashable {
    var id = UUID()
    var referenceNumber: String
    var submittedAt: Date
    var coordinate: Coordinate?
    var address: String
    var utility: Utility
    var cause: OutageCause
    var neighborsAffected: Bool
    var notes: String
    var hasPhoto: Bool
    var contactPhone: String
    var wantsUpdates: Bool

    func stage(at date: Date = .now) -> OutageStage {
        OutageStage.simulated(elapsed: date.timeIntervalSince(submittedAt))
    }

    /// Estimated restoration time shown to the user (simulated).
    var estimatedRestoration: Date { submittedAt.addingTimeInterval(6 * 3600) }
}

struct CountyOutage: Identifiable, Hashable {
    let county: String
    let customersOut: Int
    let customersServed: Int
    let coordinate: Coordinate

    var id: String { county }
    var percentOut: Double { Double(customersOut) / Double(customersServed) }
}
