import Foundation
import Testing
@testable import AcmeWeather

@MainActor
struct WeatherConditionTests {
    @Test(arguments: [
        (0, WeatherCondition.clear), (2, .partlyCloudy), (3, .cloudy), (45, .fog),
        (53, .drizzle), (63, .rain), (65, .heavyRain), (67, .freezingRain),
        (75, .snow), (95, .thunderstorm), (999, .cloudy),
    ])
    func mapsWMOCodes(code: Int, expected: WeatherCondition) {
        #expect(WeatherCondition(wmoCode: code) == expected)
    }

    @Test func muggyMeterScalesWithDewPoint() {
        #expect(MuggyMeter.label(dewPoint: 45).title == "Crisp")
        #expect(MuggyMeter.label(dewPoint: 68).title == "Muggy")
        #expect(MuggyMeter.label(dewPoint: 78).title == "Swamp Mode")
    }

    @Test func compassDirections() {
        #expect(Compass.direction(0) == "N")
        #expect(Compass.direction(359) == "N")
        #expect(Compass.direction(225) == "SW")
        #expect(Compass.direction(-90) == "W")
    }
}

@MainActor
struct StormTests {
    @Test(arguments: [
        (30, StormCategory.depression), (39, .tropicalStorm), (73, .tropicalStorm),
        (74, .hurricane(1)), (96, .hurricane(2)), (111, .hurricane(3)),
        (130, .hurricane(4)), (157, .hurricane(5)), (185, .hurricane(5)),
    ])
    func saffirSimpsonThresholds(mph: Int, expected: StormCategory) {
        #expect(StormCategory(windMph: mph) == expected)
    }

    @Test func coneSurroundsTheTrack() {
        let storm = SampleData.demoHurricane()
        let cone = storm.cone
        #expect(cone.count > storm.forecastTrack.count * 2)

        // Every forecast point should sit inside the cone's bounding box.
        let lats = cone.map(\.latitude), lons = cone.map(\.longitude)
        for point in storm.forecastTrack {
            #expect((lats.min()!...lats.max()!).contains(point.coordinate.latitude))
            #expect((lons.min()!...lons.max()!).contains(point.coordinate.longitude))
        }
    }

    @Test func coneNeedsAtLeastTwoPoints() {
        #expect(ConeBuilder.cone(along: [Coordinate(30, -80)]).isEmpty)
    }

    @Test func demoStormMakesLandfallInGeorgia() {
        let storm = SampleData.demoHurricane()
        #expect(storm.forecastTrack.contains { GeorgiaRegion.contains($0.coordinate) })
    }
}

@MainActor
struct AlertOrderingTests {
    private func alert(_ event: String, _ severity: AlertSeverity, expiresIn hours: Double = 1) -> WeatherAlert {
        WeatherAlert(
            id: event, event: event, headline: event, description: "", instruction: nil,
            severity: severity, urgency: "", certainty: "", areaDescription: "", effective: nil,
            expires: Date.now.addingTimeInterval(hours * 3600), sender: "", polygons: []
        )
    }

    @Test func sortsBySeverityThenWarningThenExpiry() {
        let sorted = [
            alert("Heat Advisory", .minor),
            alert("Flood Watch", .severe),
            alert("Severe Thunderstorm Warning", .severe, expiresIn: 2),
            alert("Tornado Warning", .extreme),
            alert("Flash Flood Warning", .severe, expiresIn: 1),
        ].sorted()

        #expect(sorted.map(\.event) == [
            "Tornado Warning",
            "Flash Flood Warning",
            "Severe Thunderstorm Warning",
            "Flood Watch",
            "Heat Advisory",
        ])
    }

    @Test(arguments: [
        ("Tornado Watch", HazardKind.tornado), ("Hurricane Warning", .tropical),
        ("Flash Flood Warning", .flood), ("Winter Storm Warning", .winter),
        ("Excessive Heat Warning", .heat), ("Red Flag Warning", .fire),
        ("Special Weather Statement", .other),
    ])
    func classifiesHazards(event: String, kind: HazardKind) {
        #expect(HazardKind(event: event) == kind)
    }
}

@MainActor
struct OutageTests {
    @Test func simulatedStagesProgressOverTime() {
        #expect(OutageStage.simulated(elapsed: 60) == .received)
        #expect(OutageStage.simulated(elapsed: 30 * 60) == .assessing)
        #expect(OutageStage.simulated(elapsed: 2 * 3600) == .crewAssigned)
        #expect(OutageStage.simulated(elapsed: 4 * 3600) == .restoring)
        #expect(OutageStage.simulated(elapsed: 7 * 3600) == .restored)
    }

    @Test func familyPlanCompletion() {
        var plan = FamilyPlan()
        #expect(plan.completion == 0)
        plan.shelterRoom = "Hall closet"
        plan.members = [FamilyMember(name: "Pat", phone: "", notes: "")]
        #expect(plan.completion > 0.3 && plan.completion < 0.4)
    }

    @Test func nearestPlace() {
        #expect(GeorgiaPlace.nearest(to: Coordinate(32.05, -81.10)).name == "Savannah")
        #expect(GeorgiaRegion.contains(GeorgiaPlace.atlanta.coordinate))
        #expect(!GeorgiaRegion.contains(Coordinate(37.33, -122.03)))
    }
}
