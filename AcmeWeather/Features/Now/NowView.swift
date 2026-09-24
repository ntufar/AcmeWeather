import SwiftUI

struct NowView: View {
    @Environment(AppState.self) private var app
    @State private var showPlaces = false
    @State private var showSettings = false
    @State private var showOutageReport = false
    @State private var showLightning = false

    var body: some View {
        let current = app.weather?.current
        let condition = current?.condition ?? .partlyCloudy
        let isDay = current?.isDay ?? true

        NavigationStack {
            ZStack {
                WeatherBackground(condition: condition, isDay: isDay)

                ScrollView {
                    VStack(spacing: 16) {
                        topBar
                        if let alert = app.topAlert {
                            AlertBanner(alert: alert, extraCount: app.alerts.count - 1) {
                                app.selectedTab = .alerts
                            }
                        }
                        if let weather = app.weather {
                            CurrentHero(weather: weather, condition: condition)
                            quickActions
                            if let nearest = app.nearestStorm {
                                StormCallout(storm: nearest.storm, miles: nearest.miles) {
                                    app.selectedTab = .hurricanes
                                }
                            }
                            HourlyStrip(hours: weather.hourly)
                            DailyForecastCard(days: weather.daily)
                            ConditionsGrid(current: weather.current, today: weather.daily.first, aqi: app.airQualityIndex)
                            footer(weather: weather)
                        } else {
                            ProgressView("Checking the Georgia sky…")
                                .tint(.white)
                                .padding(.top, 120)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    .foregroundStyle(.white)
                }
                .refreshable { await app.refreshAll() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPlaces) { PlacePickerView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showOutageReport) { OutageReportView() }
            .sheet(isPresented: $showLightning) { LightningTimerView() }
        }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            Button { showPlaces = true } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if case .currentLocation = app.placeSelection {
                            Image(systemName: "location.fill").font(.caption)
                        }
                        Text(app.placeTitle).font(.title3.weight(.bold))
                        Image(systemName: "chevron.down").font(.caption.weight(.bold))
                    }
                    Text(app.placeSubtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if app.isLoadingWeather {
                ProgressView().tint(.white).padding(.trailing, 6)
            }
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.top, 8)
    }

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                QuickAction(title: "Live Radar", symbol: "dot.radiowaves.left.and.right", tint: Theme.sky) {
                    app.selectedTab = .radar
                }
                QuickAction(title: "Report Outage", symbol: "bolt.slash.fill", tint: Theme.peach) {
                    showOutageReport = true
                }
                QuickAction(title: "Tropics", symbol: "hurricane", tint: .purple) {
                    app.selectedTab = .hurricanes
                }
                QuickAction(title: "Lightning Timer", symbol: "bolt.fill", tint: .yellow) {
                    showLightning = true
                }
                QuickAction(title: "Be Ready", symbol: "cross.case.fill", tint: Theme.pine) {
                    app.selectedTab = .safety
                }
            }
        }
    }

    private func footer(weather: WeatherSnapshot) -> some View {
        VStack(spacing: 4) {
            if app.weatherIsSample {
                Label("Offline — showing sample data", systemImage: "wifi.slash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.peachLight)
            }
            Text("Updated \(weather.fetchedAt.shortTime) · Forecast: Open-Meteo · Alerts: NWS")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.top, 4)
    }
}

// MARK: - Pieces

private struct QuickAction: View {
    let title: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol).foregroundStyle(tint)
                Text(title).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }
}

struct CurrentHero: View {
    let weather: WeatherSnapshot
    let condition: WeatherCondition

    var body: some View {
        let current = weather.current
        let today = weather.daily.first
        VStack(spacing: 6) {
            Image(systemName: condition.symbol(isDay: current.isDay))
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 64))
                .symbolEffect(.pulse, options: .repeating, isActive: condition == .thunderstorm)
                .shadow(color: .black.opacity(0.2), radius: 10)
            Text("\(Int(current.temperature.rounded()))°")
                .font(.system(size: 96, weight: .thin, design: .rounded))
                .contentTransition(.numericText())
            Text(condition.label)
                .font(.title3.weight(.medium))
            if let today {
                Text("H:\(Int(today.high.rounded()))°  L:\(Int(today.low.rounded()))°  ·  Feels like \(Int(current.apparentTemperature.rounded()))°")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

struct AlertBanner: View {
    let alert: WeatherAlert
    let extraCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: alert.kind.symbol)
                    .font(.title2)
                    .symbolEffect(.pulse, options: .repeating)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(alert.event).font(.headline)
                        if alert.isDemo { DemoBadge() }
                    }
                    Text(alert.areaDescription)
                        .font(.caption)
                        .lineLimit(1)
                        .opacity(0.9)
                    if extraCount > 0 {
                        Text("+\(extraCount) more active alert\(extraCount == 1 ? "" : "s") in Georgia")
                            .font(.caption2.weight(.semibold))
                            .opacity(0.8)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [alert.severity.color, alert.severity.color.opacity(0.7)], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: alert.severity.color.opacity(0.5), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct StormCallout: View {
    let storm: Storm
    let miles: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                SpinningStormIcon(color: storm.category.color, size: 48)
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(storm.displayName).font(.headline)
                        if storm.isDemo { DemoBadge() }
                    }
                    Text("\(storm.category.shortLabel) · \(storm.windMph) mph · \(Int(miles).formatted()) mi away")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Moving \(storm.movementText)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.6))
            }
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}

struct SpinningStormIcon: View {
    let color: Color
    var size: CGFloat = 44
    @State private var spinning = false

    var body: some View {
        Image(systemName: "hurricane")
            .font(.system(size: size * 0.55, weight: .bold))
            .foregroundStyle(.white)
            .rotationEffect(.degrees(spinning ? -360 : 0))
            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: spinning)
            .frame(width: size, height: size)
            .background(color.gradient, in: Circle())
            .onAppear { spinning = true }
    }
}
