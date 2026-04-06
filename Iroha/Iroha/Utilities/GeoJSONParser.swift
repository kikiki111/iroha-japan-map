//
//  GeoJSONParser.swift
//  Iroha
//

import CoreLocation
import SwiftUI

// MARK: - PrefectureShape

/// Holds all CGPaths for a prefecture in normalized (0...1) coordinate space.
/// MultiPolygon対応：離島・沖縄なども複数パスで保持する。
struct PrefectureShape {
    let prefectureID: Int
    /// Paths in normalized 0...1 space: x = longitude, y = latitude (north ≒ 0).
    let paths: [CGPath]
}

// MARK: - JapanBounds

enum JapanBounds {
    static let minLat: Double = 20.0
    static let maxLat: Double = 46.0
    static let minLon: Double = 122.0
    static let maxLon: Double = 154.0
}

// MARK: - GeoJSONParser

enum GeoJSONParser {
    /// Loads PrefectureShapes from a GeoJSON resource in the main bundle.
    /// GeoJSON の properties には "N03_007"（数値 or 文字列）または "code" で都道府県コードを指定する。
    /// ファイルが見つからない場合は空配列を返す（graceful degradation）。
    static func load(resource: String = "japan") -> [PrefectureShape] {
        guard
            let url  = Bundle.main.url(forResource: resource, withExtension: "geojson"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let features = json["features"] as? [[String: Any]]
        else { return [] }

        var pathsByID: [Int: [CGPath]] = [:]

        for feature in features {
            guard
                let props    = feature["properties"] as? [String: Any],
                let prefID   = extractPrefID(from: props),
                let geometry = feature["geometry"] as? [String: Any],
                let geoType  = geometry["type"] as? String
            else { continue }

            let newPaths: [CGPath]
            switch geoType {
            case "Polygon":
                guard let rings = geometry["coordinates"] as? [[[Double]]] else { continue }
                guard let path  = makePath(from: rings) else { continue }
                newPaths = [path]
            case "MultiPolygon":
                guard let polys = geometry["coordinates"] as? [[[[Double]]]] else { continue }
                newPaths = polys.compactMap { makePath(from: $0) }
            default:
                continue
            }

            pathsByID[prefID, default: []].append(contentsOf: newPaths)
        }

        return pathsByID.map { id, paths in PrefectureShape(prefectureID: id, paths: paths) }
    }

    // MARK: - Private helpers

    private static func extractPrefID(from props: [String: Any]) -> Int? {
        // N03_007 (MLIT形式) / code / pref_code の順に試す
        for key in ["N03_007", "code", "pref_code"] {
            if let value = props[key] {
                if let n = value as? Int    { return n }
                if let s = value as? String, let n = Int(s) { return n }
            }
        }
        return nil
    }

    /// Builds a normalized CGPath from the exterior ring of a GeoJSON Polygon.
    private static func makePath(from rings: [[[Double]]]) -> CGPath? {
        guard let exterior = rings.first, exterior.count >= 3 else { return nil }
        let mPath = CGMutablePath()
        for (i, coord) in exterior.enumerated() {
            guard coord.count >= 2 else { continue }
            let point = normalize(lon: coord[0], lat: coord[1])
            if i == 0 { mPath.move(to: point) } else { mPath.addLine(to: point) }
        }
        mPath.closeSubpath()
        return mPath.isEmpty ? nil : mPath
    }

    /// Projects lon/lat into normalized 0...1 space using the skill's Mercator pattern.
    private static func normalize(lon: Double, lat: Double) -> CGPoint {
        let x = (lon - JapanBounds.minLon) / (JapanBounds.maxLon - JapanBounds.minLon)
        let y = 1 - (lat - JapanBounds.minLat) / (JapanBounds.maxLat - JapanBounds.minLat)
        return CGPoint(x: x, y: y)
    }
}
