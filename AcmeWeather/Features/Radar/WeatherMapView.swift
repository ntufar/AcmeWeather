import SwiftUI
import MapKit

enum MapStyleOption: String, CaseIterable, Identifiable {
    case standard, hybrid, satellite

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var mapType: MKMapType {
        switch self {
        case .standard: .mutedStandard // muted base map makes radar colors pop
        case .hybrid: .hybrid
        case .satellite: .satellite
        }
    }
}

struct MapLayers: Equatable {
    var radar = true
    var alerts = true
    var hurricanes = true
    var outages = false
    var radarOpacity = 0.7
}

/// One-shot camera instruction. A new `id` triggers the move.
struct CameraCommand: Equatable {
    enum Action: Equatable {
        case zoomIn
        case zoomOut
        case georgia
        case focus(Coordinate, span: Double)
    }

    let id = UUID()
    let action: Action
}

// MARK: - Overlay & annotation types

final class RadarTileOverlay: MKTileOverlay {
    let frameID: String

    init(frame: RadarFrame) {
        frameID = frame.id
        super.init(urlTemplate: frame.tileTemplate)
        maximumZ = AppConfig.radarMaxZoom
        canReplaceMapContent = false
    }
}

final class AlertPolygon: MKPolygon {
    var alert: WeatherAlert?
}

final class StormConePolygon: MKPolygon {}
final class StormTrackPolyline: MKPolyline {}

final class StormAnnotation: NSObject, MKAnnotation {
    let storm: Storm
    var coordinate: CLLocationCoordinate2D { storm.position.cl }
    var title: String? { storm.displayName }
    init(storm: Storm) { self.storm = storm }
}

final class TrackPointAnnotation: NSObject, MKAnnotation {
    let point: TrackPoint
    var coordinate: CLLocationCoordinate2D { point.coordinate.cl }
    var title: String? { "\(point.label) · \(point.category.shortLabel)" }
    init(point: TrackPoint) { self.point = point }
}

final class OutageAnnotation: NSObject, MKAnnotation {
    let report: OutageReport
    let coordinate: CLLocationCoordinate2D
    var title: String? { "Your report \(report.referenceNumber)" }
    var subtitle: String? { report.stage().title }
    init(report: OutageReport, coordinate: Coordinate) {
        self.report = report
        self.coordinate = coordinate.cl
    }
}

final class CountyOutageAnnotation: NSObject, MKAnnotation {
    let outage: CountyOutage
    var coordinate: CLLocationCoordinate2D { outage.coordinate.cl }
    var title: String? { "\(outage.county) County" }
    var subtitle: String? { "\(outage.customersOut.formatted()) customers out (demo)" }
    init(outage: CountyOutage) { self.outage = outage }
}

// MARK: - Map view

struct WeatherMapView: UIViewRepresentable {
    var radarFrames: [RadarFrame]
    var radarFrameIndex: Int
    var layers: MapLayers
    var style: MapStyleOption
    var alerts: [WeatherAlert]
    var storms: [Storm]
    var outageReports: [OutageReport]
    var countyOutages: [CountyOutage]
    var command: CameraCommand?
    var onSelectAlert: (WeatherAlert) -> Void = { _ in }
    var onSelectStorm: (Storm) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.pointOfInterestFilter = .excludingAll
        map.showsScale = true
        map.showsCompass = false
        map.setRegion(GeorgiaRegion.state, animated: false)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = context.coordinator
        map.addGestureRecognizer(tap)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.sync(map)
    }

    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: WeatherMapView
        private var radarSignature = ""
        private var alertSignature = ""
        private var stormSignature = ""
        private var outageSignature = ""
        private var visibleFrameID: String?
        private var appliedOpacity = -1.0
        private var lastCommandID: UUID?

        init(parent: WeatherMapView) {
            self.parent = parent
        }

        func sync(_ map: MKMapView) {
            if map.mapType != parent.style.mapType {
                map.mapType = parent.style.mapType
            }
            syncRadar(map)
            syncAlerts(map)
            syncStorms(map)
            syncOutages(map)
            applyCommand(map)
        }

        // MARK: Layers

        /// All radar frames are added once; animation just flips which
        /// renderer is visible, so playback is smooth once tiles are cached.
        private func syncRadar(_ map: MKMapView) {
            let frames = parent.layers.radar ? parent.radarFrames : []
            let signature = frames.map(\.id).joined(separator: "|")
            if signature != radarSignature {
                radarSignature = signature
                map.removeOverlays(map.overlays.filter { $0 is RadarTileOverlay })
                for frame in frames {
                    map.addOverlay(RadarTileOverlay(frame: frame), level: .aboveRoads)
                }
                visibleFrameID = nil
            }

            let frameID = parent.radarFrames[safe: parent.radarFrameIndex]?.id
            guard frameID != visibleFrameID || appliedOpacity != parent.layers.radarOpacity else { return }
            visibleFrameID = frameID
            appliedOpacity = parent.layers.radarOpacity
            for case let overlay as RadarTileOverlay in map.overlays {
                (map.renderer(for: overlay) as? MKTileOverlayRenderer)?.alpha = radarAlpha(for: overlay)
            }
        }

        private func radarAlpha(for overlay: RadarTileOverlay) -> CGFloat {
            overlay.frameID == visibleFrameID ? parent.layers.radarOpacity : 0
        }

        private func syncAlerts(_ map: MKMapView) {
            let alerts = parent.layers.alerts ? parent.alerts.filter { !$0.polygons.isEmpty } : []
            let signature = alerts.map(\.id).joined(separator: "|")
            guard signature != alertSignature else { return }
            alertSignature = signature
            map.removeOverlays(map.overlays.filter { $0 is AlertPolygon })
            // Alerts arrive most-severe first; add in reverse so severe ones draw on top.
            for alert in alerts.reversed() {
                for ring in alert.polygons {
                    var coordinates = ring.map(\.cl)
                    let polygon = AlertPolygon(coordinates: &coordinates, count: coordinates.count)
                    polygon.alert = alert
                    map.addOverlay(polygon, level: .aboveRoads)
                }
            }
        }

        private func syncStorms(_ map: MKMapView) {
            let storms = parent.layers.hurricanes ? parent.storms : []
            let signature = storms.map { "\($0.id)-\($0.windMph)-\($0.position.latitude)" }.joined(separator: "|")
            guard signature != stormSignature else { return }
            stormSignature = signature
            map.removeOverlays(map.overlays.filter { $0 is StormConePolygon || $0 is StormTrackPolyline })
            map.removeAnnotations(map.annotations.filter { $0 is StormAnnotation || $0 is TrackPointAnnotation })

            for storm in storms {
                var cone = storm.cone.map(\.cl)
                if cone.count > 2 {
                    map.addOverlay(StormConePolygon(coordinates: &cone, count: cone.count), level: .aboveLabels)
                }
                var track = storm.forecastTrack.map(\.coordinate.cl)
                if track.count > 1 {
                    map.addOverlay(StormTrackPolyline(coordinates: &track, count: track.count), level: .aboveLabels)
                }
                map.addAnnotations(storm.forecastTrack.dropFirst().map { TrackPointAnnotation(point: $0) })
                map.addAnnotation(StormAnnotation(storm: storm))
            }
        }

        private func syncOutages(_ map: MKMapView) {
            let reports = parent.layers.outages ? parent.outageReports.filter { $0.coordinate != nil } : []
            let counties = parent.layers.outages ? parent.countyOutages : []
            let signature = (reports.map(\.id.uuidString) + counties.map(\.id)).joined(separator: "|")
            guard signature != outageSignature else { return }
            outageSignature = signature
            map.removeAnnotations(map.annotations.filter { $0 is OutageAnnotation || $0 is CountyOutageAnnotation })
            map.addAnnotations(counties.map { CountyOutageAnnotation(outage: $0) })
            map.addAnnotations(reports.compactMap { report in
                report.coordinate.map { OutageAnnotation(report: report, coordinate: $0) }
            })
        }

        private func applyCommand(_ map: MKMapView) {
            guard let command = parent.command, command.id != lastCommandID else { return }
            lastCommandID = command.id
            var region = map.region
            switch command.action {
            case .zoomIn:
                region.span = MKCoordinateSpan(
                    latitudeDelta: max(region.span.latitudeDelta / 2, 0.005),
                    longitudeDelta: max(region.span.longitudeDelta / 2, 0.005)
                )
            case .zoomOut:
                region.span = MKCoordinateSpan(
                    latitudeDelta: min(region.span.latitudeDelta * 2, 60),
                    longitudeDelta: min(region.span.longitudeDelta * 2, 60)
                )
            case .georgia:
                region = GeorgiaRegion.state
            case .focus(let coordinate, let span):
                region = MKCoordinateRegion(center: coordinate.cl, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
            }
            map.setRegion(region, animated: true)
        }

        // MARK: MKMapViewDelegate

        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            switch overlay {
            case let tiles as RadarTileOverlay:
                let renderer = MKTileOverlayRenderer(tileOverlay: tiles)
                renderer.alpha = radarAlpha(for: tiles)
                return renderer
            case let polygon as AlertPolygon:
                let renderer = MKPolygonRenderer(polygon: polygon)
                let color = UIColor(polygon.alert?.severity.color ?? .yellow)
                renderer.fillColor = color.withAlphaComponent(0.22)
                renderer.strokeColor = color
                renderer.lineWidth = 2
                return renderer
            case let cone as StormConePolygon:
                let renderer = MKPolygonRenderer(polygon: cone)
                renderer.fillColor = UIColor.white.withAlphaComponent(0.16)
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.85)
                renderer.lineWidth = 1.5
                renderer.lineDashPattern = [6, 4]
                return renderer
            case let track as StormTrackPolyline:
                let renderer = MKPolylineRenderer(polyline: track)
                renderer.strokeColor = .white
                renderer.lineWidth = 2.5
                return renderer
            default:
                return MKOverlayRenderer(overlay: overlay)
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            switch annotation {
            case let storm as StormAnnotation:
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: StormAnnotationView.reuseID) as? StormAnnotationView
                    ?? StormAnnotationView(annotation: storm, reuseIdentifier: StormAnnotationView.reuseID)
                view.annotation = storm
                view.configure(color: UIColor(storm.storm.category.color))
                return view
            case let point as TrackPointAnnotation:
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "track")
                    ?? MKAnnotationView(annotation: point, reuseIdentifier: "track")
                view.annotation = point
                view.image = MapImages.dot(color: UIColor(point.point.category.color), label: point.point.label)
                view.canShowCallout = true
                return view
            case let report as OutageAnnotation:
                let view = marker(for: report, in: mapView, id: "outage")
                view.markerTintColor = UIColor(Theme.peach)
                view.glyphImage = UIImage(systemName: "bolt.slash.fill")
                return view
            case let county as CountyOutageAnnotation:
                let view = marker(for: county, in: mapView, id: "county")
                view.markerTintColor = county.outage.percentOut > 0.05 ? .systemRed : .systemOrange
                view.glyphText = county.outage.customersOut >= 1000
                    ? "\(county.outage.customersOut / 1000)k" : "\(county.outage.customersOut)"
                return view
            default:
                return nil
            }
        }

        private func marker(for annotation: any MKAnnotation, in mapView: MKMapView, id: String) -> MKMarkerAnnotationView {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.canShowCallout = true
            view.glyphImage = nil
            view.glyphText = nil
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let storm = view.annotation as? StormAnnotation {
                mapView.deselectAnnotation(storm, animated: false)
                parent.onSelectStorm(storm.storm)
            }
        }

        // MARK: Tapping warning polygons

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let map = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: map)
            if let hit = map.hitTest(point, with: nil), hit is MKAnnotationView || hit.superview is MKAnnotationView {
                return
            }
            let mapPoint = MKMapPoint(map.convert(point, toCoordinateFrom: map))
            for case let polygon as AlertPolygon in map.overlays.reversed() {
                guard let renderer = map.renderer(for: polygon) as? MKPolygonRenderer,
                      let alert = polygon.alert,
                      let path = renderer.path else { continue }
                if path.contains(renderer.point(for: mapPoint)) {
                    parent.onSelectAlert(alert)
                    return
                }
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

// MARK: - Custom annotation drawing

/// Storm marker with a continuously spinning hurricane glyph.
final class StormAnnotationView: MKAnnotationView {
    static let reuseID = "storm"
    private let spinner = UIImageView()

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        spinner.frame = bounds
        addSubview(spinner)
        canShowCallout = false
        displayPriority = .required
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(color: UIColor) {
        spinner.image = MapImages.badge(color: color, symbol: "hurricane", size: 46)
        spinner.layer.removeAllAnimations()
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = -2 * Double.pi
        spin.duration = 2.5
        spin.repeatCount = .infinity
        spinner.layer.add(spin, forKey: "spin")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        spinner.layer.removeAllAnimations()
    }
}

enum MapImages {
    static func badge(color: UIColor, symbol: String, size: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { _ in
            let rect = CGRect(x: 0, y: 0, width: size, height: size).insetBy(dx: 2, dy: 2)
            let circle = UIBezierPath(ovalIn: rect)
            color.setFill()
            circle.fill()
            UIColor.white.setStroke()
            circle.lineWidth = 2
            circle.stroke()
            let config = UIImage.SymbolConfiguration(pointSize: size * 0.5, weight: .bold)
            if let glyph = UIImage(systemName: symbol, withConfiguration: config)?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                glyph.draw(in: CGRect(
                    x: (size - glyph.size.width) / 2, y: (size - glyph.size.height) / 2,
                    width: glyph.size.width, height: glyph.size.height
                ))
            }
        }
    }

    static func dot(color: UIColor, label: String) -> UIImage {
        let font = UIFont.systemFont(ofSize: 10, weight: .bold)
        let text = label as NSString
        let textSize = text.size(withAttributes: [.font: font])
        let size = CGSize(width: max(14, textSize.width) + 8, height: 14 + textSize.height + 2)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let dotRect = CGRect(x: (size.width - 12) / 2, y: 0, width: 12, height: 12)
            let dot = UIBezierPath(ovalIn: dotRect)
            color.setFill()
            dot.fill()
            UIColor.white.setStroke()
            dot.lineWidth = 1.5
            dot.stroke()
            text.draw(
                at: CGPoint(x: (size.width - textSize.width) / 2, y: 14),
                withAttributes: [.font: font, .foregroundColor: UIColor.white, .strokeColor: UIColor.black, .strokeWidth: -2]
            )
        }
    }
}
