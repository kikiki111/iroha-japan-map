//
//  DistanceCalculator.swift
//  Iroha
//

import Foundation

enum DistanceCalculator {
    /// Haversine 公式で2地点間の直線距離（km）を計算
    static func distance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }

    /// 基準都道府県からの距離を計算
    static func distance(from home: Prefecture, to target: Prefecture) -> Double {
        distance(lat1: home.latitude, lon1: home.longitude,
                 lat2: target.latitude, lon2: target.longitude)
    }

    /// 旅行全体の移動距離を計算（居住地→各訪問地→居住地のルート距離合計）
    /// 各 visit に位置情報があればその座標、なければ県の代表座標を使用。
    static func totalRouteDistance(trips: [Trip], home: Prefecture, prefectures: [Prefecture]) -> Double {
        var total = 0.0
        let homeCoord = (lat: home.latitude, lon: home.longitude)

        for trip in trips {
            let sorted = trip.visits.sorted { $0.startDate < $1.startDate }
            // 1 レコードに複数県がある場合は登録順に経由地を展開する。
            // 位置情報は 1 レコードに 1 組しか持てないため先頭県の座標として扱い、
            // 2 県目以降は県の代表座標で補完する。
            let stops: [(lat: Double, lon: Double)] = sorted.flatMap { visit -> [(lat: Double, lon: Double)] in
                let pinned: (lat: Double, lon: Double)? = {
                    guard let lat = visit.locationLatitude, let lon = visit.locationLongitude else { return nil }
                    return (lat, lon)
                }()
                let ids = visit.effectivePrefectureIDs
                guard !ids.isEmpty else {
                    // ID 未 backfill (CloudKit 同期直後など) の記録。位置情報か、
                    // 旧 prefectureName の名前一致で拾って経由地から落とさない。
                    if let pinned { return [pinned] }
                    guard let pref = prefectures.first(where: { $0.name == visit.prefectureName })
                    else { return [] }
                    return [(pref.latitude, pref.longitude)]
                }

                return ids.enumerated().compactMap { index, id -> (lat: Double, lon: Double)? in
                    if index == 0, let pinned { return pinned }
                    guard let pref = prefectures.first(where: { $0.id == id }) else { return nil }
                    return (pref.latitude, pref.longitude)
                }
            }
            guard let first = stops.first, let last = stops.last else { continue }

            total += distance(lat1: homeCoord.lat, lon1: homeCoord.lon, lat2: first.lat, lon2: first.lon)
            for i in 1..<stops.count {
                total += distance(lat1: stops[i - 1].lat, lon1: stops[i - 1].lon,
                                  lat2: stops[i].lat,     lon2: stops[i].lon)
            }
            total += distance(lat1: last.lat, lon1: last.lon, lat2: homeCoord.lat, lon2: homeCoord.lon)
        }

        return total
    }
}
