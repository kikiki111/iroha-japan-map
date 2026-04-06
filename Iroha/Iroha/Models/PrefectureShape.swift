//
//  PrefectureShape.swift
//  Iroha
//

import CoreLocation

/// GeoJSON から変換した都道府県の境界形状。
/// MultiPolygon（離島・沖縄など）に対応するため polygons を配列で保持する。
struct PrefectureShape: Identifiable {
    /// JIS 都道府県コード（1〜47）
    let id: Int
    /// 都道府県名（日本語）
    let name: String
    /// 外周リング（インデックス 0）と内周リング（穴）からなるポリゴンの配列。
    /// Polygon の場合は要素が 1 つ、MultiPolygon の場合は複数。
    /// 各ポリゴンは [外周リング, 穴1, 穴2, …] の形式。
    let polygons: [[[CLLocationCoordinate2D]]]

    /// 最初のポリゴンの外周リングから求めた重心（ラベル配置用）。
    /// ポリゴンが存在しない場合は nil を返す。
    var centroid: CLLocationCoordinate2D? {
        guard let ring = polygons.first?.first, !ring.isEmpty else { return nil }
        let lat = ring.map(\.latitude).reduce(0, +) / Double(ring.count)
        let lon = ring.map(\.longitude).reduce(0, +) / Double(ring.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
