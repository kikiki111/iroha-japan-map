//
//  JapanMapView.swift
//  Iroha
//

import SwiftUI
import SwiftData
import CoreLocation

/// GeoJSON を SwiftUI Canvas に描画する日本地図ビュー。
/// 正規化パス（0..1）は static let で起動時に一度だけ計算し全インスタンスで共有する。
/// タップした都道府県を MapViewModel にフォーカスとして通知する。
struct JapanMapView: View {
    var mapViewModel: MapViewModel

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]
    @State private var canvasSize: CGSize = .zero

    private static let mapAspectRatio: CGFloat = 0.92
    private static let unitRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    /// 正規化座標(0..1)の CGPath — アプリ起動後に一度だけ計算
    private static let shapes: [PrefShape] = {
        guard let geoShapes = try? GeoJSONParser.loadPrefectures() else { return [] }
        return geoShapes.map { shape in
            let paths = shape.polygons.map { rings -> CGPath in
                let path = CGMutablePath()
                for ring in rings {
                    let pts = ring.map { MapProjection.project($0, in: unitRect) }
                    guard let first = pts.first else { continue }
                    path.move(to: first)
                    path.addLines(between: Array(pts.dropFirst()))
                    path.closeSubpath()
                }
                return path
            }
            return PrefShape(name: shape.name, paths: paths)
        }
    }()

    var body: some View {
        Canvas { context, size in
            renderMap(context: context, size: size)
        }
        .aspectRatio(Self.mapAspectRatio, contentMode: .fit)
        .background(Color(hex: "#F0EEE8"))
        .overlay(
            GeometryReader { geo in
                Color.clear.onAppear { canvasSize = geo.size }
            }
        )
        .gesture(
            SpatialTapGesture()
                .onEnded { value in
                    guard canvasSize != .zero else { return }
                    let norm = CGPoint(
                        x: value.location.x / canvasSize.width,
                        y: value.location.y / canvasSize.height
                    )
                    guard let hit = Self.shapes.first(where: { entry in
                        entry.paths.contains { $0.contains(norm) }
                    }) else { return }
                    if let pref = prefectures.first(where: { $0.name == hit.name }) {
                        mapViewModel.focus(prefecture: pref)
                    }
                }
        )
    }

    // MARK: - Canvas rendering

    private func renderMap(context: GraphicsContext, size: CGSize) {
        let transform = CGAffineTransform(scaleX: size.width, y: size.height)
        let prefMap = Dictionary(uniqueKeysWithValues: prefectures.map { ($0.name, $0) })

        for entry in Self.shapes {
            let pref = prefMap[entry.name]
            let isFocused = mapViewModel.focusedPrefecture?.name == entry.name

            let fillColor: Color
            if isFocused {
                fillColor = .orange
            } else if let pref {
                fillColor = mapViewModel.color(for: pref, allPrefectures: prefectures)
            } else {
                fillColor = Color(hex: "#DDDAD4")
            }

            for normPath in entry.paths {
                let scaled = Path(normPath).applying(transform)
                context.fill(scaled, with: .color(fillColor))
                context.stroke(scaled, with: .color(.white.opacity(0.8)), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Supporting type

    private struct PrefShape {
        let name: String
        let paths: [CGPath]
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

// MARK: - Preview

#Preview {
    @Previewable @State var vm = MapViewModel()
    ScrollView {
        JapanMapView(mapViewModel: vm)
            .padding()
    }
    .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
