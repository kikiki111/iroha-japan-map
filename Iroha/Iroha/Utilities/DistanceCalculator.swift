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
            let stops: [(lat: Double, lon: Double)] = sorted.compactMap { visit in
                if let lat = visit.locationLatitude, let lon = visit.locationLongitude {
                    return (lat, lon)
                }
                if let pref = prefectures.first(where: { $0.name == visit.prefectureName }) {
                    return (pref.latitude, pref.longitude)
                }
                return nil
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
