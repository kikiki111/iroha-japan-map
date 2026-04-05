//
//  GeoJSONParser.swift
//  Iroha
//

import CoreLocation
import Foundation

/// Bundle 内の GeoJSON ファイルを解析して PrefectureShape の配列を返すユーティリティ。
enum GeoJSONParser {

    // MARK: - Public

    /// `japan_prefectures.geojson` を Bundle から読み込み、47 都道府県の形状を返す。
    /// - Throws: GeoJSONParserError または JSONDecoder のエラー
    static func loadPrefectures() throws -> [PrefectureShape] {
        guard let url = Bundle.main.url(forResource: "japan_prefectures", withExtension: "geojson") else {
            throw GeoJSONParserError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        let collection = try JSONDecoder().decode(FeatureCollection.self, from: data)
        return try collection.features.map { try parseFeature($0) }
    }

    // MARK: - Private parsing

    private static func parseFeature(_ feature: Feature) throws -> PrefectureShape {
        let polygons: [[[CLLocationCoordinate2D]]]

        switch feature.geometry {
        case .polygon(let rings):
            polygons = [rings.map(coordinatesFromRing)]
        case .multiPolygon(let multiRings):
            polygons = multiRings.map { rings in
                rings.map(coordinatesFromRing)
            }
        }

        return PrefectureShape(
            id: feature.properties.id,
            name: feature.properties.name,
            polygons: polygons
        )
    }

    /// GeoJSON リング（[[lon, lat], …]）を CLLocationCoordinate2D の配列に変換する。
    private static func coordinatesFromRing(_ ring: [[Double]]) -> [CLLocationCoordinate2D] {
        ring.compactMap { point in
            guard point.count >= 2 else { return nil }
            // GeoJSON は [経度, 緯度] の順
            return CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
        }
    }
}

// MARK: - Errors

enum GeoJSONParserError: Error, LocalizedError {
    case fileNotFound
    case invalidGeometry

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "japan_prefectures.geojson が Bundle に見つかりません。"
        case .invalidGeometry:
            return "GeoJSON のジオメトリ形式が不正です。サポートされる型は \"Polygon\" と \"MultiPolygon\" のみです。"
        }
    }
}

// MARK: - Decodable models (private)

private struct FeatureCollection: Decodable {
    let features: [Feature]
}

private struct Feature: Decodable {
    let properties: Properties
    let geometry: Geometry

    struct Properties: Decodable {
        let id: Int
        let name: String
    }
}

private enum Geometry: Decodable {
    /// 外周・穴リングの配列（Polygon）
    case polygon([[[Double]]])
    /// ポリゴンの配列（MultiPolygon）
    case multiPolygon([[[[Double]]]])

    private enum CodingKeys: String, CodingKey {
        case type, coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "Polygon":
            let coords = try container.decode([[[Double]]].self, forKey: .coordinates)
            self = .polygon(coords)
        case "MultiPolygon":
            let coords = try container.decode([[[[Double]]]].self, forKey: .coordinates)
            self = .multiPolygon(coords)
        default:
            throw GeoJSONParserError.invalidGeometry
        }
    }
}
