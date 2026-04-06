//
//  MapProjection.swift
//  Iroha
//

import CoreLocation
import CoreGraphics

// MARK: - JapanBounds

/// 日本列島（沖縄を含む）を内包する地理的境界ボックス。
struct JapanBounds {
    static let minLatitude:  Double = 24.0   // 沖縄・波照間島付近
    static let maxLatitude:  Double = 45.9   // 北海道・宗谷岬付近
    static let minLongitude: Double = 122.8  // 沖縄・与那国島付近
    static let maxLongitude: Double = 153.9  // 北海道・納沙布岬付近
}

// MARK: - MapProjection

/// メルカトル投影を使って地理座標をビュー座標に変換するユーティリティ。
enum MapProjection {

    // MARK: Projection

    /// 地理座標をビュー矩形 `rect` 内のピクセル座標に投影する（Mercator 投影）。
    /// - Parameters:
    ///   - coordinate: 変換する緯度経度
    ///   - rect: 描画先の CGRect
    /// - Returns: `rect` 内の CGPoint
    static func project(_ coordinate: CLLocationCoordinate2D, in rect: CGRect) -> CGPoint {
        let x = (coordinate.longitude - JapanBounds.minLongitude)
              / (JapanBounds.maxLongitude - JapanBounds.minLongitude)

        // メルカトル投影: Y 軸は緯度を対数スケールに変換
        let latRad    = coordinate.latitude  * .pi / 180.0
        let minLatRad = JapanBounds.minLatitude  * .pi / 180.0
        let maxLatRad = JapanBounds.maxLatitude  * .pi / 180.0

        let mercY    = log(tan(.pi / 4.0 + latRad    / 2.0))
        let mercYMin = log(tan(.pi / 4.0 + minLatRad / 2.0))
        let mercYMax = log(tan(.pi / 4.0 + maxLatRad / 2.0))

        // Y は北が上（CGRect では Y 軸が下向きなので反転）
        let y = 1.0 - (mercY - mercYMin) / (mercYMax - mercYMin)

        return CGPoint(
            x: rect.minX + CGFloat(x) * rect.width,
            y: rect.minY + CGFloat(y) * rect.height
        )
    }

    // MARK: Hit Test

    /// ビュー上の点 `point` がどの都道府県ポリゴン内に含まれるかを返す。
    /// 複数のポリゴンを持つ場合（MultiPolygon）はいずれかに含まれれば一致と見なす。
    /// - Parameters:
    ///   - point: ビュー上の CGPoint（タップ位置など）
    ///   - rect: 描画先の CGRect
    ///   - shapes: 検索対象の PrefectureShape 配列
    /// - Returns: 一致した PrefectureShape、見つからない場合は nil
    static func prefecture(
        at point: CGPoint,
        in rect: CGRect,
        shapes: [PrefectureShape]
    ) -> PrefectureShape? {
        shapes.first { shape in
            shape.polygons.contains { rings in
                guard let outerRing = rings.first else { return false }
                let projected = outerRing.map { project($0, in: rect) }
                return containsPoint(point, polygon: projected)
            }
        }
    }

    // MARK: - Private helpers

    /// 射線法（Ray Casting）でポリゴン内に点が含まれるか判定する。
    private static func containsPoint(_ point: CGPoint, polygon: [CGPoint]) -> Bool {
        guard polygon.count >= 3 else { return false }
        var inside = false
        var j = polygon.count - 1
        for i in 0 ..< polygon.count {
            let pi = polygon[i]
            let pj = polygon[j]
            let crossesY = (pi.y > point.y) != (pj.y > point.y)
            // pj.y == pi.y は水平辺なので交差しないためスキップ
            if crossesY {
                let t = (point.y - pi.y) / (pj.y - pi.y)
                let xIntersect = pi.x + t * (pj.x - pi.x)
                if point.x < xIntersect {
                    inside.toggle()
                }
            }
            j = i
        }
        return inside
    }
}
