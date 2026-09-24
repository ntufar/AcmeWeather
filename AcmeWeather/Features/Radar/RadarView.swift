import SwiftUI

struct RadarView: View {
    @Environment(AppState.self) private var app
    @State private var layers = MapLayers()
    @State private var style: MapStyleOption = .standard
    @State private var frameIndex = 0
    @State private var isPlaying = true
    @State private var command: CameraCommand?
    @State private var selectedAlert: WeatherAlert?
    @State private var selectedStorm: Storm?
    @State private var showLayers = false
    @State private var showOutageReport = false

    private var currentFrame: RadarFrame? { app.radarFrames[safe: frameIndex] }

    var body: some View {
        ZStack {
            WeatherMapView(
                radarFrames: app.radarFrames,
                radarFrameIndex: frameIndex,
                layers: layers,
                style: style,
                alerts: app.alerts,
                storms: app.storms,
                outageReports: app.outages.reports,
                countyOutages: app.outages.countyOutages,
                command: command,
                onSelectAlert: { selectedAlert = $0 },
                onSelectStorm: { selectedStorm = $0 }
            )
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                header
                Spacer()
                HStack(alignment: .bottom) {
                    Spacer()
                    mapControls
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                timeline
            }
        }
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(650))
                guard !app.radarFrames.isEmpty else { continue }
                frameIndex = (frameIndex + 1) % app.radarFrames.count
            }
        }
        .onChange(of: app.radarFrames) { _, frames in
            frameIndex = frames.lastIndex { !$0.isForecast } ?? 0
        }
        .sheet(item: $selectedAlert) { alert in
            NavigationStack { AlertDetailView(alert: alert) }
        }
        .sheet(item: $selectedStorm) { storm in
            NavigationStack { StormDetailView(storm: storm) }
        }
        .sheet(isPresented: $showLayers) {
            LayerSheet(layers: $layers, style: $style)
                .presentationDetents([.medium])
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showOutageReport) { OutageReportView() }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Live Radar")
                    .font(.title2.weight(.bold))
                HStack(spacing: 6) {
                    if app.radarFrames.isEmpty {
                        Label("Radar unavailable", systemImage: "wifi.slash")
                    } else {
                        Circle()
                            .fill(currentFrame?.isForecast == true ? Theme.peach : .green)
                            .frame(width: 8, height: 8)
                        Text(currentFrame?.isForecast == true ? "Forecast" : "Observed")
                    }
                    let alertsOnMap = app.alerts.filter { !$0.polygons.isEmpty }.count
                    if alertsOnMap > 0 {
                        Text("· \(alertsOnMap) warning area\(alertsOnMap == 1 ? "" : "s")")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            Spacer()
            Button { showLayers = true } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Map layers")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: Controls

    private var mapControls: some View {
        VStack(spacing: 0) {
            controlButton("plus", label: "Zoom in") { command = CameraCommand(action: .zoomIn) }
            Divider().frame(width: 30)
            controlButton("minus", label: "Zoom out") { command = CameraCommand(action: .zoomOut) }
            Divider().frame(width: 30)
            controlButton("location.fill", label: "Zoom to my location") { zoomToMe() }
            Divider().frame(width: 30)
            controlButton("map", label: "Show all of Georgia") { command = CameraCommand(action: .georgia) }
            Divider().frame(width: 30)
            controlButton("bolt.slash.fill", label: "Report outage", tint: Theme.peach) { showOutageReport = true }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 8)
    }

    private func controlButton(_ symbol: String, label: String, tint: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
        }
        .accessibilityLabel(label)
    }

    private func zoomToMe() {
        if let coordinate = app.location.coordinate {
            command = CameraCommand(action: .focus(coordinate, span: 0.35))
        } else {
            app.location.requestPermission()
        }
    }

    // MARK: Timeline

    @ViewBuilder
    private var timeline: some View {
        if app.radarFrames.count > 1 {
            VStack(spacing: 8) {
                HStack {
                    Button { isPlaying.toggle() } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .accessibilityLabel(isPlaying ? "Pause radar loop" : "Play radar loop")

                    Slider(
                        value: Binding(
                            get: { Double(frameIndex) },
                            set: { frameIndex = Int($0.rounded()); isPlaying = false }
                        ),
                        in: 0...Double(app.radarFrames.count - 1),
                        step: 1
                    )
                    .tint(currentFrame?.isForecast == true ? Theme.peach : Theme.sky)

                    Text(currentFrame?.time.shortTime ?? "")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .frame(width: 64, alignment: .trailing)
                }
                RadarLegend()
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

private struct RadarLegend: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Light").font(.caption2)
            LinearGradient(
                colors: [Color(red: 0.55, green: 0.85, blue: 1), .blue, .green, .yellow, .orange, .red, .purple],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 6)
            .clipShape(Capsule())
            Text("Extreme").font(.caption2)
        }
        .foregroundStyle(.secondary)
    }
}

private struct LayerSheet: View {
    @Binding var layers: MapLayers
    @Binding var style: MapStyleOption

    var body: some View {
        NavigationStack {
            Form {
                Section("Map style") {
                    Picker("Style", selection: $style) {
                        ForEach(MapStyleOption.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Layers") {
                    Toggle(isOn: $layers.radar) { Label("Precipitation radar", systemImage: "cloud.rain.fill") }
                    if layers.radar {
                        HStack {
                            Text("Opacity")
                            Slider(value: $layers.radarOpacity, in: 0.2...1)
                        }
                    }
                    Toggle(isOn: $layers.alerts) { Label("Warning polygons", systemImage: "exclamationmark.triangle.fill") }
                    Toggle(isOn: $layers.hurricanes) { Label("Hurricanes & cones", systemImage: "hurricane") }
                    Toggle(isOn: $layers.outages) { Label("Power outages", systemImage: "bolt.slash.fill") }
                }
                Section {
                    Text("Radar © RainViewer · Alerts © NOAA/NWS · Storms © NOAA/NHC")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Map Layers")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
