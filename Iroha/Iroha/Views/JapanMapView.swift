//
//  JapanMapView.swift
//  Iroha
//

import SwiftUI
import SwiftData
import CoreLocation

/// GeoJSON を SwiftUI Canvas に描画する日本地図ビュー。
/// 正規化座標（0..1）の CGPath を事前計算し、Canvas の描画フレームごとにスケール変換する。
/// 都道府県をタップすると MapViewModel にフォーカスを設定する。
struct JapanMapView: View {
    var mapViewModel: MapViewModel

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    /// 正規化座標(0..1)で保持する都道府県パス
    @State private var normalizedShapes: [(name: String, paths: [CGPath])] = []
    /// タップ判定用に Canvas の実描画サイズを保持
    @State private var canvasSize: CGSize = .zero

    // Mercator 投影の縦横比 (width / height) ≈ Δλ_rad / ΔmercY
    private static let mapAspectRatio: CGFloat = 0.92
    // 正規化計算に使う単位矩形
    private static let unitRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    var body: some View {
        Canvas { context, size in
            renderMap(context: context, size: size)
        }
        .aspectRatio(Self.mapAspectRatio, contentMode: .fit)
        // Canvas の実サイズをタップ判定用に取得（overlay の GeometryReader は Canvas の実サイズを受け取る）
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
                    guard let hit = normalizedShapes.first(where: { entry in
                        entry.paths.contains { $0.contains(norm) }
                    }) else { return }
                    if let pref = prefectures.first(where: { $0.name == hit.name }) {
                        mapViewModel.focus(prefecture: pref)
                    }
                }
        )
        .onAppear { loadShapes() }
    }

    // MARK: - Canvas rendering

    private func renderMap(context: GraphicsContext, size: CGSize) {
        let transform = CGAffineTransform(scaleX: size.width, y: size.height)
        let prefMap = Dictionary(uniqueKeysWithValues: prefectures.map { ($0.name, $0) })

        for entry in normalizedShapes {
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

    // MARK: - Data Loading

    private func loadShapes() {
        guard normalizedShapes.isEmpty else { return }
        guard let geoShapes = try? GeoJSONParser.loadPrefectures() else { return }

        normalizedShapes = geoShapes.map { shape in
            let paths = shape.polygons.map { rings -> CGPath in
                buildNormalizedPath(rings: rings)
            }
            return (name: shape.name, paths: paths)
        }
    }

    /// 各リングを正規化座標（0..1）の CGPath に変換する。
    private func buildNormalizedPath(rings: [[CLLocationCoordinate2D]]) -> CGPath {
        let path = CGMutablePath()
        for ring in rings {
            let pts = ring.map { MapProjection.project($0, in: Self.unitRect) }
            guard let first = pts.first else { continue }
            path.move(to: first)
            path.addLines(between: Array(pts.dropFirst()))
            path.closeSubpath()
        }
        return path
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
