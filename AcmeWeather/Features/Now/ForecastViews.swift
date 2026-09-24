import SwiftUI

struct HourlyStrip: View {
    let hours: [HourlyForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(title: "Next 24 hours", systemImage: "clock")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                        VStack(spacing: 8) {
                            Text(index == 0 ? "Now" : hour.time.hourLabel)
                                .font(.caption.weight(.semibold))
                            Image(systemName: hour.condition.symbol(isDay: hour.isDay))
                                .symbolRenderingMode(.multicolor)
                                .font(.title3)
                                .frame(height: 26)
                            Text(hour.precipitationChance >= 20 ? "\(hour.precipitationChance)%" : " ")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Theme.sky)
                            Text("\(Int(hour.temperature.rounded()))°")
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .glassCard()
    }
}

struct DailyForecastCard: View {
    let days: [DailyForecast]

    var body: some View {
        let weekLow = days.map(\.low).min() ?? 0
        let weekHigh = days.map(\.high).max() ?? 100

        VStack(alignment: .leading, spacing: 10) {
            CardHeader(title: "7-day forecast", systemImage: "calendar")
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                HStack(spacing: 12) {
                    Text(index == 0 ? "Today" : day.date.weekdayShort)
                        .font(.body.weight(.semibold))
                        .frame(width: 56, alignment: .leading)
                    VStack(spacing: 0) {
                        Image(systemName: day.condition.symbol(isDay: true))
                            .symbolRenderingMode(.multicolor)
                        if day.precipitationChance >= 20 {
                            Text("\(day.precipitationChance)%")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Theme.sky)
                        }
                    }
                    .frame(width: 36)
                    Text("\(Int(day.low.rounded()))°")
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 36, alignment: .trailing)
                    TemperatureBar(low: day.low, high: day.high, weekLow: weekLow, weekHigh: weekHigh)
                    Text("\(Int(day.high.rounded()))°")
                        .frame(width: 36, alignment: .leading)
                }
                .font(.body)
                if index < days.count - 1 {
                    Divider().overlay(.white.opacity(0.1))
                }
            }
        }
        .glassCard()
    }
}

/// Apple-Weather-style range bar showing where today's low/high sit within the week.
struct TemperatureBar: View {
    let low: Double
    let high: Double
    let weekLow: Double
    let weekHigh: Double

    var body: some View {
        GeometryReader { geo in
            let range = max(weekHigh - weekLow, 1)
            let start = (low - weekLow) / range * geo.size.width
            let width = max((high - low) / range * geo.size.width, 6)
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [Theme.sky, .yellow, Theme.peach, Theme.danger], startPoint: .leading, endPoint: .trailing))
                    .frame(width: width)
                    .offset(x: start)
            }
        }
        .frame(height: 5)
    }
}

struct ConditionsGrid: View {
    let current: CurrentConditions
    let today: DailyForecast?
    let aqi: Int?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            muggyTile
            windTile
            uvTile
            aqiTile
            pollenTile
            sunTile
            DetailTile(title: "Humidity", symbol: "humidity.fill", value: "\(Int(current.humidity))%",
                       caption: "Dew point \(Int(current.dewPoint.rounded()))°")
            DetailTile(title: "Pressure", symbol: "gauge.with.dots.needle.33percent",
                       value: String(format: "%.2f", current.pressureInHg), caption: "inHg")
        }
    }

    private var muggyTile: some View {
        let muggy = MuggyMeter.label(dewPoint: current.dewPoint)
        return DetailTile(title: "Muggy Meter", symbol: "drop.degreesign.fill", value: muggy.title, caption: muggy.detail) {
            GaugeBar(level: muggy.level, colors: [.green, .yellow, .orange, .red])
        }
    }

    private var windTile: some View {
        DetailTile(title: "Wind", symbol: "wind",
                   value: "\(Int(current.windSpeed.rounded())) mph",
                   caption: "Gusts \(Int(current.windGust.rounded())) · \(Compass.direction(current.windDirection))") {
            Image(systemName: "location.north.fill")
                .rotationEffect(.degrees(current.windDirection + 180))
                .foregroundStyle(Theme.sky)
        }
    }

    private var uvTile: some View {
        let uv = UVScale.label(current.uvIndex)
        return DetailTile(title: "UV Index", symbol: "sun.max.fill", value: "\(Int(current.uvIndex.rounded()))", caption: uv.0) {
            GaugeBar(level: min(current.uvIndex / 11, 1), colors: [.green, .yellow, .orange, .red, .purple])
        }
    }

    @ViewBuilder
    private var aqiTile: some View {
        if let aqi {
            let label = AirQualityScale.label(aqi)
            DetailTile(title: "Air Quality", symbol: "aqi.medium", value: "\(aqi)", caption: label.0) {
                GaugeBar(level: min(Double(aqi) / 300, 1), colors: [.green, .yellow, .orange, .red, .purple])
            }
        } else {
            DetailTile(title: "Air Quality", symbol: "aqi.medium", value: "—", caption: "Unavailable")
        }
    }

    private var pollenTile: some View {
        let pollen = PollenOutlook.estimate()
        return DetailTile(title: "Pollen (est.)", symbol: "leaf.fill", value: pollen.level, caption: pollen.source) {
            GaugeBar(level: pollen.progress, colors: [.green, .yellow, .orange, .red])
        }
    }

    private var sunTile: some View {
        DetailTile(
            title: "Sunrise · Sunset", symbol: "sunrise.fill",
            value: today?.sunrise?.shortTime ?? "—",
            caption: "Sunset \(today?.sunset?.shortTime ?? "—")"
        )
    }
}

struct DetailTile<Accessory: View>: View {
    let title: String
    let symbol: String
    let value: String
    let caption: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title.uppercased(), systemImage: symbol)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.title2.weight(.semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            accessory
            Spacer(minLength: 0)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .glassCard(padding: 14)
    }
}

extension DetailTile where Accessory == EmptyView {
    init(title: String, symbol: String, value: String, caption: String) {
        self.init(title: title, symbol: symbol, value: value, caption: caption) { EmptyView() }
    }
}

struct GaugeBar: View {
    let level: Double
    let colors: [Color]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                Circle()
                    .fill(.white)
                    .frame(width: 9, height: 9)
                    .shadow(radius: 2)
                    .offset(x: max(0, min(level, 1)) * (geo.size.width - 9))
            }
        }
        .frame(height: 9)
    }
}
