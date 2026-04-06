---
name: geojson-map
description: >-
  GeoJSON を SwiftUI Canvas で描画する専門知識。
  地図・GeoJSON・Mercator 投影・ヒットテスト・座標変換に関するタスクで自動使用する。
license: MIT
---

## 日本の表示範囲（定数として定義すること）
```swift
enum JapanBounds {
    static let minLat: Double = 20.0
    static let maxLat: Double = 46.0
    static let minLon: Double = 122.0
    static let maxLon: Double = 154.0
}
```

## Mercator 投影パターン
```swift
func project(_ coord: CLLocationCoordinate2D, in rect: CGRect) -> CGPoint {
    let x = (coord.longitude - JapanBounds.minLon)
           / (JapanBounds.maxLon - JapanBounds.minLon) * rect.width + rect.minX
    let y = (1 - (coord.latitude - JapanBounds.minLat)
           / (JapanBounds.maxLat - JapanBounds.minLat)) * rect.height + rect.minY
    return CGPoint(x: x, y: y)
}
```

## ヒットテスト（タップ判定）
```swift
// CGPath.contains を使う
func prefecture(at point: CGPoint) -> Prefecture? {
    prefectureShapes.first { shape in
        shape.paths.contains { $0.contains(point) }
    }?.prefecture
}
```

## 複数ポリゴン対応（離島・沖縄など）
- MultiPolygon 型を必ずサポートする
- すべてのポリゴンを描画し、いずれかにヒットすれば訪問済みと判定
