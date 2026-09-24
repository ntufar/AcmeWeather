import Foundation
import Observation

/// Power outage reports. Submission is simulated — no data leaves the device.
/// Swap `submit` for a real utility or backend API later (see docs/ROADMAP.md).
@Observable
final class OutageStore {
    private(set) var reports: [OutageReport] {
        didSet { Storage.save(reports, key: StorageKey.outageReports) }
    }

    /// Simulated county-level outage picture.
    let countyOutages: [CountyOutage] = SampleData.countyOutages()

    init() {
        reports = Storage.load([OutageReport].self, key: StorageKey.outageReports) ?? []
    }

    var totalCustomersOut: Int { countyOutages.reduce(0) { $0 + $1.customersOut } }
    var activeReports: [OutageReport] { reports.filter { $0.stage() != .restored } }

    func submit(_ draft: OutageReport) async -> OutageReport {
        try? await Task.sleep(for: .seconds(1.4)) // simulate the network round trip
        var report = draft
        report.referenceNumber = Self.makeReferenceNumber()
        report.submittedAt = .now
        reports.insert(report, at: 0)
        return report
    }

    func delete(_ report: OutageReport) {
        reports.removeAll { $0.id == report.id }
    }

    private static func makeReferenceNumber() -> String {
        let digits = (0..<6).map { _ in String(Int.random(in: 0...9)) }.joined()
        return "GA-\(digits)"
    }
}

@Observable
final class EmergencyKitStore {
    private(set) var checked: Set<String> {
        didSet { Storage.save(Array(checked), key: StorageKey.kitChecked) }
    }

    init() {
        checked = Set(Storage.load([String].self, key: StorageKey.kitChecked) ?? [])
    }

    var progress: Double { Double(checked.count) / Double(KitCategory.totalItems) }

    func isChecked(_ item: KitItem) -> Bool { checked.contains(item.id) }

    func toggle(_ item: KitItem) {
        if checked.contains(item.id) { checked.remove(item.id) } else { checked.insert(item.id) }
    }

    func reset() { checked = [] }
}

struct FamilyMember: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var phone: String
    var notes: String
}

struct FamilyPlan: Codable, Equatable {
    var members: [FamilyMember] = []
    var shelterRoom = ""
    var meetingPlaceNearby = ""
    var meetingPlaceOutOfTown = ""
    var outOfTownContactName = ""
    var outOfTownContactPhone = ""
    var evacuationDestination = ""
    var petPlan = ""

    /// Fraction of the core plan that's filled in.
    var completion: Double {
        let fields = [shelterRoom, meetingPlaceNearby, meetingPlaceOutOfTown, outOfTownContactName, evacuationDestination]
        let filled = fields.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count + (members.isEmpty ? 0 : 1)
        return Double(filled) / Double(fields.count + 1)
    }
}

@Observable
final class FamilyPlanStore {
    var plan: FamilyPlan {
        didSet { Storage.save(plan, key: StorageKey.familyPlan) }
    }

    init() {
        plan = Storage.load(FamilyPlan.self, key: StorageKey.familyPlan) ?? FamilyPlan()
    }
}
