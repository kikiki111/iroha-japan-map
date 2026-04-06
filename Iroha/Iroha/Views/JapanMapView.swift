//
//  JapanMapView.swift
//  Iroha
//

import SwiftUI
import SwiftData
import CoreLocation

/// GeoJSON を SwiftUI Canvas に描画する日本地図ビュー。
/// 都道府県をタップすると MapViewModel にフォーカスを設定する。
struct JapanMapView: View {
    var mapViewModel: MapViewModel

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]
    @State private var geoShapes: [PrefectureShape] = []

    // Mercator 投影の縦横比 (width / height) ≈ Δλ_rad / ΔmercY
    private static let mapAspectRatio: CGFloat = 0.92

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                drawMap(context: context, size: size)
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        let rect = CGRect(origin: .zero, size: geo.size)
                        guard let shape = MapProjection.prefecture(
                            at: value.location, in: rect, shapes: geoShapes
                        ) else { return }
                        if let pref = prefectures.first(where: { $0.name == shape.name }) {
                            mapViewModel.focus(prefecture: pref)
                        }
                    }
            )
        }
        .aspectRatio(Self.mapAspectRatio, contentMode: .fit)
        .onAppear { loadShapes() }
    }

    // MARK: - Drawing

    private func drawMap(context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let prefMap = Dictionary(uniqueKeysWithValues: prefectures.map { ($0.name, $0) })

        for shape in geoShapes {
            let pref = prefMap[shape.name]
            let isFocused = mapViewModel.focusedPrefecture?.name == shape.name

            let fillColor: Color
            if isFocused {
                fillColor = .orange
            } else if let pref {
                fillColor = mapViewModel.color(for: pref, allPrefectures: prefectures)
            } else {
                fillColor = Color(hex: "#DDDAD4")
            }

            for rings in shape.polygons {
                let path = buildPath(rings: rings, in: rect)
                context.fill(Path(path), with: .color(fillColor))
                context.stroke(Path(path), with: .color(.white.opacity(0.8)), lineWidth: 0.5)
            }
        }
    }

    private func buildPath(
        rings: [[CLLocationCoordinate2D]],
        in rect: CGRect
    ) -> CGPath {
        let path = CGMutablePath()
        for ring in rings {
            let pts = ring.map { MapProjection.project($0, in: rect) }
            guard let first = pts.first else { continue }
            path.move(to: first)
            path.addLines(between: Array(pts.dropFirst()))
            path.closeSubpath()
        }
        return path
    }

    // MARK: - Data Loading

    private func loadShapes() {
        guard geoShapes.isEmpty else { return }
        geoShapes = (try? GeoJSONParser.loadPrefectures()) ?? []
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var vm = MapViewModel()
    ScrollView {
        JapanMapView(mapViewModel: vm)
            .padding()
    }
    .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
