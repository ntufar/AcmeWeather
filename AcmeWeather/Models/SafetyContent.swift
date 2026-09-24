import SwiftUI

struct SafetyGuide: Identifiable, Hashable {
    struct Section: Hashable {
        let title: String
        let symbol: String
        let tips: [String]
    }

    let id: String
    let title: String
    let tagline: String
    let symbol: String
    let color: Color
    let sections: [Section]

    static func guide(id: String) -> SafetyGuide? { all.first { $0.id == id } }

    static let all: [SafetyGuide] = [
        SafetyGuide(
            id: "hurricane", title: "Hurricanes", tagline: "Run from water, hide from wind.",
            symbol: "hurricane", color: Color(red: 0.55, green: 0.45, blue: 1.0),
            sections: [
                Section(title: "Before the season", symbol: "calendar", tips: [
                    "Find out if you live in a coastal evacuation zone — check with GEMA or your county EMA.",
                    "Plan where you'd go: a friend or relative inland, a hotel, or a shelter as a last resort.",
                    "Review homeowners/renters insurance. Flood damage needs a separate flood policy, which takes 30 days to go into effect.",
                    "Trim trees and secure loose items like grills, furniture and trampolines.",
                ]),
                Section(title: "72–48 hours out", symbol: "clock.badge.exclamationmark", tips: [
                    "Top off your emergency kit: water, medications, batteries, cash.",
                    "Fill vehicle gas tanks and charge power banks.",
                    "Photograph your home and belongings for insurance.",
                    "Bring in outdoor items; install storm shutters or plywood.",
                ]),
                Section(title: "When ordered to evacuate", symbol: "car.fill", tips: [
                    "Leave immediately. Follow posted evacuation routes — shortcuts may be flooded.",
                    "Turn off utilities if officials tell you to.",
                    "Take your kit, documents, medications, pets and pet supplies.",
                    "Tell your out-of-town contact where you're going.",
                ]),
                Section(title: "If you ride it out", symbol: "house.fill", tips: [
                    "Stay in a small interior room, closet or hallway on the lowest floor that won't flood.",
                    "Stay away from windows and glass doors.",
                    "The calm eye is not the end — the other side of the storm is coming.",
                ]),
                Section(title: "After the storm", symbol: "sun.haze.fill", tips: [
                    "Never walk or drive through floodwater. Six inches of moving water can knock you down.",
                    "Stay away from downed power lines and report them.",
                    "Run generators outdoors only, at least 20 feet from doors and windows.",
                    "Text instead of calling to keep lines open for emergencies.",
                ]),
            ]
        ),
        SafetyGuide(
            id: "tornado", title: "Tornadoes", tagline: "Lowest floor. Interior room. Cover your head.",
            symbol: "tornado", color: Color(red: 0.93, green: 0.25, blue: 0.40),
            sections: [
                Section(title: "Know the difference", symbol: "info.circle.fill", tips: [
                    "Tornado WATCH: conditions are favorable. Review your plan and stay alert.",
                    "Tornado WARNING: a tornado is occurring or imminent. Take shelter now.",
                    "Georgia tornadoes often strike at night and can be rain-wrapped — don't wait to see it.",
                ]),
                Section(title: "Take shelter", symbol: "house.lodge.fill", tips: [
                    "Go to a basement, storm shelter, or small interior room on the lowest floor.",
                    "Put as many walls as possible between you and the outside.",
                    "Cover your head and neck with your arms, a mattress, or a helmet.",
                    "Wear sturdy shoes so you can walk through debris afterward.",
                ]),
                Section(title: "Mobile homes & vehicles", symbol: "car.side.fill", tips: [
                    "Mobile homes are not safe in tornadoes. Go to a sturdy building or shelter before the storm arrives.",
                    "Never shelter under a highway overpass.",
                    "If caught driving, get to a sturdy building. As a last resort, stay buckled and cover your head.",
                ]),
            ]
        ),
        SafetyGuide(
            id: "flood", title: "Flash Floods", tagline: "Turn Around, Don't Drown.",
            symbol: "water.waves", color: Color(red: 0.25, green: 0.60, blue: 1.0),
            sections: [
                Section(title: "The rules", symbol: "exclamationmark.octagon.fill", tips: [
                    "Just 12 inches of moving water can carry away most cars.",
                    "Six inches of moving water can knock an adult off their feet.",
                    "Roads under water may be washed out underneath.",
                    "Be especially careful at night, when it's harder to see flooded roads.",
                ]),
                Section(title: "If flooding starts", symbol: "arrow.up.circle.fill", tips: [
                    "Move to higher ground immediately — don't wait for instructions.",
                    "If trapped in a building, go to the highest level. Avoid closed attics.",
                    "If your car stalls in rising water, get out and move to higher ground if it's safe.",
                ]),
                Section(title: "After", symbol: "drop.triangle.fill", tips: [
                    "Floodwater can contain sewage, chemicals and debris. Avoid contact.",
                    "Watch for mosquitoes after flooding — use repellent.",
                    "Discard food that touched floodwater.",
                ]),
            ]
        ),
        SafetyGuide(
            id: "heat", title: "Extreme Heat", tagline: "Georgia summers are no joke.",
            symbol: "thermometer.sun.fill", color: Color(red: 1.0, green: 0.45, blue: 0.20),
            sections: [
                Section(title: "Stay cool", symbol: "snowflake", tips: [
                    "Drink water before you're thirsty. Avoid alcohol and heavy sugar drinks.",
                    "Limit outdoor work to early morning or evening.",
                    "Find air conditioning: libraries, malls and cooling centers.",
                    "Check on elderly neighbors and anyone without A/C.",
                ]),
                Section(title: "Never in a hot car", symbol: "car.fill", tips: [
                    "A car's interior can climb 20°F in 10 minutes.",
                    "Always look before you lock — children and pets.",
                ]),
                Section(title: "Warning signs", symbol: "heart.text.square.fill", tips: [
                    "Heat exhaustion: heavy sweating, cold clammy skin, nausea, dizziness. Move somewhere cool and sip water.",
                    "Heat stroke: hot red skin, confusion, fast pulse, possibly no sweating. Call 911 — it's an emergency.",
                ]),
            ]
        ),
        SafetyGuide(
            id: "winter", title: "Ice & Winter Storms", tagline: "A little ice shuts Georgia down.",
            symbol: "snowflake", color: Color(red: 0.55, green: 0.80, blue: 1.0),
            sections: [
                Section(title: "Before", symbol: "calendar", tips: [
                    "Ice storms bring down trees and power lines. Expect outages.",
                    "Stock up before roads ice over — avoid the bread-and-milk rush.",
                    "Insulate exposed pipes and know where your water shutoff is.",
                ]),
                Section(title: "During", symbol: "house.fill", tips: [
                    "Stay off the roads. Bridges and overpasses freeze first.",
                    "Never use a grill, camp stove or generator indoors.",
                    "Let faucets drip to keep pipes from freezing.",
                    "Bring pets indoors.",
                ]),
            ]
        ),
        SafetyGuide(
            id: "lightning", title: "Thunderstorms & Lightning", tagline: "When thunder roars, go indoors.",
            symbol: "cloud.bolt.fill", color: Color(red: 1.0, green: 0.80, blue: 0.25),
            sections: [
                Section(title: "Outdoors", symbol: "figure.walk", tips: [
                    "No place outside is safe during a thunderstorm.",
                    "If you can hear thunder, you're close enough to be struck.",
                    "Get into a building with plumbing and wiring, or a hard-topped vehicle.",
                    "Wait 30 minutes after the last thunder before going back out.",
                ]),
                Section(title: "Indoors", symbol: "house.fill", tips: [
                    "Avoid corded phones, showers and baths during the storm.",
                    "Stay away from windows and doors.",
                    "Unplug sensitive electronics before the storm arrives.",
                ]),
            ]
        ),
        SafetyGuide(
            id: "power", title: "Power Outages & Generators", tagline: "Stay safe when the lights go out.",
            symbol: "bolt.slash.fill", color: Color(red: 1.0, green: 0.62, blue: 0.20),
            sections: [
                Section(title: "Downed lines", symbol: "exclamationmark.triangle.fill", tips: [
                    "Assume every downed line is live. Stay at least 30 feet away and call 911 and your utility.",
                    "Never touch anything in contact with a line — fences, puddles, cars or tree limbs.",
                ]),
                Section(title: "Generators", symbol: "powerplug.fill", tips: [
                    "Run generators outdoors only, at least 20 feet from doors, windows and vents.",
                    "Never run a generator in a garage, even with the door open. Carbon monoxide kills.",
                    "Install battery-powered CO alarms.",
                    "Never plug a generator into a wall outlet — it can backfeed and injure line workers.",
                ]),
                Section(title: "Food safety", symbol: "refrigerator.fill", tips: [
                    "Keep refrigerator and freezer doors closed.",
                    "A closed fridge keeps food cold about 4 hours.",
                    "A full freezer holds temperature about 48 hours (24 hours if half full).",
                    "When in doubt, throw it out.",
                ]),
            ]
        ),
    ]
}

struct KitItem: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String?
}

struct KitCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let items: [KitItem]

    static let all: [KitCategory] = [
        KitCategory(id: "water", title: "Water & Food", symbol: "drop.fill", items: [
            KitItem(id: "water", title: "Water", detail: "1 gallon per person per day, at least 3 days"),
            KitItem(id: "food", title: "Non-perishable food", detail: "At least a 3-day supply"),
            KitItem(id: "canopener", title: "Manual can opener", detail: nil),
            KitItem(id: "cooler", title: "Cooler & ice packs", detail: "For medications and food during outages"),
        ]),
        KitCategory(id: "power", title: "Power & Light", symbol: "flashlight.on.fill", items: [
            KitItem(id: "radio", title: "NOAA Weather Radio", detail: "Battery or hand-crank"),
            KitItem(id: "flashlight", title: "Flashlights", detail: "One per person"),
            KitItem(id: "batteries", title: "Extra batteries", detail: nil),
            KitItem(id: "powerbank", title: "Charged power banks", detail: "And phone cables"),
        ]),
        KitCategory(id: "health", title: "Health & First Aid", symbol: "cross.case.fill", items: [
            KitItem(id: "firstaid", title: "First aid kit", detail: nil),
            KitItem(id: "meds", title: "Prescription medications", detail: "At least a 7-day supply"),
            KitItem(id: "glasses", title: "Glasses & contact supplies", detail: nil),
            KitItem(id: "masks", title: "Dust masks", detail: nil),
            KitItem(id: "sanitation", title: "Moist towelettes & garbage bags", detail: "For personal sanitation"),
            KitItem(id: "bugspray", title: "Insect repellent & sunscreen", detail: "Mosquitoes thrive after storms"),
        ]),
        KitCategory(id: "tools", title: "Tools & Supplies", symbol: "wrench.and.screwdriver.fill", items: [
            KitItem(id: "whistle", title: "Whistle", detail: "To signal for help"),
            KitItem(id: "wrench", title: "Wrench or pliers", detail: "To turn off utilities"),
            KitItem(id: "tape", title: "Plastic sheeting & duct tape", detail: nil),
            KitItem(id: "extinguisher", title: "Fire extinguisher", detail: nil),
            KitItem(id: "matches", title: "Matches in a waterproof container", detail: nil),
        ]),
        KitCategory(id: "docs", title: "Documents & Money", symbol: "doc.text.fill", items: [
            KitItem(id: "documents", title: "Important documents", detail: "IDs, insurance, deeds — in a waterproof bag"),
            KitItem(id: "cash", title: "Cash", detail: "ATMs and card readers fail without power"),
            KitItem(id: "contacts", title: "Printed contact list", detail: nil),
            KitItem(id: "maps", title: "Paper map of Georgia", detail: "In case GPS and cell service are down"),
        ]),
        KitCategory(id: "family", title: "Family & Pets", symbol: "figure.2.and.child.holdinghands", items: [
            KitItem(id: "baby", title: "Infant formula, diapers, wipes", detail: "If needed"),
            KitItem(id: "pets", title: "Pet food, water, leash & carrier", detail: nil),
            KitItem(id: "clothes", title: "Change of clothes & sturdy shoes", detail: nil),
            KitItem(id: "blankets", title: "Sleeping bags or blankets", detail: nil),
        ]),
    ]

    static var totalItems: Int { all.reduce(0) { $0 + $1.items.count } }
}

struct EmergencyContact: Identifiable {
    let name: String
    let detail: String
    let phone: String?
    let url: URL?
    let symbol: String
    var id: String { name }

    static let all: [EmergencyContact] = [
        EmergencyContact(name: "Emergency", detail: "Police, fire, medical — life-threatening emergencies", phone: "911", url: nil, symbol: "phone.fill"),
        EmergencyContact(name: "Georgia 211", detail: "Shelters, food, recovery assistance", phone: "211", url: nil, symbol: "person.2.fill"),
        EmergencyContact(name: "Georgia 511", detail: "Road conditions & evacuation traffic (GDOT)", phone: "511", url: URL(string: "https://511ga.org"), symbol: "car.fill"),
        EmergencyContact(name: "Poison Control", detail: "Including carbon monoxide exposure", phone: "18002221222", url: nil, symbol: "cross.vial.fill"),
        EmergencyContact(name: "GEMA/HS", detail: "Georgia Emergency Management & Homeland Security", phone: nil, url: URL(string: "https://gema.georgia.gov"), symbol: "shield.lefthalf.filled"),
        EmergencyContact(name: "National Hurricane Center", detail: "Official tropical forecasts", phone: nil, url: URL(string: "https://www.nhc.noaa.gov"), symbol: "hurricane"),
        EmergencyContact(name: "NWS Peachtree City", detail: "Forecast office for north & central Georgia", phone: nil, url: URL(string: "https://www.weather.gov/ffc"), symbol: "antenna.radiowaves.left.and.right"),
        EmergencyContact(name: "Ready.gov", detail: "Federal preparedness guidance", phone: nil, url: URL(string: "https://www.ready.gov"), symbol: "checklist"),
    ]
}
